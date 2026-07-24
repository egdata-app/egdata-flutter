import { queueSafeError } from './safe-error'
import type {
  InMemoryQueueOptions,
  QueueEventSnapshot,
  QueueEventType,
  QueueInput,
  QueueItemSnapshot,
  QueueItemState,
  QueueProcessor,
  QueueRestoreInput,
  QueueRunOptions,
  QueueRunState,
  QueueSnapshot,
  QueueSuccessfulResultState,
} from './types'

const DEFAULT_CONCURRENCY = 5
const DEFAULT_MAX_EVENTS = 200

interface InternalEntry<T> extends QueueInput<T> {
  title: string
  state: QueueItemState
  attempts: number
  createdAt: string
  startedAt: string | null
  finishedAt: string | null
  error: string | null
  message: string | null
}

const retryableStates = new Set<QueueItemState>(['failed', 'skipped', 'cancelled'])
const terminalStates = new Set<QueueItemState>([
  'uploaded',
  'alreadyUploaded',
  'failed',
  'skipped',
  'cancelled',
])
const resultStates = new Set<QueueSuccessfulResultState>(['uploaded', 'alreadyUploaded', 'skipped'])

function iso(timestamp: number): string {
  return new Date(timestamp).toISOString()
}

function cloneValue<T>(value: T): T {
  try {
    return structuredClone(value)
  } catch {
    return value
  }
}

export class InMemoryQueue<T> {
  readonly #process: QueueProcessor<T>
  readonly #defaultConcurrency: number
  readonly #maxEvents: number
  readonly #now: () => number
  readonly #sanitizeError: (error: unknown) => string
  readonly #entries: InternalEntry<T>[] = []
  readonly #events: QueueEventSnapshot[] = []
  readonly #listeners = new Set<(snapshot: QueueSnapshot<T>) => void>()
  readonly #controllers = new Map<string, AbortController>()
  #state: QueueRunState = 'idle'
  #startedAt: string | null = null
  #finishedAt: string | null = null
  #pauseRequested = false
  #cancelRequested = false
  #sequence = 0
  #runPromise: Promise<void> | null = null
  #runConcurrency: number

  constructor(options: InMemoryQueueOptions<T>) {
    if (typeof options.process !== 'function')
      throw new TypeError('Queue process function is required')
    const concurrency = options.concurrency ?? DEFAULT_CONCURRENCY
    if (!Number.isInteger(concurrency) || concurrency < 1) {
      throw new RangeError('Queue concurrency must be a positive integer')
    }
    const maxEvents = options.maxEvents ?? DEFAULT_MAX_EVENTS
    if (!Number.isInteger(maxEvents) || maxEvents < 1 || maxEvents > DEFAULT_MAX_EVENTS) {
      throw new RangeError('Queue event history must be between 1 and 200')
    }
    this.#process = options.process
    this.#defaultConcurrency = concurrency
    this.#runConcurrency = concurrency
    this.#maxEvents = maxEvents
    this.#now = options.now ?? Date.now
    this.#sanitizeError = options.sanitizeError ?? queueSafeError
  }

  get snapshot(): QueueSnapshot<T> {
    const timestamp = this.#now()
    const items: QueueItemSnapshot<T>[] = this.#entries.map((entry) =>
      Object.freeze({
        id: entry.id,
        value: cloneValue(entry.value),
        title: entry.title,
        state: entry.state,
        attempts: entry.attempts,
        createdAt: entry.createdAt,
        startedAt: entry.startedAt,
        finishedAt: entry.finishedAt,
        error: entry.error,
        message: entry.message,
      }),
    )
    const count = (state: QueueItemState) => items.filter((item) => item.state === state).length
    const startedAtMs = this.#startedAt ? Date.parse(this.#startedAt) : null
    const finishedAtMs = this.#finishedAt ? Date.parse(this.#finishedAt) : timestamp
    const progress = Object.freeze({
      total: items.filter((item) => item.state !== 'removed').length,
      pending: count('pending'),
      running: count('running'),
      uploaded: count('uploaded'),
      alreadyUploaded: count('alreadyUploaded'),
      failed: count('failed'),
      skipped: count('skipped'),
      cancelled: count('cancelled'),
      removed: count('removed'),
      terminal: items.filter((item) => terminalStates.has(item.state)).length,
      elapsedMs: startedAtMs === null ? 0 : Math.max(0, finishedAtMs - startedAtMs),
    })
    return Object.freeze({
      state: this.#state,
      concurrency: this.#runConcurrency,
      startedAt: this.#startedAt,
      finishedAt: this.#finishedAt,
      items: Object.freeze(items),
      progress,
      events: Object.freeze(this.#events.map((event) => Object.freeze({ ...event }))),
    })
  }

  subscribe(listener: (snapshot: QueueSnapshot<T>) => void): () => void {
    this.#listeners.add(listener)
    listener(this.snapshot)
    return () => this.#listeners.delete(listener)
  }

