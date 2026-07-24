import { DatabaseSync } from 'node:sqlite'

import { rebuildAffectedSearchDocuments, type CatalogSearchTarget } from './database-build'
import {
  type CatalogCounts,
  type CatalogHydrationApplyResult,
  type CatalogHydrationIdentifier,
  type CatalogHydrationRequest,
  type CatalogHydrationRootResult,
  type CatalogInterestScopeKind,
  type CatalogRecord,
} from './types'
import { imageFromRecord, objectString, optionalString } from './database-utils'
import {
  CatalogValidationError,
  catalogHydrationRootKey,
  graphHashForMembership,
  parseCatalogRecord,
} from './validation'

const nowIso = (): string => new Date().toISOString()

export function catalogCounts(database: DatabaseSync): CatalogCounts {
  const count = (table: string): number =>
    Number(
      (database.prepare(`SELECT COUNT(*) AS value FROM ${table}`).get() as { value: number }).value,
    )
  return {
    offers: count('catalog_offers'),
    items: count('catalog_items'),
    assets: count('catalog_assets'),
    releaseApps: count('catalog_release_apps'),
    offerItems: count('catalog_offer_items'),
  }
}

export function lastCatalogSync(database: DatabaseSync): string | null {
  const row = database.prepare('SELECT MAX(last_synced_at) AS value FROM catalog_roots').get() as {
    value: string | null
  }
  return row.value
}

const targetKey = (target: CatalogSearchTarget): string =>
  `${target.kind}\0${target.namespace}\0${target.id}`

function targetsForRecord(record: CatalogRecord): CatalogSearchTarget[] {
  switch (record.type) {
    case 'offer':
      return [{ kind: 'offer', namespace: record.namespace, id: record.id }]
    case 'item':
      return [
        { kind: 'item', namespace: record.namespace, id: record.id },
        ...(record.primaryOfferNamespace && record.primaryOfferId
          ? [
              {
                kind: 'offer' as const,
                namespace: record.primaryOfferNamespace,
                id: record.primaryOfferId,
              },
            ]
          : []),
      ]
    case 'asset':
    case 'release-app':
      return [{ kind: 'item', namespace: record.itemNamespace, id: record.itemId }]
    case 'offer-item':
      return [
        { kind: 'offer', namespace: record.offerNamespace, id: record.offerId },
        { kind: 'item', namespace: record.itemNamespace, id: record.itemId },
      ]
  }
}

function recordsForRoot(database: DatabaseSync, rootKey: string): CatalogRecord[] {
  return (
    database
      .prepare(
        `SELECT r.raw_json FROM catalog_root_records rr
         JOIN catalog_records r ON r.record_key = rr.record_key
         WHERE rr.root_key = ? LIMIT 500`,
      )
      .all(rootKey) as unknown as Array<{ raw_json: string }>
  ).map((row) => parseCatalogRecord(JSON.parse(row.raw_json) as unknown))
}

function expandTargets(
  database: DatabaseSync,
  targets: CatalogSearchTarget[],
): CatalogSearchTarget[] {
  const result = new Map(targets.map((target) => [targetKey(target), target]))
  const offersForItem = database.prepare(
    'SELECT offer_namespace, offer_id FROM catalog_offer_items WHERE item_namespace = ? AND item_id = ? LIMIT 500',
  )
  const itemsForOffer = database.prepare(
    'SELECT item_namespace, item_id FROM catalog_offer_items WHERE offer_namespace = ? AND offer_id = ? LIMIT 500',
  )
  for (const target of [...result.values()]) {
    if (target.kind === 'item') {
      for (const row of offersForItem.all(target.namespace, target.id) as unknown as Array<{
        offer_namespace: string
        offer_id: string
      }>) {
        const related = { kind: 'offer' as const, namespace: row.offer_namespace, id: row.offer_id }
        result.set(targetKey(related), related)
      }
    } else {
      for (const row of itemsForOffer.all(target.namespace, target.id) as unknown as Array<{
        item_namespace: string
        item_id: string
      }>) {
        const related = { kind: 'item' as const, namespace: row.item_namespace, id: row.item_id }
        result.set(targetKey(related), related)
      }
    }
  }
  return [...result.values()]
}

