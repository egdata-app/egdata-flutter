import { CatalogDatabase } from './catalog-database'
import { fetchCatalogTaxonomy } from './taxonomy'
import type {
  CatalogDetails,
  CatalogDetailsRequest,
  CatalogHydrationIdentifier,
  CatalogInterestScopeKind,
  CatalogLauncherCandidateInput,
  CatalogLauncherResolution,
  CatalogNameResolution,
  CatalogNameResolutionInput,
  CatalogSearchPage,
  CatalogSearchRequest,
  CatalogStatus,
  CatalogTaxonomySnapshot,
} from './types'
import { CATALOG_MAX_ROOT_BYTES } from './types'
import { CatalogValidationError, catalogHydrationRootKey } from './validation'

const DEFAULT_BASE_URL = 'https://api.egdata.app'
const WEEKLY_SWEEP_INTERVAL = 60 * 60 * 1_000
const ON_USE_MAX_AGE = 24 * 60 * 60 * 1_000
const BACKGROUND_MAX_AGE = 7 * 24 * 60 * 60 * 1_000
const AUTOMATIC_RETRY_DELAY = 60 * 60 * 1_000
const HYDRATION_BATCH_SIZE = 25
const MAX_CHUNK_BUFFER = CATALOG_MAX_ROOT_BYTES + 64 * 1024
const TAXONOMY_MAX_AGE = 24 * 60 * 60 * 1_000

type CatalogErrorCode = NonNullable<CatalogStatus['error']>['code']

export interface CatalogServiceOptions {
  filePath: string
  baseUrl?: string
  fetchImpl?: typeof fetch
  sweepIntervalMs?: number
  now?: () => Date
  onUpdated?: () => void
  /** Compatibility alias for callers from the pre-v2 implementation. */
  onPromoted?: () => void
}

export interface CatalogTaxonomyRefreshResult {
  snapshot: CatalogTaxonomySnapshot
  updated: boolean
  warning: string | null
}

class CatalogServiceError extends Error {
  readonly code: CatalogErrorCode
  constructor(code: CatalogErrorCode, message: string, options?: ErrorOptions) {
    super(message, options)
    this.name = 'CatalogServiceError'
    this.code = code
  }
}

const emptyCounts = (): CatalogStatus['counts'] => ({
  offers: 0,
  items: 0,
  assets: 0,
  releaseApps: 0,
  offerItems: 0,
})
const hydrationUrl = (baseUrl: string): string => `${baseUrl.replace(/\/+$/, '')}/catalog/hydrate`
const isAbortError = (error: unknown): boolean =>
  error instanceof Error && error.name === 'AbortError'
const publicError = (error: unknown): NonNullable<CatalogStatus['error']> => {
  if (isAbortError(error))
    return {
      code: 'CATALOG_SYNC_CANCELLED',
      message: 'The catalog sync was cancelled.',
      retryable: true,
    }
  if (error instanceof CatalogServiceError)
    return { code: error.code, message: error.message.slice(0, 500), retryable: true }
  if (error instanceof CatalogValidationError || error instanceof SyntaxError) {
    return {
      code: 'CATALOG_RESPONSE_INVALID',
      message: 'The catalog hydration stream failed validation.',
      retryable: true,
    }
  }
  return {
    code: 'CATALOG_SYNC_FAILED',
    message: 'The local catalog could not be synchronized.',
    retryable: true,
  }
}

export const hydrationIdentifiersForNames = (
  inputs: readonly CatalogNameResolutionInput[],
): CatalogHydrationIdentifier[] => {
  const identifiers: CatalogHydrationIdentifier[] = []
  for (const input of inputs) {
    if (!input.namespace) continue
    if (input.catalogItemId) {
      identifiers.push({ type: 'item', namespace: input.namespace, id: input.catalogItemId })
    } else if (input.artifactId && input.platform) {
      identifiers.push({
        type: 'asset',
        namespace: input.namespace,
        artifactId: input.artifactId,
        platform: input.platform,
      })
    } else if (input.appName && input.platform) {
      identifiers.push({
        type: 'release-app',
        namespace: input.namespace,
        appId: input.appName,
        platform: input.platform,
      })
    }
  }
  return [...new Map(identifiers.map((entry) => [catalogHydrationRootKey(entry), entry])).values()]
}

