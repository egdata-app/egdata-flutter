import type { EpicAuthorizedRequester } from '../auth/types'
import { EpicCloudError } from './errors'
import { authorizedFetchWithOneRefresh, parseJson, timedOperation } from './request'
import type { CloudManifest, EpicLibraryItem, EpicPlatform } from './types'

const ASSET_ROOT = 'https://launcher-public-service-prod06.ol.epicgames.com'
const DEFAULT_MAX_MANIFEST_BYTES = 256 * 1024 * 1024

export interface EpicManifestServiceOptions {
  auth: EpicAuthorizedRequester
  platform: EpicPlatform
  fetch?: typeof fetch
  requestTimeoutMs?: number
  downloadTimeoutMs?: number
  maxManifestBytes?: number
}

interface SelectedManifest {
  url: URL
  buildVersion: string | null
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
}

function requiredSegment(value: string, field: string): string {
  const trimmed = value.trim()
  if (!trimmed) throw new TypeError(`${field} must not be empty`)
  return encodeURIComponent(trimmed)
}

export function buildLauncherAssetUrl(item: EpicLibraryItem, platform: EpicPlatform): URL {
  const path = [
    'launcher/api/public/assets/v2/platform',
    requiredSegment(platform, 'platform'),
    'namespace',
    requiredSegment(item.namespace, 'namespace'),
    'catalogItem',
    requiredSegment(item.catalogItemId, 'catalogItemId'),
    'app',
    requiredSegment(item.appName, 'appName'),
    'label/Live',
  ].join('/')
  return new URL(`/${path}`, ASSET_ROOT)
}

function selectManifest(payload: unknown): SelectedManifest {
  if (!isRecord(payload) || !Array.isArray(payload.elements) || payload.elements.length === 0) {
    throw new EpicCloudError('EPIC_MANIFEST_RESPONSE_INVALID')
  }

  for (const element of payload.elements) {
    if (!isRecord(element) || !Array.isArray(element.manifests)) continue
    const buildVersion =
      typeof element.buildVersion === 'string' && element.buildVersion.trim()
        ? element.buildVersion.trim()
        : null
    for (const manifest of element.manifests) {
      if (!isRecord(manifest) || typeof manifest.uri !== 'string' || !manifest.uri.trim()) continue
      let url: URL
      try {
        url = new URL(manifest.uri)
      } catch {
        continue
      }
      if (url.protocol !== 'https:') continue
      if (manifest.queryParams !== undefined && !Array.isArray(manifest.queryParams)) continue

      let valid = true
      for (const parameter of manifest.queryParams ?? []) {
        if (
          !isRecord(parameter) ||
          typeof parameter.name !== 'string' ||
          !parameter.name ||
          typeof parameter.value !== 'string'
        ) {
          valid = false
          break
        }
        url.searchParams.set(parameter.name, parameter.value)
      }
      if (valid) return { url, buildVersion }
    }
  }
  throw new EpicCloudError('EPIC_MANIFEST_RESPONSE_INVALID')
}

export class EpicManifestService {
  readonly #auth: EpicAuthorizedRequester
  readonly #platform: EpicPlatform
  readonly #fetch: typeof fetch
  readonly #requestTimeoutMs: number
  readonly #downloadTimeoutMs: number
  readonly #maxManifestBytes: number

  constructor(options: EpicManifestServiceOptions) {
    this.#auth = options.auth
    this.#platform = options.platform
    this.#fetch = options.fetch ?? globalThis.fetch
    this.#requestTimeoutMs = options.requestTimeoutMs ?? 20_000
    this.#downloadTimeoutMs = options.downloadTimeoutMs ?? 60_000
    this.#maxManifestBytes = options.maxManifestBytes ?? DEFAULT_MAX_MANIFEST_BYTES
  }

  async getManifest(
    item: EpicLibraryItem,
    options: { signal?: AbortSignal } = {},
  ): Promise<CloudManifest | null> {
    const response = await authorizedFetchWithOneRefresh(
      this.#auth,
      buildLauncherAssetUrl(item, this.#platform),
      { method: 'GET' },
      {
        timeoutMs: this.#requestTimeoutMs,
        signal: options.signal,
        failureCode: 'EPIC_MANIFEST_REQUEST_FAILED',
      },
    )
    if (response.status === 404) return null
    if (!response.ok) {
      throw new EpicCloudError('EPIC_MANIFEST_REQUEST_FAILED', { statusCode: response.status })
    }

    const selected = selectManifest(
      await parseJson(response, 'EPIC_MANIFEST_RESPONSE_INVALID', {
        timeoutMs: this.#requestTimeoutMs,
        signal: options.signal,
        failureCode: 'EPIC_MANIFEST_REQUEST_FAILED',
      }),
    )
    const bytes = await timedOperation<Uint8Array>(
      async (signal) => {
        const download = await this.#fetch(selected.url, { method: 'GET', signal })
        if (!download.ok) {
          throw new EpicCloudError('EPIC_MANIFEST_DOWNLOAD_FAILED', { statusCode: download.status })
        }
        const lengthHeader = download.headers.get('content-length')
        const declaredLength = lengthHeader === null ? null : Number(lengthHeader)
        if (
          declaredLength !== null &&
          (!Number.isFinite(declaredLength) || declaredLength > this.#maxManifestBytes)
        ) {
          throw new EpicCloudError('EPIC_MANIFEST_DOWNLOAD_FAILED')
        }
        const buffer = await download.arrayBuffer()
        if (buffer.byteLength === 0 || buffer.byteLength > this.#maxManifestBytes) {
          throw new EpicCloudError('EPIC_MANIFEST_DOWNLOAD_FAILED')
        }
        return new Uint8Array(buffer)
      },
      {
        timeoutMs: this.#downloadTimeoutMs,
        signal: options.signal,
        failureCode: 'EPIC_MANIFEST_DOWNLOAD_FAILED',
      },
    )
    return { bytes, buildVersion: selected.buildVersion }
  }
}