function removeNormalizedRecord(database: DatabaseSync, recordKey: string): void {
  for (const table of [
    'catalog_offers',
    'catalog_items',
    'catalog_assets',
    'catalog_release_apps',
    'catalog_offer_items',
  ])
    database.prepare(`DELETE FROM ${table} WHERE record_key = ?`).run(recordKey)
}

function upsertNormalizedRecord(
  database: DatabaseSync,
  recordKey: string,
  record: CatalogRecord,
): void {
  removeNormalizedRecord(database, recordKey)
  const raw = JSON.stringify(record)
  switch (record.type) {
    case 'offer':
      database
        .prepare(
          `INSERT INTO catalog_offers
         (record_key, namespace, id, title, description, long_description, offer_type,
          developer, publisher, image_url, product_slug, url_slug, raw_json)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
         ON CONFLICT(namespace, id) DO UPDATE SET
          record_key=excluded.record_key, title=excluded.title, description=excluded.description,
          long_description=excluded.long_description, offer_type=excluded.offer_type,
          developer=excluded.developer, publisher=excluded.publisher, image_url=excluded.image_url,
          product_slug=excluded.product_slug, url_slug=excluded.url_slug, raw_json=excluded.raw_json`,
        )
        .run(
          recordKey,
          record.namespace,
          record.id,
          record.title,
          optionalString(record.description) ?? '',
          optionalString(record.longDescription) ?? '',
          optionalString(record.offerType),
          optionalString(record.developerDisplayName) ?? objectString(record.developer),
          optionalString(record.publisherDisplayName) ?? objectString(record.publisher),
          imageFromRecord(record),
          optionalString(record.productSlug),
          optionalString(record.urlSlug),
          raw,
        )
      return
    case 'item':
      database
        .prepare(
          `INSERT INTO catalog_items
         (record_key, namespace, id, title, description, long_description, technical_details,
          primary_offer_namespace, primary_offer_id, raw_json)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
         ON CONFLICT(namespace, id) DO UPDATE SET
          record_key=excluded.record_key, title=excluded.title, description=excluded.description,
          long_description=excluded.long_description, technical_details=excluded.technical_details,
          primary_offer_namespace=excluded.primary_offer_namespace,
          primary_offer_id=excluded.primary_offer_id, raw_json=excluded.raw_json`,
        )
        .run(
          recordKey,
          record.namespace,
          record.id,
          record.title,
          optionalString(record.description) ?? '',
          optionalString(record.longDescription) ?? '',
          optionalString(record.technicalDetails) ?? '',
          optionalString(record.primaryOfferNamespace),
          optionalString(record.primaryOfferId),
          raw,
        )
      return
    case 'asset':
      database
        .prepare(
          `INSERT INTO catalog_assets
         (record_key, namespace, artifact_id, platform, item_namespace, item_id, raw_json)
         VALUES (?, ?, ?, ?, ?, ?, ?)
         ON CONFLICT(namespace, artifact_id, platform, item_namespace, item_id)
         DO UPDATE SET record_key=excluded.record_key, raw_json=excluded.raw_json`,
        )
        .run(
          recordKey,
          record.namespace,
          record.artifactId,
          record.platform,
          record.itemNamespace,
          record.itemId,
          raw,
        )
      return
    case 'release-app':
      database
        .prepare(
          `INSERT INTO catalog_release_apps
         (record_key, namespace, app_id, platform, item_namespace, item_id, raw_json)
         VALUES (?, ?, ?, ?, ?, ?, ?)
         ON CONFLICT(namespace, app_id, platform, item_namespace, item_id)
         DO UPDATE SET record_key=excluded.record_key, raw_json=excluded.raw_json`,
        )
        .run(
          recordKey,
          record.namespace,
          record.appId,
          record.platform,
          record.itemNamespace,
          record.itemId,
          raw,
        )
      return
    case 'offer-item':
      database
        .prepare(
          `INSERT INTO catalog_offer_items
         (record_key, offer_namespace, offer_id, item_namespace, item_id, sources_json, is_primary)
         VALUES (?, ?, ?, ?, ?, ?, ?)
         ON CONFLICT(offer_namespace, offer_id, item_namespace, item_id)
         DO UPDATE SET record_key=excluded.record_key, sources_json=excluded.sources_json,
          is_primary=excluded.is_primary`,
        )
        .run(
          recordKey,
          record.offerNamespace,
          record.offerId,
          record.itemNamespace,
          record.itemId,
          JSON.stringify(record.sources),
          record.isPrimary ? 1 : 0,
        )
  }
}

