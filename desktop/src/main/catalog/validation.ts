import { createHash } from 'node:crypto'

import {
  CATALOG_MAX_ROOT_RECORDS,
  CATALOG_SCHEMA_VERSION,
  type CatalogHydrationIdentifier,
  type CatalogHydrationRootResult,
  type CatalogItemRecord,
  type CatalogOfferItemRecord,
  type CatalogOfferRecord,
  type CatalogRecord,
} from './types'

const SHA256 = /^[a-f0-9]{64}$/
const MAX_ID = 256
const MAX_TITLE = 512
const MAX_STRING = 64 * 1024
const MAX_URL = 4 * 1024
const MAX_DEPTH = 24
const MAX_ENTRIES = 20_000

export class CatalogValidationError extends Error {
  constructor(message: string) {
    super(message)
    this.name = 'CatalogValidationError'
  }
}

const objectValue = (value: unknown, field: string): Record<string, unknown> => {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new CatalogValidationError(`${field} must be an object.`)
  }
  return value as Record<string, unknown>
}
const stringValue = (value: unknown, field: string, maximum = MAX_STRING): string => {
  if (typeof value !== 'string' || value.length > maximum) {
    throw new CatalogValidationError(`${field} must be a bounded string.`)
  }
  return value
}
const nonEmpty = (value: unknown, field: string, maximum = MAX_ID): string => {
  const result = stringValue(value, field, maximum)
  if (!result.trim()) throw new CatalogValidationError(`${field} must not be empty.`)
  return result
}
const sha = (value: unknown, field: string): string => {
  const result = stringValue(value, field, 64).toLowerCase()
  if (!SHA256.test(result)) throw new CatalogValidationError(`${field} is not SHA-256.`)
  return result
}
const isoDate = (value: unknown, field: string): string => {
  const result = stringValue(value, field, 64)
  if (Number.isNaN(Date.parse(result))) throw new CatalogValidationError(`${field} is not a date.`)
  return result
}
const arrayValue = (value: unknown, field: string): unknown[] => {
  if (!Array.isArray(value)) throw new CatalogValidationError(`${field} must be an array.`)
  return value
}
const assertJson = (value: unknown, key = 'record', depth = 0): void => {
  if (depth > MAX_DEPTH) throw new CatalogValidationError('Catalog JSON is too deeply nested.')
  if (value === null || typeof value === 'boolean') return
  if (typeof value === 'number') {
    if (!Number.isFinite(value))
      throw new CatalogValidationError('Catalog JSON has an invalid number.')
    return
  }
  if (typeof value === 'string') {
    const lower = key.toLowerCase()
    const maximum = lower.includes('url')
      ? MAX_URL
      : lower.includes('title')
        ? MAX_TITLE
        : MAX_STRING
    if (value.length > maximum) throw new CatalogValidationError(`${key} is too long.`)
    return
  }
  if (Array.isArray(value)) {
    if (value.length > MAX_ENTRIES) throw new CatalogValidationError(`${key} has too many entries.`)
    for (const entry of value) assertJson(entry, key, depth + 1)
    return
  }
  const source = objectValue(value, key)
  if (Object.keys(source).length > MAX_ENTRIES)
    throw new CatalogValidationError(`${key} has too many fields.`)
  for (const [childKey, entry] of Object.entries(source)) {
    if (!childKey || childKey.length > MAX_ID)
      throw new CatalogValidationError('Catalog JSON has an invalid key.')
    assertJson(entry, childKey, depth + 1)
  }
}

export function stableJson(value: unknown): string {
  if (value === null || typeof value !== 'object') return JSON.stringify(value)
  if (Array.isArray(value)) return `[${value.map(stableJson).join(',')}]`
  const source = value as Record<string, unknown>
  return `{${Object.keys(source)
    .sort()
    .map((key) => `${JSON.stringify(key)}:${stableJson(source[key])}`)
    .join(',')}}`
}

export const catalogSha256 = (value: string): string =>
  createHash('sha256').update(value, 'utf8').digest('hex')