export class CatalogService {
  readonly #database: CatalogDatabase
  readonly #baseUrl: string
  readonly #url: string
  readonly #fetch: typeof fetch
  readonly #sweepIntervalMs: number
  readonly #now: () => Date
  readonly #onUpdated: (() => void) | undefined
  readonly #listeners = new Set<(status: CatalogStatus) => void>()
  readonly #pending = new Map<string, CatalogHydrationIdentifier>()
  #status: CatalogStatus = {
    available: false,
    state: 'empty',
    lastSyncedAt: null,
    progress: null,
    counts: emptyCounts(),
    error: null,
  }
  #controller: AbortController | null = null
  #syncPromise: Promise<CatalogStatus> | null = null
  #timer: NodeJS.Timeout | null = null

  constructor(options: CatalogServiceOptions) {
    this.#database = new CatalogDatabase(options.filePath)
    this.#baseUrl = options.baseUrl ?? DEFAULT_BASE_URL
    this.#url = hydrationUrl(this.#baseUrl)
    this.#fetch = options.fetchImpl ?? fetch
    this.#sweepIntervalMs = Math.max(1_000, options.sweepIntervalMs ?? WEEKLY_SWEEP_INTERVAL)
    this.#now = options.now ?? (() => new Date())
    this.#onUpdated = options.onUpdated ?? options.onPromoted
  }

  async initialize(): Promise<void> {
    try {
      await this.#database.initialize()
      const state = this.#database.getState()
      this.#status = {
        available: Object.values(state.counts).some((count) => count > 0),
        state: Object.values(state.counts).some((count) => count > 0) ? 'ready' : 'empty',
        lastSyncedAt: state.lastSyncedAt,
        progress: null,
        counts: state.counts,
        error: null,
      }
      this.#emit()
    } catch (error) {
      this.#status = {
        ...this.#status,
        state: 'failed',
        error: {
          code: 'CATALOG_STORAGE_FAILED',
          message: 'The local catalog could not be opened.',
          retryable: true,
        },
      }
      this.#emit()
      throw error
    }
  }

  start(): void {
    if (this.#timer) return
    void this.#sweep().catch(() => undefined)
    void this.refreshTaxonomy(false).catch(() => undefined)
    this.#timer = setInterval(
      () => void this.#sweep().catch(() => undefined),
      this.#sweepIntervalMs,
    )
    this.#timer.unref()
  }

  stop(): void {
    if (this.#timer) clearInterval(this.#timer)
    this.#timer = null
    this.#controller?.abort()
  }

  close(): void {
    this.stop()
    this.#database.close()
  }

  getStatus(): CatalogStatus {
    return {
      ...this.#status,
      counts: { ...this.#status.counts },
      progress: this.#status.progress ? { ...this.#status.progress } : null,
      error: this.#status.error ? { ...this.#status.error } : null,
    }
  }

  subscribe(listener: (status: CatalogStatus) => void): () => void {
    this.#listeners.add(listener)
    return () => this.#listeners.delete(listener)
  }

  refresh(): Promise<CatalogStatus> {
    return this.hydrateIdentifiers(this.#database.listHydrationIdentifiers())
  }

  reconcileNames(
    scopeKey: string,
    kind: CatalogInterestScopeKind,
    inputs: readonly CatalogNameResolutionInput[],
  ): Promise<CatalogStatus> {
    return this.reconcileIdentifiers(scopeKey, kind, hydrationIdentifiersForNames(inputs))
  }

  reconcileIdentifiers(
    scopeKey: string,
    kind: CatalogInterestScopeKind,
    identifiers: readonly CatalogHydrationIdentifier[],
  ): Promise<CatalogStatus> {
    const pending = this.#database.reconcileScope(
      scopeKey,
      kind,
      identifiers,
      this.#now().toISOString(),
    )
    this.#refreshStoredState()
    return this.hydrateIdentifiers(pending)
  }

  removeScope(scopeKey: string): void {
    this.#database.removeScope(scopeKey)
    this.#refreshStoredState()
    this.#notifyUpdated()
  }

  hydrateNames(inputs: readonly CatalogNameResolutionInput[]): Promise<CatalogStatus> {
    const now = this.#now()
    return this.hydrateIdentifiers(
      this.#database.filterInterestedIdentifiers(
        hydrationIdentifiersForNames(inputs),
        new Date(now.valueOf() - ON_USE_MAX_AGE).toISOString(),
        now.toISOString(),
      ),
    )
  }

  hydrateIdentifiers(identifiers: readonly CatalogHydrationIdentifier[]): Promise<CatalogStatus> {
    for (const identifier of identifiers)
      this.#pending.set(catalogHydrationRootKey(identifier), identifier)
    return this.#drain()
  }

  cancelRefresh(): boolean {
    if (!this.#controller) return false
    this.#controller.abort()
    return true
  }

  search(request: CatalogSearchRequest): CatalogSearchPage {
    return this.#database.search(request)
  }

  getDetails(request: CatalogDetailsRequest): CatalogDetails | null {
    const details = this.#database.getDetails(request)
    const now = this.#now()
    const stale = this.#database.listIdentifiersForDetails(
      request,
      new Date(now.valueOf() - ON_USE_MAX_AGE).toISOString(),
      now.toISOString(),
    )
    if (stale.length) void this.hydrateIdentifiers(stale).catch(() => undefined)
    return details
  }

  getLibraryMetadata(
    input: CatalogNameResolutionInput,
  ): ReturnType<CatalogDatabase['getLibraryMetadata']> {
    return this.#database.getLibraryMetadata(input)
  }

  getTaxonomy(): CatalogTaxonomySnapshot {
    return this.#database.getTaxonomy()
  }

  async refreshTaxonomy(force = false): Promise<CatalogTaxonomyRefreshResult> {
    const cached = this.#database.getTaxonomy()
    const updatedAt = cached.updatedAt ? Date.parse(cached.updatedAt) : Number.NaN
    if (
      !force &&
      Number.isFinite(updatedAt) &&
      this.#now().valueOf() - updatedAt < TAXONOMY_MAX_AGE
    ) {
      return { snapshot: cached, updated: false, warning: null }
    }
    try {
      const tags = await fetchCatalogTaxonomy(this.#baseUrl, this.#fetch)
      const refreshedAt = this.#now().toISOString()
      this.#database.replaceTaxonomy(tags, refreshedAt)
      const snapshot = this.#database.getTaxonomy()
      this.#notifyUpdated()
      return { snapshot, updated: true, warning: null }
    } catch {
      return {
        snapshot: cached,
        updated: false,
        warning: 'Library filters could not be refreshed; cached taxonomy was kept.',
      }
    }
  }

  resolveDisplayName(input: CatalogNameResolutionInput): CatalogNameResolution | null {
    const result = this.#database.resolveDisplayName(input)
    void this.hydrateNames([input]).catch(() => undefined)
    return result
  }

  resolveLauncherCandidate(input: CatalogLauncherCandidateInput): CatalogLauncherResolution | null {
    const result = this.#database.resolveLauncherCandidate(input)
    const hint = input.catalogHint
    void this.hydrateNames([
      {
        ...(hint?.catalogNamespace ? { namespace: hint.catalogNamespace } : {}),
        ...(hint?.catalogItemId ? { catalogItemId: hint.catalogItemId } : {}),
        ...(hint?.artifactId ? { artifactId: hint.artifactId } : {}),
        appName: input.buildAppName,
        platform: input.platform,
      },
    ]).catch(() => undefined)
    return result
  }

  async #sweep(): Promise<void> {
    const now = this.#now()
    const cutoff = new Date(now.valueOf() - BACKGROUND_MAX_AGE).toISOString()
    await this.hydrateIdentifiers(
      this.#database.listHydrationIdentifiers(cutoff, now.toISOString()),
    )
  }

  #drain(): Promise<CatalogStatus> {
    if (this.#syncPromise) return this.#syncPromise
    if (this.#pending.size === 0) return Promise.resolve(this.getStatus())
    const identifiers = [...this.#pending.values()]
    this.#pending.clear()
    const controller = new AbortController()
    this.#controller = controller
    this.#syncPromise = this.#run(identifiers, controller.signal).finally(() => {
      if (this.#controller === controller) this.#controller = null
      this.#syncPromise = null
    })
    return this.#syncPromise
  }

  async #run(
    identifiers: readonly CatalogHydrationIdentifier[],
    signal: AbortSignal,
  ): Promise<CatalogStatus> {
    let processed = 0
    let updated = 0
    let failed = 0
    this.#setStatus({
      state: 'syncing',
      progress: { processed, total: identifiers.length, updated, failed },
      error: null,
    })
    try {
      for (let offset = 0; offset < identifiers.length; offset += HYDRATION_BATCH_SIZE) {
        const batch = identifiers.slice(offset, offset + HYDRATION_BATCH_SIZE)
        const processedKeys = new Set<string>()
        try {
          const changed = await this.#requestBatch(batch, signal, (value) => {
            const applied = this.#database.applyHydrationRoot(value)
            const source = value as { rootKey?: unknown; status?: unknown }
            if (typeof source.rootKey === 'string') {
              processedKeys.add(source.rootKey)
              this.#pending.delete(source.rootKey)
            }
            processed += applied.rootsChecked
            if (applied.updated) updated += 1
            if (source.status === 'error') failed += 1
            this.#refreshStoredState()
            this.#setStatus({
              state: 'syncing',
              progress: { processed, total: identifiers.length, updated, failed },
            })
          })
          if (changed) this.#notifyUpdated()
        } catch (error) {
          const deferred = [
            ...batch.filter(
              (identifier) => !processedKeys.has(catalogHydrationRootKey(identifier)),
            ),
            ...identifiers.slice(offset + batch.length),
          ]
          for (const identifier of deferred)
            this.#pending.delete(catalogHydrationRootKey(identifier))
          this.#database.deferHydrationIdentifiers(
            deferred,
            new Date(this.#now().valueOf() + AUTOMATIC_RETRY_DELAY).toISOString(),
            publicError(error).code,
          )
          throw error
        }
        await new Promise<void>((resolve) => setImmediate(resolve))
      }
      this.#refreshStoredState()
      this.#setStatus({
        state: failed > 0 ? 'failed' : this.#status.available ? 'ready' : 'empty',
        progress: null,
        error:
          failed > 0
            ? {
                code: 'CATALOG_SYNC_FAILED',
                message: `${failed} catalog ${failed === 1 ? 'root' : 'roots'} could not be synchronized; completed roots were kept.`,
                retryable: true,
              }
            : null,
      })
      if (this.#pending.size > 0) queueMicrotask(() => void this.#drain())
      return this.getStatus()
    } catch (error) {
      const safe = publicError(error)
      this.#refreshStoredState()
      this.#setStatus({
        state: safe.code === 'CATALOG_SYNC_CANCELLED' ? 'cancelled' : 'failed',
        progress: null,
        error: safe,
      })
      if (this.#pending.size > 0) queueMicrotask(() => void this.#drain())
      return this.getStatus()
    }
  }

  async #requestBatch(
    identifiers: readonly CatalogHydrationIdentifier[],
    signal: AbortSignal,
    onRoot: (value: unknown) => void,
  ): Promise<boolean> {
    const request = this.#database.getHydrationRequest(identifiers)
    const timeout = AbortSignal.timeout(60_000)
    let response: Response
    try {
      response = await this.#fetch(this.#url, {
        method: 'POST',
        headers: new Headers({
          Accept: 'application/x-ndjson',
          'Content-Type': 'application/json',
        }),
        body: JSON.stringify(request),
        signal: AbortSignal.any([signal, timeout]),
      })
    } catch (error) {
      if (signal.aborted) throw new DOMException('Catalog sync cancelled.', 'AbortError')
      throw new CatalogServiceError(
        'CATALOG_SYNC_FAILED',
        'The catalog hydration request failed.',
        { cause: error },
      )
    }
    if (!response.ok || !response.body) {
      throw new CatalogServiceError(
        response.status === 503 ? 'CATALOG_UNAVAILABLE' : 'CATALOG_SYNC_FAILED',
        'The catalog hydration service is unavailable.',
      )
    }
    if (!response.headers.get('content-type')?.toLowerCase().startsWith('application/x-ndjson')) {
      throw new CatalogServiceError(
        'CATALOG_RESPONSE_INVALID',
        'The catalog hydration response type is invalid.',
      )
    }
    const reader = response.body.getReader() as ReadableStreamDefaultReader<Uint8Array>
    let pending: Uint8Array<ArrayBufferLike> = new Uint8Array(0)
    let changed = false
    const decoder = new TextDecoder('utf-8', { fatal: true })
    const consume = (lineBytes: Uint8Array): void => {
      if (lineBytes.byteLength === 0) return
      if (lineBytes.byteLength > CATALOG_MAX_ROOT_BYTES)
        throw new CatalogValidationError('A hydration root exceeded its byte limit.')
      const value = JSON.parse(decoder.decode(lineBytes)) as unknown
      const status = (value as { status?: unknown }).status
      onRoot(value)
      if (status === 'resolved' || status === 'not-found') changed = true
    }
    try {
      while (true) {
        const { done, value } = await reader.read()
        if (done) break
        const next = new Uint8Array(pending.byteLength + value.byteLength)
        next.set(pending)
        next.set(value, pending.byteLength)
        pending = next
        if (pending.byteLength > MAX_CHUNK_BUFFER)
          throw new CatalogValidationError('A hydration line exceeded its byte limit.')
        let start = 0
        for (let index = 0; index < pending.byteLength; index += 1) {
          if (pending[index] !== 10) continue
          consume(pending.subarray(start, index))
          start = index + 1
        }
        pending = pending.slice(start)
      }
      if (pending.byteLength > 0) consume(pending)
    } finally {
      reader.releaseLock()
    }
    return changed
  }

  #refreshStoredState(): void {
    const state = this.#database.getState()
    this.#status = {
      ...this.#status,
      available: Object.values(state.counts).some((count) => count > 0),
      lastSyncedAt: state.lastSyncedAt,
      counts: state.counts,
    }
  }

  #notifyUpdated(): void {
    try {
      this.#onUpdated?.()
    } catch {
      /* presentation refresh cannot roll back catalog data */
    }
  }

  #setStatus(patch: Partial<CatalogStatus>): void {
    this.#status = {
      ...this.#status,
      ...patch,
      counts: patch.counts ? { ...patch.counts } : this.#status.counts,
      progress: patch.progress === undefined ? this.#status.progress : patch.progress,
      error: patch.error === undefined ? this.#status.error : patch.error,
    }
    this.#emit()
  }

  #emit(): void {
    const status = this.getStatus()
    for (const listener of this.#listeners) {
      try {
        listener(status)
      } catch {
        /* renderer listeners cannot interrupt synchronization */
      }
    }
  }
}