function garbageCollect(database: DatabaseSync): void {
  database.exec(`
    DELETE FROM catalog_records
     WHERE NOT EXISTS (
       SELECT 1 FROM catalog_root_records rr WHERE rr.record_key = catalog_records.record_key
     );
  `)
}

export function applyCatalogHydrationRoot(
  database: DatabaseSync,
  result: CatalogHydrationRootResult,
): CatalogHydrationApplyResult {
  const oldRecords = recordsForRoot(database, result.rootKey)
  const targets = oldRecords.flatMap(targetsForRecord)
  database.exec('BEGIN IMMEDIATE')
  try {
    database
      .prepare(
        `INSERT INTO catalog_roots
       (root_key, identifier_json, graph_hash, sync_state, last_synced_at, retry_at, last_error_code)
       VALUES (?, ?, NULL, 'pending', NULL, NULL, NULL)
       ON CONFLICT(root_key) DO UPDATE SET identifier_json=excluded.identifier_json`,
      )
      .run(result.rootKey, JSON.stringify(result.identifier))
    if (result.status === 'error') {
      const retryAt = new Date(Date.parse(result.hydratedAt) + 60 * 60 * 1_000).toISOString()
      database
        .prepare(
          `UPDATE catalog_roots SET sync_state='error', retry_at=?, last_error_code=? WHERE root_key=?`,
        )
        .run(retryAt, result.error.code.slice(0, 128), result.rootKey)
      database.exec('COMMIT')
      return { counts: catalogCounts(database), recordsChanged: 0, rootsChecked: 1, updated: false }
    }
    if (result.status === 'unchanged') {
      const current = database
        .prepare('SELECT graph_hash FROM catalog_roots WHERE root_key = ?')
        .get(result.rootKey) as { graph_hash: string | null }
      if (current.graph_hash !== result.graphHash)
        throw new CatalogValidationError('An unchanged root has a different graph hash.')
      database
        .prepare(
          `UPDATE catalog_roots SET sync_state='resolved', last_synced_at=?, retry_at=NULL,
         last_error_code=NULL WHERE root_key=?`,
        )
        .run(result.hydratedAt, result.rootKey)
      database.exec('COMMIT')
      return { counts: catalogCounts(database), recordsChanged: 0, rootsChecked: 1, updated: false }
    }

    database.prepare('DELETE FROM catalog_root_records WHERE root_key = ?').run(result.rootKey)
    if (result.status === 'not-found') {
      database
        .prepare(
          `UPDATE catalog_roots SET graph_hash=NULL, sync_state='not-found', last_synced_at=?,
         retry_at=NULL, last_error_code=NULL WHERE root_key=?`,
        )
        .run(result.hydratedAt, result.rootKey)
      garbageCollect(database)
      rebuildAffectedSearchDocuments(database, expandTargets(database, targets))
      database.exec('COMMIT')
      return {
        counts: catalogCounts(database),
        recordsChanged: oldRecords.length,
        rootsChecked: 1,
        updated: oldRecords.length > 0,
      }
    }

    for (const envelope of result.records) {
      targets.push(...targetsForRecord(envelope.record))
      database
        .prepare(
          `INSERT INTO catalog_records (record_key, record_type, sha256, raw_json, updated_at)
         VALUES (?, ?, ?, ?, ?)
         ON CONFLICT(record_key) DO UPDATE SET record_type=excluded.record_type,
          sha256=excluded.sha256, raw_json=excluded.raw_json, updated_at=excluded.updated_at`,
        )
        .run(
          envelope.recordKey,
          envelope.record.type,
          envelope.sha256,
          JSON.stringify(envelope.record),
          result.hydratedAt,
        )
      upsertNormalizedRecord(database, envelope.recordKey, envelope.record)
    }
    const membership = result.recordKeys.map((recordKey) => {
      const row = database
        .prepare('SELECT sha256 FROM catalog_records WHERE record_key = ?')
        .get(recordKey) as { sha256: string } | undefined
      if (!row) throw new CatalogValidationError('A hydration delta omitted an unknown record.')
      return { recordKey, sha256: row.sha256 }
    })
    if (graphHashForMembership(membership) !== result.graphHash) {
      throw new CatalogValidationError('The root graph hash is invalid.')
    }
    const insertMembership = database.prepare(
      'INSERT INTO catalog_root_records (root_key, record_key) VALUES (?, ?)',
    )
    for (const { recordKey } of membership) insertMembership.run(result.rootKey, recordKey)
    database
      .prepare(
        `UPDATE catalog_roots SET graph_hash=?, sync_state='resolved', last_synced_at=?,
       retry_at=NULL, last_error_code=NULL WHERE root_key=?`,
      )
      .run(result.graphHash, result.hydratedAt, result.rootKey)
    garbageCollect(database)
    rebuildAffectedSearchDocuments(database, expandTargets(database, targets))
    database.exec('COMMIT')
    return {
      counts: catalogCounts(database),
      recordsChanged: result.records.length,
      rootsChecked: 1,
      updated: result.records.length > 0 || oldRecords.length !== result.recordKeys.length,
    }
  } catch (error) {
    try {
      database.exec('ROLLBACK')
    } catch {
      /* original error wins */
    }
    throw error
  }
}