  add(inputs: ReadonlyArray<QueueInput<T>>): QueueSnapshot<T> {
    const knownIds = new Set(this.#entries.map((entry) => entry.id))
    for (const input of inputs) {
      const id = input.id.trim()
      if (!id) throw new TypeError('Queue item id must not be empty')
      if (knownIds.has(id)) throw new Error(`Duplicate queue item id: ${id}`)
      knownIds.add(id)
      this.#entries.push({
        id,
        value: input.value,
        title: input.title?.trim() || id,
        state: 'pending',
        attempts: 0,
        createdAt: iso(this.#now()),
        startedAt: null,
        finishedAt: null,
        error: null,
        message: null,
      })
      this.#event('added', id)
    }
    if (inputs.length > 0 && (this.#state === 'completed' || this.#state === 'cancelled')) {
      this.#state = 'idle'
      this.#finishedAt = null
      this.#notify()
    }
    return this.snapshot
  }

  replace(inputs: ReadonlyArray<QueueInput<T>>): QueueSnapshot<T> {
    if (this.#runPromise) throw new Error('Cannot replace an active queue')
    this.#entries.length = 0
    this.#events.length = 0
    this.#state = 'idle'
    this.#startedAt = null
    this.#finishedAt = null
    this.#sequence = 0
    return this.add(inputs)
  }

  restore(inputs: ReadonlyArray<QueueRestoreInput<T>>): QueueSnapshot<T> {
    if (this.#runPromise) throw new Error('Cannot restore an active queue')
    const knownIds = new Set<string>()
    this.#entries.length = 0
    this.#events.length = 0
    this.#state = 'idle'
    this.#startedAt = null
    this.#finishedAt = null
    this.#sequence = 0

    for (const input of inputs) {
      const id = input.id.trim()
      if (!id) throw new TypeError('Queue item id must not be empty')
      if (knownIds.has(id)) throw new Error(`Duplicate queue item id: ${id}`)
      knownIds.add(id)
      const interrupted = input.state === 'running'
      this.#entries.push({
        id,
        value: input.value,
        title: input.title?.trim() || id,
        state: interrupted ? 'pending' : input.state,
        attempts: Math.max(0, Math.trunc(input.attempts)),
        createdAt: input.createdAt,
        startedAt: interrupted ? null : input.startedAt,
        finishedAt: interrupted ? null : input.finishedAt,
        error: interrupted ? null : input.error,
        message: interrupted ? 'Interrupted sync is ready to resume.' : input.message,
      })
    }

    if (
      this.#entries.length > 0 &&
      this.#entries.every((entry) => terminalStates.has(entry.state) || entry.state === 'removed')
    ) {
      this.#state = 'completed'
      this.#finishedAt = this.#entries.reduce<string | null>((latest, entry) => {
        if (!entry.finishedAt) return latest
        return latest === null || entry.finishedAt > latest ? entry.finishedAt : latest
      }, null)
    }
    this.#notify()
    return this.snapshot
  }

  start(options: QueueRunOptions = {}): Promise<void> {
    if (this.#runPromise) return this.#runPromise
    if (!this.#entries.some((entry) => entry.state === 'pending')) {
      if (this.#entries.length > 0) this.#complete()
      return Promise.resolve()
    }
    this.#pauseRequested = false
    this.#cancelRequested = false
    this.#runConcurrency = this.#validRunConcurrency(options.concurrency)
    this.#state = 'running'
    this.#startedAt ??= iso(this.#now())
    this.#finishedAt = null
    this.#notify()
    return this.#drive()
  }

  pause(): QueueSnapshot<T> {
    if (this.#state !== 'running') return this.snapshot
    this.#pauseRequested = true
    this.#state = 'pausing'
    this.#event('pauseRequested')
    return this.snapshot
  }

  resume(): Promise<void> {
    if (this.#state !== 'paused') return this.#runPromise ?? Promise.resolve()
    this.#pauseRequested = false
    this.#cancelRequested = false
    this.#state = 'running'
    this.#event('resumed')
    return this.#drive()
  }

  async cancel(): Promise<void> {
    if (!this.#runPromise && this.#state !== 'paused') return
    this.#cancelRequested = true
    this.#pauseRequested = false
    const finishedAt = iso(this.#now())
    for (const entry of this.#entries) {
      if (entry.state === 'pending') {
        entry.state = 'cancelled'
        entry.finishedAt = finishedAt
        entry.message = 'Cancelled'
        this.#event('cancelled', entry.id)
      }
    }
    for (const controller of this.#controllers.values()) controller.abort()
    if (this.#runPromise) await this.#runPromise
    else this.#finishCancelled()
  }

  retry(ids?: ReadonlySet<string>, options: QueueRunOptions = {}): Promise<void> {
    if (this.#runPromise || this.#state === 'running' || this.#state === 'pausing') {
      throw new Error('Cannot retry while the queue is active')
    }
    let count = 0
    for (const entry of this.#entries) {
      if ((ids === undefined || ids.has(entry.id)) && retryableStates.has(entry.state)) {
        entry.state = 'pending'
        entry.startedAt = null
        entry.finishedAt = null
        entry.error = null
        entry.message = null
        count += 1
        this.#event('retried', entry.id)
      }
    }
    if (count === 0) return Promise.resolve()
    this.#state = 'idle'
    this.#finishedAt = null
    return this.start(options)
  }

  remove(ids: ReadonlySet<string>): QueueSnapshot<T> {
    const finishedAt = iso(this.#now())
    for (const entry of this.#entries) {
      if (!ids.has(entry.id) || entry.state === 'running' || entry.state === 'removed') continue
      entry.state = 'removed'
      entry.finishedAt = finishedAt
      entry.error = null
      entry.message = 'Removed from queue'
      this.#event('removed', entry.id)
    }
    return this.snapshot
  }

  clearCompleted(): QueueSnapshot<T> {
    if (this.#runPromise) return this.snapshot
    const before = this.#entries.length
    for (let index = this.#entries.length - 1; index >= 0; index -= 1) {
      const entry = this.#entries[index]
      if (entry && (terminalStates.has(entry.state) || entry.state === 'removed')) {
        this.#entries.splice(index, 1)
      }
    }
    if (this.#entries.length !== before)
      this.#event('cleared', null, `${before - this.#entries.length} entries cleared`)
    if (this.#entries.length === 0) {
      this.#state = 'idle'
      this.#startedAt = null
      this.#finishedAt = null
      this.#notify()
    }
    return this.snapshot
  }

  #drive(): Promise<void> {
    const execution = Promise.all(
      Array.from({ length: this.#runConcurrency }, () => this.#worker()),
    )
      .then(() => {
        if (this.#cancelRequested) this.#finishCancelled()
        else if (this.#pauseRequested && this.#entries.some((entry) => entry.state === 'pending')) {
          this.#state = 'paused'
          this.#event('paused')
        } else this.#complete()
      })
      .finally(() => {
        if (this.#runPromise === execution) this.#runPromise = null
      })
    this.#runPromise = execution
    return execution
  }

  #validRunConcurrency(value: number | undefined): number {
    const concurrency = value ?? this.#defaultConcurrency
    if (!Number.isInteger(concurrency) || concurrency < 1) {
      throw new RangeError('Queue concurrency must be a positive integer')
    }
    return concurrency
  }

  async #worker(): Promise<void> {
    while (!this.#pauseRequested && !this.#cancelRequested) {
      const entry = this.#entries.find((candidate) => candidate.state === 'pending')
      if (!entry) return
      entry.state = 'running'
      entry.attempts += 1
      entry.startedAt = iso(this.#now())
      entry.finishedAt = null
      entry.error = null
      entry.message = null
      const controller = new AbortController()
      this.#controllers.set(entry.id, controller)
      this.#event('started', entry.id)

      try {
        const result = await this.#process(entry.value, {
          id: entry.id,
          attempt: entry.attempts,
          signal: controller.signal,
        })
        if (controller.signal.aborted || this.#cancelRequested) {
          this.#setCancelled(entry)
        } else if (!resultStates.has(result.state)) {
          throw new Error('Queue processor returned an invalid result state')
        } else {
          entry.state = result.state
          entry.finishedAt = iso(this.#now())
          entry.message = result.message ? this.#sanitizeError(result.message) : null
          this.#event('finished', entry.id)
        }
      } catch (error) {
        if (controller.signal.aborted || this.#cancelRequested) {
          this.#setCancelled(entry)
        } else {
          entry.state = 'failed'
          entry.finishedAt = iso(this.#now())
          entry.error = this.#sanitizeError(error)
          this.#event('failed', entry.id, entry.error)
        }
      } finally {
        this.#controllers.delete(entry.id)
      }
    }
  }

  #setCancelled(entry: InternalEntry<T>): void {
    entry.state = 'cancelled'
    entry.finishedAt = iso(this.#now())
    entry.error = null
    entry.message = 'Cancelled'
    this.#event('cancelled', entry.id)
  }

  #complete(): void {
    this.#state = 'completed'
    this.#finishedAt = iso(this.#now())
    this.#event('completed')
  }

  #finishCancelled(): void {
    this.#state = 'cancelled'
    this.#finishedAt = iso(this.#now())
    this.#event('cancelled')
  }

  #event(type: QueueEventType, itemId: string | null = null, message: string | null = null): void {
    this.#events.push(
      Object.freeze({
        sequence: ++this.#sequence,
        timestamp: iso(this.#now()),
        type,
        itemId,
        message: message === null ? null : this.#sanitizeError(message),
      }),
    )
    if (this.#events.length > this.#maxEvents)
      this.#events.splice(0, this.#events.length - this.#maxEvents)
    this.#notify()
  }

  #notify(): void {
    if (this.#listeners.size === 0) return
    const snapshot = this.snapshot
    for (const listener of this.#listeners) listener(snapshot)
  }
}