export function parseCatalogRecord(value: unknown): CatalogRecord {
  const source = objectValue(value, 'record')
  assertJson(source)
  if (source.type === 'offer' || source.type === 'item') {
    const common = {
      namespace: nonEmpty(source.namespace, `${source.type}.namespace`),
      id: nonEmpty(source.id, `${source.type}.id`),
      title: nonEmpty(source.title, `${source.type}.title`, MAX_TITLE),
    }
    arrayValue(source.keyImages, `${source.type}.keyImages`)
    arrayValue(source.categories, `${source.type}.categories`)
    arrayValue(source.customAttributes, `${source.type}.customAttributes`)
    if (source.type === 'offer') {
      arrayValue(source.tags, 'offer.tags')
      return { ...source, type: 'offer', ...common } as CatalogOfferRecord
    }
    arrayValue(source.installModes, 'item.installModes')
    return { ...source, type: 'item', ...common } as CatalogItemRecord
  }
  if (source.type === 'asset') {
    return {
      ...source,
      type: 'asset',
      namespace: nonEmpty(source.namespace, 'asset.namespace'),
      artifactId: nonEmpty(source.artifactId, 'asset.artifactId'),
      platform: nonEmpty(source.platform, 'asset.platform', 64),
      itemNamespace: nonEmpty(source.itemNamespace, 'asset.itemNamespace'),
      itemId: nonEmpty(source.itemId, 'asset.itemId'),
    }
  }
  if (source.type === 'release-app') {
    return {
      ...source,
      type: 'release-app',
      namespace: nonEmpty(source.namespace, 'releaseApp.namespace'),
      appId: nonEmpty(source.appId, 'releaseApp.appId'),
      platform: nonEmpty(source.platform, 'releaseApp.platform', 64),
      itemNamespace: nonEmpty(source.itemNamespace, 'releaseApp.itemNamespace'),
      itemId: nonEmpty(source.itemId, 'releaseApp.itemId'),
    }
  }
  if (source.type === 'offer-item') {
    const sources = arrayValue(source.sources, 'offerItem.sources')
    if (sources.some((entry) => !['direct', 'subitem', 'linked'].includes(String(entry)))) {
      throw new CatalogValidationError('offerItem.sources is invalid.')
    }
    if (typeof source.isPrimary !== 'boolean')
      throw new CatalogValidationError('offerItem.isPrimary is invalid.')
    return {
      type: 'offer-item',
      offerNamespace: nonEmpty(source.offerNamespace, 'offerItem.offerNamespace'),
      offerId: nonEmpty(source.offerId, 'offerItem.offerId'),
      itemNamespace: nonEmpty(source.itemNamespace, 'offerItem.itemNamespace'),
      itemId: nonEmpty(source.itemId, 'offerItem.itemId'),
      sources: sources as CatalogOfferItemRecord['sources'],
      isPrimary: source.isPrimary,
    }
  }
  throw new CatalogValidationError('The catalog record type is unsupported.')
}

const encoded = (value: string): string =>
  encodeURIComponent(value.trim().toLocaleLowerCase('en-US'))
const entityKey = (namespace: string, id: string): string => `${encoded(namespace)}:${encoded(id)}`

export function catalogRecordKey(record: CatalogRecord): string {
  switch (record.type) {
    case 'offer':
    case 'item':
      return `${record.type}:${entityKey(record.namespace, record.id)}`
    case 'asset':
      return `asset:${[record.namespace, record.artifactId, record.platform, record.itemNamespace, record.itemId].map(encoded).join(':')}`
    case 'release-app':
      return `release-app:${[record.namespace, record.appId, record.platform, record.itemNamespace, record.itemId].map(encoded).join(':')}`
    case 'offer-item':
      return `offer-item:${[record.offerNamespace, record.offerId, record.itemNamespace, record.itemId].map(encoded).join(':')}`
  }
}

export function catalogHydrationRootKey(identifier: CatalogHydrationIdentifier): string {
  switch (identifier.type) {
    case 'item':
      return `item:${entityKey(identifier.namespace, identifier.id)}`
    case 'asset':
      return `asset:${[identifier.namespace, identifier.artifactId, identifier.platform].map(encoded).join(':')}`
    case 'release-app':
      return `release-app:${[identifier.namespace, identifier.appId, identifier.platform].map(encoded).join(':')}`
  }
}