export function hydrationRequest(
  database: DatabaseSync,
  identifiers: readonly CatalogHydrationIdentifier[],
): CatalogHydrationRequest {
  const unique = [
    ...new Map(identifiers.map((entry) => [catalogHydrationRootKey(entry), entry])).values(),
  ].slice(0, 25)
  const knownRoots: CatalogHydrationRequest['knownRoots'] = []
  const knownRecords = new Map<string, string>()
  const rootQuery = database.prepare('SELECT graph_hash FROM catalog_roots WHERE root_key = ?')
  const recordsQuery = database.prepare(
    `SELECT r.record_key, r.sha256 FROM catalog_root_records rr
     JOIN catalog_records r ON r.record_key = rr.record_key WHERE rr.root_key = ? LIMIT 500`,
  )
  for (const identifier of unique) {
    const rootKey = catalogHydrationRootKey(identifier)
    const root = rootQuery.get(rootKey) as { graph_hash: string | null } | undefined
    if (root?.graph_hash) knownRoots.push({ rootKey, graphHash: root.graph_hash })
    for (const row of recordsQuery.all(rootKey) as unknown as Array<{
      record_key: string
      sha256: string
    }>) {
      if (knownRecords.size < 5_000) knownRecords.set(row.record_key, row.sha256)
    }
  }
  return {
    schemaVersion: 2,
    identifiers: unique,
    knownRoots,
    knownRecords: [...knownRecords].map(([recordKey, sha256]) => ({ recordKey, sha256 })),
  }
}

export function listInterestedIdentifiers(
  database: DatabaseSync,
  olderThan?: string,
  retryBefore = nowIso(),
): CatalogHydrationIdentifier[] {
  const rows = database
    .prepare(
      `SELECT DISTINCT r.identifier_json FROM catalog_roots r
       JOIN catalog_interests i ON i.root_key = r.root_key
       WHERE (? IS NULL
         OR r.sync_state = 'pending'
         OR (r.sync_state = 'error' AND (r.retry_at IS NULL OR r.retry_at <= ?))
         OR (r.sync_state IN ('resolved', 'not-found')
           AND (r.last_synced_at IS NULL OR r.last_synced_at < ?)))
       ORDER BY r.root_key LIMIT 100000`,
    )
    .all(olderThan ?? null, retryBefore, olderThan ?? null) as unknown as Array<{
    identifier_json: string
  }>
  return rows.map((row) => JSON.parse(row.identifier_json) as CatalogHydrationIdentifier)
}

