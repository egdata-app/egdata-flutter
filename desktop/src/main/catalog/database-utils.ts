import type { CatalogItemRecord, CatalogLauncherRecordKind, CatalogSearchResultKind } from './types'
import { CatalogValidationError, catalogSha256 } from './validation'

export function compositeKey(namespace: string, id: string): string {
  return namespace + '\u0000' + id
}

export function documentKey(kind: CatalogSearchResultKind, namespace: string, id: string): string {
  return catalogSha256(kind + '\u0000' + namespace + '\u0000' + id)
}

export function parseJsonObject<T>(value: string): T {
  const decoded: unknown = JSON.parse(value)
  if (!decoded || typeof decoded !== 'object' || Array.isArray(decoded)) {
    throw new CatalogValidationError('Stored catalog JSON is invalid.')
  }
  return decoded as T
}

export function optionalString(value: unknown): string | null {
  return typeof value === 'string' && value.trim() ? value : null
}

export function objectString(value: unknown): string | null {
  if (typeof value === 'string' && value.trim()) return value
  if (!value || typeof value !== 'object' || Array.isArray(value)) return null
  const source = value as Record<string, unknown>
  return (
    optionalString(source.name) ??
    optionalString(source.displayName) ??
    optionalString(source.value) ??
    null
  )
}

function valuesAsText(value: unknown, output: string[], depth = 0): void {
  if (output.length >= 5_000 || depth > 12 || value === null || value === undefined) return
  if (typeof value === 'string') {
    if (value.trim()) output.push(value)
    return
  }
  if (typeof value === 'number' || typeof value === 'boolean') {
    output.push(String(value))
    return
  }
  if (Array.isArray(value)) {
    for (const entry of value) valuesAsText(entry, output, depth + 1)
    return
  }
  if (typeof value === 'object') {
    for (const [key, entry] of Object.entries(value as Record<string, unknown>)) {
      output.push(key)
      valuesAsText(entry, output, depth + 1)
    }
  }
}

export function searchableText(value: unknown): string {
  const output: string[] = []
  valuesAsText(value, output)
  return output.join(' ').slice(0, 1024 * 1024)
}

export function imageFromRecord(record: Record<string, unknown>): string | null {
  if (!Array.isArray(record.keyImages)) return null
  const preferred = ['offerimagewide', 'dieselstorefrontwide', 'thumbnail', 'logo']
  const images = record.keyImages
    .filter((entry): entry is Record<string, unknown> =>
      Boolean(entry && typeof entry === 'object' && !Array.isArray(entry)),
    )
    .map((entry) => ({
      type: optionalString(entry.type)?.toLowerCase() ?? '',
      url: optionalString(entry.url) ?? optionalString(entry.imageUrl),
    }))
    .filter((entry): entry is { type: string; url: string } => Boolean(entry.url))
  for (const type of preferred) {
    const found = images.find((entry) => entry.type === type)
    if (found) return found.url
  }
  return images[0]?.url ?? null
}

export function imagesFromRecords(
  records: readonly Record<string, unknown>[],
): Array<{ type: string; url: string }> {
  const result = new Map<string, { type: string; url: string }>()
  for (const record of records) {
    if (!Array.isArray(record.keyImages)) continue
    for (const entry of record.keyImages) {
      if (!entry || typeof entry !== 'object' || Array.isArray(entry)) continue
      const image = entry as Record<string, unknown>
      const url = optionalString(image.url) ?? optionalString(image.imageUrl)
      if (!url || result.has(url)) continue
      result.set(url, { type: optionalString(image.type) ?? 'image', url })
      if (result.size >= 100) return [...result.values()]
    }
  }
  return [...result.values()]
}

export function stringList(value: unknown): string[] {
  if (!Array.isArray(value)) return []
  const result: string[] = []
  for (const entry of value) {
    const text = optionalString(entry) ?? objectString(entry)
    if (text && !result.includes(text)) result.push(text)
  }
  return result
}

export function attributeMap(record: Record<string, unknown>): Map<string, unknown> {
  const result = new Map<string, unknown>()
  for (const [key, value] of Object.entries(record)) result.set(key.toLowerCase(), value)
  const attributes = record.customAttributes
  if (Array.isArray(attributes)) {
    for (const entry of attributes) {
      if (!entry || typeof entry !== 'object' || Array.isArray(entry)) continue
      const source = entry as Record<string, unknown>
      const key =
        optionalString(source.key) ??
        optionalString(source.name) ??
        optionalString(source.attributeName)
      if (!key) continue
      result.set(
        key.toLowerCase(),
        source.value ?? source.attributeValue ?? source.content ?? source,
      )
    }
  } else if (attributes && typeof attributes === 'object') {
    for (const [key, value] of Object.entries(attributes as Record<string, unknown>)) {
      result.set(key.toLowerCase(), value)
    }
  }
  return result
}

export function attributeValue(attributes: Map<string, unknown>, ...keys: string[]): unknown {
  for (const key of keys) {
    const value = attributes.get(key.toLowerCase())
    if (value !== undefined) return value
  }
  return undefined
}

export function booleanAttribute(value: unknown, fallback: boolean): boolean {
  if (typeof value === 'boolean') return value
  if (typeof value === 'number') return value !== 0
  if (typeof value === 'string') {
    const normalized = value.trim().toLowerCase()
    if (normalized === 'true' || normalized === '1' || normalized === 'yes') return true
    if (normalized === 'false' || normalized === '0' || normalized === 'no') return false
  }
  return fallback
}

export function arrayAttribute(value: unknown): string[] {
  if (Array.isArray(value)) {
    return [...new Set(value.map((entry) => optionalString(entry)).filter(Boolean) as string[])]
  }
  if (typeof value !== 'string') return []
  const trimmed = value.trim()
  if (!trimmed) return []
  try {
    const decoded: unknown = JSON.parse(trimmed)
    if (Array.isArray(decoded)) return arrayAttribute(decoded)
  } catch {
    // The launcher also stores some lists as comma-delimited strings.
  }
  return [
    ...new Set(
      trimmed
        .split(',')
        .map((entry) => entry.trim())
        .filter(Boolean),
    ),
  ]
}

export function launcherKind(item: CatalogItemRecord): CatalogLauncherRecordKind {
  const haystack = [
    item.itemType,
    ...stringList(item.categories),
    searchableText(item.customAttributes),
  ]
    .filter((entry): entry is string => typeof entry === 'string')
    .join(' ')
    .toLowerCase()
  if (
    haystack.includes('digital extra') ||
    haystack.includes('digital-extra') ||
    haystack.includes('digitalextras')
  ) {
    return 'digital-extra'
  }
  if (haystack.includes('addon') || haystack.includes('add-on') || haystack.includes('dlc')) {
    return 'addon'
  }
  return 'base-game'
}

export function platformSearchValue(platforms: readonly string[]): string {
  return '\n' + platforms.map((entry) => entry.toLowerCase()).join('\n') + '\n'
}

export function ftsQuery(value: string): string | null {
  const tokens = value.normalize('NFKC').match(/[\p{L}\p{N}_]+/gu)
  if (!tokens?.length) return null
  return tokens
    .slice(0, 32)
    .map((token) => '"' + token.replaceAll('"', '""') + '"*')
    .join(' AND ')
}

export function abortIfNeeded(signal?: AbortSignal): void {
  if (signal?.aborted) throw new DOMException('Catalog refresh cancelled.', 'AbortError')
}

export function yieldToEventLoop(): Promise<void> {
  return new Promise((resolve) => setImmediate(resolve))
}
