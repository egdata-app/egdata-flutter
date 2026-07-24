import type { CatalogTaxonomyGroup, CatalogTaxonomyTag } from './types'

const MAX_TAXONOMY_BYTES = 2 * 1024 * 1024
const MAX_TAXONOMY_TAGS = 10_000
const GROUPS = new Set<CatalogTaxonomyGroup>([
  'genre',
  'feature',
  'epicfeature',
  'platform',
  'subscription',
])

export class CatalogTaxonomyError extends Error {
  constructor(message: string, options?: ErrorOptions) {
    super(message, options)
    this.name = 'CatalogTaxonomyError'
  }
}

export async function fetchCatalogTaxonomy(
  baseUrl: string,
  fetchImpl: typeof fetch,
  signal?: AbortSignal,
): Promise<CatalogTaxonomyTag[]> {
  const timeout = AbortSignal.timeout(15_000)
  let response: Response
  try {
    response = await fetchImpl(`${baseUrl.replace(/\/+$/, '')}/search/tags?raw=true`, {
      headers: new Headers({ Accept: 'application/json' }),
      signal: signal ? AbortSignal.any([signal, timeout]) : timeout,
    })
  } catch (error) {
    throw new CatalogTaxonomyError('The Library taxonomy request failed.', { cause: error })
  }
  if (!response.ok || !response.body) {
    throw new CatalogTaxonomyError('The Library taxonomy service is unavailable.')
  }
  const declaredSize = Number(response.headers.get('content-length'))
  if (Number.isFinite(declaredSize) && declaredSize > MAX_TAXONOMY_BYTES) {
    throw new CatalogTaxonomyError('The Library taxonomy response is too large.')
  }
  const reader = response.body.getReader() as ReadableStreamDefaultReader<Uint8Array>
  const chunks: Uint8Array[] = []
  let size = 0
  try {
    while (true) {
      const { done, value } = await reader.read()
      if (done) break
      size += value.byteLength
      if (size > MAX_TAXONOMY_BYTES) {
        throw new CatalogTaxonomyError('The Library taxonomy response is too large.')
      }
      chunks.push(value)
    }
  } finally {
    reader.releaseLock()
  }
  const bytes = new Uint8Array(size)
  let offset = 0
  for (const chunk of chunks) {
    bytes.set(chunk, offset)
    offset += chunk.byteLength
  }
  let decoded: unknown
  try {
    decoded = JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(bytes)) as unknown
  } catch (error) {
    throw new CatalogTaxonomyError('The Library taxonomy response is invalid.', { cause: error })
  }
  const source = Array.isArray(decoded)
    ? decoded
    : decoded && typeof decoded === 'object' && !Array.isArray(decoded)
      ? ((decoded as Record<string, unknown>).data ?? (decoded as Record<string, unknown>).tags)
      : null
  if (!Array.isArray(source) || source.length > MAX_TAXONOMY_TAGS) {
    throw new CatalogTaxonomyError('The Library taxonomy response has an invalid shape.')
  }
  const result = new Map<string, CatalogTaxonomyTag>()
  for (const value of source) {
    if (!value || typeof value !== 'object' || Array.isArray(value)) continue
    const entry = value as Record<string, unknown>
    const id = boundedString(entry.id, 256)
    const name = boundedString(entry.name, 512)
    const groupName = boundedString(entry.groupName, 64)?.toLowerCase() as
      | CatalogTaxonomyGroup
      | undefined
    const status = boundedString(entry.status, 64) ?? 'active'
    if (!id || !name || !groupName || !GROUPS.has(groupName)) continue
    result.set(id, { id, name, groupName, status })
  }
  return [...result.values()]
}

function boundedString(value: unknown, maximum: number): string | undefined {
  if (typeof value !== 'string') return undefined
  const trimmed = value.trim()
  return trimmed && trimmed.length <= maximum ? trimmed : undefined
}