export function deferCatalogHydrationIdentifiers(
  database: DatabaseSync,
  identifiers: readonly CatalogHydrationIdentifier[],
  retryAt: string,
  errorCode: string,
): void {
  if (identifiers.length === 0) return
  database.exec('BEGIN IMMEDIATE')
  try {
    const update = database.prepare(
      `UPDATE catalog_roots SET sync_state='error', retry_at=?, last_error_code=?
       WHERE root_key=?`,
    )
    for (const identifier of identifiers) {
      update.run(retryAt, errorCode.slice(0, 128), catalogHydrationRootKey(identifier))
    }
    database.exec('COMMIT')
  } catch (error) {
    try {
      database.exec('ROLLBACK')
    } catch {
      /* original error wins */
    }
    throw error
  }
}

export function reconcileInterestScope(
  database: DatabaseSync,
  scopeKey: string,
  kind: CatalogInterestScopeKind,
  identifiers: readonly CatalogHydrationIdentifier[],
  reconciledAt = nowIso(),
): CatalogHydrationIdentifier[] {
  if (!scopeKey.trim() || scopeKey.length > 256)
    throw new Error('The catalog scope key is invalid.')
  const unique = new Map(identifiers.map((entry) => [catalogHydrationRootKey(entry), entry]))
  database.exec('BEGIN IMMEDIATE')
  try {
    const oldRoots = database
      .prepare('SELECT root_key FROM catalog_interests WHERE scope_key = ?')
      .all(scopeKey) as unknown as Array<{ root_key: string }>
    database
      .prepare(
        `INSERT INTO catalog_interest_scopes (scope_key, kind, reconciled_at) VALUES (?, ?, ?)
       ON CONFLICT(scope_key) DO UPDATE SET kind=excluded.kind, reconciled_at=excluded.reconciled_at`,
      )
      .run(scopeKey, kind, reconciledAt)
    database.prepare('DELETE FROM catalog_interests WHERE scope_key = ?').run(scopeKey)
    const insertRoot = database.prepare(
      `INSERT INTO catalog_roots
       (root_key, identifier_json, graph_hash, sync_state, last_synced_at, retry_at, last_error_code)
       VALUES (?, ?, NULL, 'pending', NULL, NULL, NULL)
       ON CONFLICT(root_key) DO UPDATE SET identifier_json=excluded.identifier_json`,
    )
    const insertInterest = database.prepare(
      'INSERT INTO catalog_interests (scope_key, root_key) VALUES (?, ?)',
    )
    for (const [rootKey, identifier] of unique) {
      insertRoot.run(rootKey, JSON.stringify(identifier))
      insertInterest.run(scopeKey, rootKey)
    }
    const removedRoots = oldRoots.filter((entry) => !unique.has(entry.root_key))
    const targets: CatalogSearchTarget[] = []
    for (const { root_key: rootKey } of removedRoots) {
      const count = database
        .prepare('SELECT COUNT(*) AS value FROM catalog_interests WHERE root_key = ?')
        .get(rootKey) as { value: number }
      if (count.value !== 0) continue
      targets.push(...recordsForRoot(database, rootKey).flatMap(targetsForRecord))
      database.prepare('DELETE FROM catalog_roots WHERE root_key = ?').run(rootKey)
    }
    garbageCollect(database)
    rebuildAffectedSearchDocuments(database, expandTargets(database, targets))
    database.exec('COMMIT')
  } catch (error) {
    try {
      database.exec('ROLLBACK')
    } catch {
      /* original error wins */
    }
    throw error
  }
  const pending = database.prepare(
    `SELECT identifier_json FROM catalog_roots
     WHERE root_key = ? AND (
       sync_state = 'pending'
       OR (sync_state = 'error' AND (retry_at IS NULL OR retry_at <= ?))
     )`,
  )
  return [...unique].flatMap(([rootKey]) => {
    const row = pending.get(rootKey, reconciledAt) as { identifier_json: string } | undefined
    return row ? [JSON.parse(row.identifier_json) as CatalogHydrationIdentifier] : []
  })
}

export function removeInterestScope(database: DatabaseSync, scopeKey: string): void {
  reconcileInterestScope(database, scopeKey, 'cloud-account', [])
  database.prepare('DELETE FROM catalog_interest_scopes WHERE scope_key = ?').run(scopeKey)
}
