import type { StoredSettings } from '../../shared'
import type {
  ScheduledUploadSource,
  ScheduledUploadState,
  ScheduledUploadStateStorage,
} from '../storage'

const MINUTE_MS = 60 * 1000
const STARTUP_GRACE_MS = 60 * 1000
const BLOCKED_RETRY_MS = 5 * MINUTE_MS

type TimerHandle = ReturnType<typeof setTimeout>

export interface ScheduledUploadServiceOptions {
  stateStorage: Pick<ScheduledUploadStateStorage, 'load' | 'recordAttempt'>
  getSettings: () => Promise<StoredSettings>
  canRun: (source: ScheduledUploadSource) => boolean | Promise<boolean>
  run: (source: ScheduledUploadSource, signal: AbortSignal) => Promise<void>
  onError?: (message: string, error: unknown) => void | Promise<void>
  now?: () => number
  setTimer?: (callback: () => void, delayMs: number) => TimerHandle
  clearTimer?: (timer: TimerHandle) => void
  startupGraceMs?: number
  blockedRetryMs?: number
}

export class ScheduledUploadService {
  readonly #options: ScheduledUploadServiceOptions
  readonly #now: () => number
  readonly #setTimer: (callback: () => void, delayMs: number) => TimerHandle
  readonly #clearTimer: (timer: TimerHandle) => void
  readonly #startupGraceMs: number
  readonly #blockedRetryMs: number
  #state: ScheduledUploadState | null = null
  #timer: TimerHandle | null = null
  #controller: AbortController | null = null
  #activeSource: ScheduledUploadSource | null = null
  #startupNotBefore = 0
  #started = false
  #disposed = false
  #evaluation: Promise<void> | null = null
  #evaluateAgain = false

  constructor(options: ScheduledUploadServiceOptions) {
    this.#options = options
    this.#now = options.now ?? Date.now
    this.#setTimer = options.setTimer ?? ((callback, delayMs) => setTimeout(callback, delayMs))
    this.#clearTimer = options.clearTimer ?? clearTimeout
    this.#startupGraceMs = options.startupGraceMs ?? STARTUP_GRACE_MS
    this.#blockedRetryMs = options.blockedRetryMs ?? BLOCKED_RETRY_MS
  }

  async start(): Promise<void> {
    if (this.#started || this.#disposed) return
    this.#started = true
    this.#startupNotBefore = this.#now() + this.#startupGraceMs
    this.#state = await this.#options.stateStorage.load()
    await this.refresh()
  }

  refresh(): Promise<void> {
    if (!this.#started || this.#disposed) return Promise.resolve()
    if (this.#evaluation) {
      this.#evaluateAgain = true
      return this.#evaluation
    }
    const evaluation = this.#evaluate().finally(() => {
      if (this.#evaluation === evaluation) this.#evaluation = null
      if (this.#evaluateAgain && !this.#disposed) {
        this.#evaluateAgain = false
        void this.refresh()
      }
    })
    this.#evaluation = evaluation
    return evaluation
  }

  cancelActive(source?: ScheduledUploadSource): void {
    if (!source || this.#activeSource === source) this.#controller?.abort()
  }

  dispose(): void {
    this.#disposed = true
    this.#clearScheduledTimer()
    this.#controller?.abort()
  }

  async #evaluate(): Promise<void> {
    this.#clearScheduledTimer()
    const settings = await this.#options.getSettings()
    if (!settings.automaticUploadsEnabled || !settings.contributionConsent) {
      this.#controller?.abort()
      return
    }
    if (this.#controller || !this.#state) return

    const candidates = this.#dueCandidates(settings)
    const next = candidates[0]
    if (!next) return
    const now = this.#now()
    const delayMs = Math.max(0, next.dueAt - now, this.#startupNotBefore - now)
    if (delayMs > 0) {
      this.#schedule(delayMs)
      return
    }
    for (const candidate of candidates) {
      if (candidate.dueAt > now) break
      if (await this.#options.canRun(candidate.source)) {
        await this.#run(candidate.source)
        return
      }
    }
    this.#schedule(this.#blockedRetryMs)
  }

  #dueCandidates(settings: StoredSettings): Array<{
    source: ScheduledUploadSource
    dueAt: number
  }> {
    const intervals: Record<ScheduledUploadSource, number> = {
      local: settings.automaticLocalUploadIntervalMinutes * MINUTE_MS,
      cloud: settings.automaticCloudUploadIntervalMinutes * MINUTE_MS,
    }
    return (['local', 'cloud'] as const)
      .map((source) => {
        const lastAttemptAt = this.#state?.lastAttemptAt[source]
        const parsed = lastAttemptAt ? Date.parse(lastAttemptAt) : Number.NEGATIVE_INFINITY
        return {
          source,
          dueAt: Number.isFinite(parsed) ? parsed + intervals[source] : Number.NEGATIVE_INFINITY,
        }
      })
      .sort((left, right) => left.dueAt - right.dueAt)
  }

  async #run(source: ScheduledUploadSource): Promise<void> {
    const controller = new AbortController()
    this.#controller = controller
    this.#activeSource = source
    await this.#recordAttempt(source, this.#now())
    try {
      await this.#options.run(source, controller.signal)
    } catch (error) {
      await this.#reportError(`Scheduled ${source} upload failed`, error)
    } finally {
      await this.#recordAttempt(source, this.#now())
      this.#controller = null
      this.#activeSource = null
    }
    if (!this.#disposed) await this.#evaluate()
  }

  async #recordAttempt(source: ScheduledUploadSource, timestamp: number): Promise<void> {
    const attemptedAt = new Date(timestamp).toISOString()
    this.#state = {
      version: 1,
      lastAttemptAt: {
        ...this.#state?.lastAttemptAt,
        [source]: attemptedAt,
      },
    }
    try {
      await this.#options.stateStorage.recordAttempt(source, attemptedAt)
    } catch (error) {
      await this.#reportError('Scheduled upload timing could not be persisted', error)
    }
  }

  #schedule(delayMs: number): void {
    this.#clearScheduledTimer()
    this.#timer = this.#setTimer(
      () => {
        this.#timer = null
        void this.refresh()
      },
      Math.max(0, delayMs),
    )
  }

  #clearScheduledTimer(): void {
    if (!this.#timer) return
    this.#clearTimer(this.#timer)
    this.#timer = null
  }

  async #reportError(message: string, error: unknown): Promise<void> {
    try {
      await this.#options.onError?.(message, error)
    } catch {
      // Logging must not stop future scheduled work.
    }
  }
}