const parseIdentifier = (value: unknown): CatalogHydrationIdentifier => {
  const source = objectValue(value, 'identifier')
  const namespace = nonEmpty(source.namespace, 'identifier.namespace')
  if (source.type === 'item')
    return { type: 'item', namespace, id: nonEmpty(source.id, 'identifier.id') }
  if (source.type === 'asset')
    return {
      type: 'asset',
      namespace,
      artifactId: nonEmpty(source.artifactId, 'identifier.artifactId'),
      platform: nonEmpty(source.platform, 'identifier.platform', 64),
    }
  if (source.type === 'release-app')
    return {
      type: 'release-app',
      namespace,
      appId: nonEmpty(source.appId, 'identifier.appId'),
      platform: nonEmpty(source.platform, 'identifier.platform', 64),
    }
  throw new CatalogValidationError('The hydration identifier type is unsupported.')
}

export function parseCatalogHydrationRootResult(value: unknown): CatalogHydrationRootResult {
  const source = objectValue(value, 'hydration result')
  if (source.schemaVersion !== CATALOG_SCHEMA_VERSION)
    throw new CatalogValidationError('The hydration schema is unsupported.')
  const identifier = parseIdentifier(source.identifier)
  const rootKey = nonEmpty(source.rootKey, 'rootKey', 4_096)
  if (rootKey !== catalogHydrationRootKey(identifier))
    throw new CatalogValidationError('The hydration root key is invalid.')
  const base = {
    schemaVersion: 2 as const,
    rootKey,
    identifier,
    hydratedAt: isoDate(source.hydratedAt, 'hydratedAt'),
  }
  if (source.status === 'not-found') return { ...base, status: 'not-found' }
  if (source.status === 'error') {
    const error = objectValue(source.error, 'error')
    return {
      ...base,
      status: 'error',
      error: {
        code: nonEmpty(error.code, 'error.code', 128),
        message: nonEmpty(error.message, 'error.message', 500),
      },
    }
  }
  const graphHash = sha(source.graphHash, 'graphHash')
  if (source.status === 'unchanged') return { ...base, status: 'unchanged', graphHash }
  if (source.status !== 'resolved')
    throw new CatalogValidationError('The hydration status is unsupported.')
  const rawKeys = arrayValue(source.recordKeys, 'recordKeys')
  const recordKeys = rawKeys.map((entry, index) => nonEmpty(entry, `recordKeys[${index}]`, 4_096))
  if (
    recordKeys.length > CATALOG_MAX_ROOT_RECORDS ||
    new Set(recordKeys).size !== recordKeys.length
  ) {
    throw new CatalogValidationError('The hydration membership is invalid.')
  }
  const records = arrayValue(source.records, 'records').map((entry, index) => {
    const envelope = objectValue(entry, `records[${index}]`)
    const record = parseCatalogRecord(envelope.record)
    const recordKey = nonEmpty(envelope.recordKey, 'recordKey', 4_096)
    const recordSha = sha(envelope.sha256, 'sha256')
    if (
      !recordKeys.includes(recordKey) ||
      catalogRecordKey(record) !== recordKey ||
      catalogSha256(stableJson(record)) !== recordSha
    ) {
      throw new CatalogValidationError('A hydrated record checksum is invalid.')
    }
    return { recordKey, sha256: recordSha, record }
  })
  if (
    records.length > CATALOG_MAX_ROOT_RECORDS ||
    new Set(records.map((entry) => entry.recordKey)).size !== records.length
  ) {
    throw new CatalogValidationError('The hydration record delta is invalid.')
  }
  return { ...base, status: 'resolved', graphHash, recordKeys: [...recordKeys].sort(), records }
}

export function graphHashForMembership(
  entries: readonly { recordKey: string; sha256: string }[],
): string {
  return catalogSha256(
    stableJson(
      entries
        .map((entry) => [entry.recordKey, entry.sha256] as const)
        .sort(([left], [right]) => left.localeCompare(right)),
    ),
  )
}
