import type { EpicAuthorizedRequester } from '../auth/types'
import { EpicCloudError } from './errors'
import { authorizedFetchWithOneRefresh, parseJson } from './request'
import type { EpicLibraryItem, EpicPlatform } from './types'

const LIBRARY_URL = 'https://library-service.live.use1a.on.epicgames.com/library/api/public/items'
const DEFAULT_LIMIT = 200
const MAX_LIMIT = 200
const DEFAULT_MAX_PAGES = 100

export interface EpicLibraryServiceOptions {
  auth: EpicAuthorizedRequester
  platform: EpicPlatform
  pageLimit?: number
  requestTimeoutMs?: number
  maxPages?: number
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
}

function optionalString(value: unknown): string | null {
  return typeof value === 'string' ? value : null
}

export class EpicLibraryService {
  readonly #auth: EpicAuthorizedRequester
  readonly #platform: EpicPlatform
  readonly #pageLimit: number
  readonly #requestTimeoutMs: number
  readonly #maxPages: number

  constructor(options: EpicLibraryServiceOptions) {
    this.#auth = options.auth
    this.#platform = options.platform
    this.#pageLimit = Math.min(
      MAX_LIMIT,
      Math.max(1, Math.trunc(options.pageLimit ?? DEFAULT_LIMIT)),
    )
    this.#requestTimeoutMs = options.requestTimeoutMs ?? 20_000
    this.#maxPages = Math.max(1, Math.trunc(options.maxPages ?? DEFAULT_MAX_PAGES))
  }

  async getLibrary(options: { signal?: AbortSignal } = {}): Promise<EpicLibraryItem[]> {
    const items: EpicLibraryItem[] = []
    const itemKeys = new Set<string>()
    const cursors = new Set<string>()
    let cursor: string | null = null

    for (let page = 0; page < this.#maxPages; page += 1) {
      const url = new URL(LIBRARY_URL)
      url.searchParams.set('includeMetadata', 'true')
      url.searchParams.set('platform', this.#platform)
      url.searchParams.set('excludeNs', 'ue')
      url.searchParams.set('limit', String(this.#pageLimit))
      if (cursor) url.searchParams.set('cursor', cursor)

      const response = await authorizedFetchWithOneRefresh(
        this.#auth,
        url,
        { method: 'GET' },
        {
          timeoutMs: this.#requestTimeoutMs,
          signal: options.signal,
          failureCode: 'EPIC_LIBRARY_REQUEST_FAILED',
        },
      )
      if (!response.ok) {
        throw new EpicCloudError('EPIC_LIBRARY_REQUEST_FAILED', { statusCode: response.status })
      }

      const payload = await parseJson(response, 'EPIC_LIBRARY_RESPONSE_INVALID', {
        timeoutMs: this.#requestTimeoutMs,
        signal: options.signal,
        failureCode: 'EPIC_LIBRARY_REQUEST_FAILED',
      })
      if (!isRecord(payload) || !Array.isArray(payload.records)) {
        throw new EpicCloudError('EPIC_LIBRARY_RESPONSE_INVALID')
      }

      for (const raw of payload.records) {
        if (!isRecord(raw)) continue
        const recordType = (optionalString(raw.recordType) ?? 'APPLICATION').toUpperCase()
        const appName = optionalString(raw.appName)?.trim() ?? ''
        const catalogItemId = optionalString(raw.catalogItemId)?.trim() ?? ''
        const namespace = optionalString(raw.namespace)?.trim() ?? ''
        if (
          recordType !== 'APPLICATION' ||
          !appName ||
          !catalogItemId ||
          namespace.toLowerCase() === 'ue'
        ) {
          continue
        }

        const key = `${namespace}\u0000${catalogItemId}\u0000${appName}`
        if (itemKeys.has(key)) continue
        itemKeys.add(key)
        const productId = optionalString(raw.productId)?.trim()
        const assetId = optionalString(raw.assetId)?.trim()
        items.push({
          appName,
          catalogItemId,
          namespace,
          title: optionalString(raw.title)?.trim() ?? '',
          assetId: productId || assetId || appName,
          buildVersion: optionalString(raw.buildVersion)?.trim() || null,
        })
      }

      if (payload.responseMetadata !== undefined && !isRecord(payload.responseMetadata)) {
        throw new EpicCloudError('EPIC_LIBRARY_RESPONSE_INVALID')
      }
      const nextValue = isRecord(payload.responseMetadata)
        ? payload.responseMetadata.nextCursor
        : undefined
      if (nextValue === undefined || nextValue === null || nextValue === '') return items
      if (typeof nextValue !== 'string') throw new EpicCloudError('EPIC_LIBRARY_RESPONSE_INVALID')
      const nextCursor = nextValue.trim()
      if (!nextCursor || cursors.has(nextCursor)) {
        throw new EpicCloudError('EPIC_LIBRARY_PAGINATION_INVALID')
      }
      cursors.add(nextCursor)
      cursor = nextCursor
    }

    throw new EpicCloudError('EPIC_LIBRARY_PAGINATION_INVALID')
  }
}
