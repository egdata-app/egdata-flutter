import { DatabaseSync } from 'node:sqlite'

import type { CatalogItemRecord, CatalogOfferRecord } from './types'
import { compositeKey, imageFromRecord, optionalString, parseJsonObject } from './database-utils'
import type { ItemRow, OfferRow } from './database-rows'

export type CatalogSearchTarget =
  | { kind: 'offer'; namespace: string; id: string }
  | { kind: 'item'; namespace: string; id: string }

const documentId = (kind: 'offer' | 'orphan-item', namespace: string, id: string): string =>
  `${kind}\0${namespace}\0${id}`

const deleteDocument = (
  database: DatabaseSync,
  kind: 'offer' | 'orphan-item',
  namespace: string,
  id: string,
): void => {
  const idValue = documentId(kind, namespace, id)
  database.prepare('DELETE FROM catalog_fts WHERE document_id = ?').run(idValue)
  database
    .prepare(
      'DELETE FROM catalog_identifiers WHERE target_kind = ? AND target_namespace = ? AND target_id = ?',
    )
    .run(kind, namespace, id)
  database.prepare('DELETE FROM catalog_search_documents WHERE document_id = ?').run(idValue)
}

const addIdentifier = (
  database: DatabaseSync,
  kind: 'offer' | 'orphan-item',
  namespace: string,
  id: string,
  identifier: string | undefined,
  field: string,
  priority: number,
): void => {
  const bounded = identifier?.trim().slice(0, 4_096)
  if (!bounded) return
  database
    .prepare(
      `INSERT OR IGNORE INTO catalog_identifiers
       (target_kind, target_namespace, target_id, identifier, identifier_lower, field, priority)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
    )
    .run(kind, namespace, id, bounded, bounded.toLocaleLowerCase('en-US'), field, priority)
}

const itemRowsForOffer = (database: DatabaseSync, namespace: string, id: string): ItemRow[] =>
  database
    .prepare(
      `SELECT i.* FROM catalog_offer_items e
       JOIN catalog_items i ON i.namespace = e.item_namespace AND i.id = e.item_id
       WHERE e.offer_namespace = ? AND e.offer_id = ?
       ORDER BY i.namespace, i.id LIMIT 500`,
    )
    .all(namespace, id) as unknown as ItemRow[]

const platformsForItems = (database: DatabaseSync, items: readonly ItemRow[]): string[] => {
  const result = new Set<string>()
  const queryAssets = database.prepare(
    'SELECT platform FROM catalog_assets WHERE item_namespace = ? AND item_id = ? LIMIT 100',
  )
  const queryApps = database.prepare(
    'SELECT platform FROM catalog_release_apps WHERE item_namespace = ? AND item_id = ? LIMIT 100',
  )
  for (const item of items) {
    for (const row of [
      ...(queryAssets.all(item.namespace, item.id) as unknown as Array<{ platform: string }>),
      ...(queryApps.all(item.namespace, item.id) as unknown as Array<{ platform: string }>),
    ])
      result.add(row.platform)
  }
  return [...result].sort((left, right) => left.localeCompare(right)).slice(0, 64)
}

const upsertDocument = (
  database: DatabaseSync,
  kind: 'offer' | 'orphan-item',
  namespace: string,
  id: string,
  offer: OfferRow | null,
  items: ItemRow[],
): void => {
  const selectedItem = items[0]
  if (!offer && !selectedItem) return
  const offerRecord = offer ? parseJsonObject<CatalogOfferRecord>(offer.raw_json) : null
  const itemRecords = items.map((row) => parseJsonObject<CatalogItemRecord>(row.raw_json))
  const title = offer?.title ?? selectedItem?.title ?? ''
  const description = offer?.description ?? selectedItem?.description ?? ''
  const developer = offer?.developer ?? optionalString(itemRecords[0]?.developer) ?? null
  const publisher = offer?.publisher ?? null
  const imageUrl = offer?.image_url ?? (itemRecords[0] ? imageFromRecord(itemRecords[0]) : null)
  const platforms = platformsForItems(database, items)
  const idValue = documentId(kind, namespace, id)
  database
    .prepare(
      `INSERT INTO catalog_search_documents
       (document_id, kind, namespace, id, title, description, offer_type, developer, publisher,
        image_url, platforms_json, platforms_search, item_count)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
       ON CONFLICT(document_id) DO UPDATE SET
         title=excluded.title, description=excluded.description, offer_type=excluded.offer_type,
         developer=excluded.developer, publisher=excluded.publisher, image_url=excluded.image_url,
         platforms_json=excluded.platforms_json, platforms_search=excluded.platforms_search,
         item_count=excluded.item_count`,
    )
    .run(
      idValue,
      kind,
      namespace,
      id,
      title,
      description,
      offer?.offer_type ?? null,
      developer,
      publisher,
      imageUrl,
      JSON.stringify(platforms),
      `\n${platforms.map((entry) => entry.toLocaleLowerCase('en-US')).join('\n')}\n`,
      items.length,
    )
  addIdentifier(database, kind, namespace, id, namespace, 'namespace', 10)
  addIdentifier(database, kind, namespace, id, id, kind === 'offer' ? 'offer-id' : 'item-id', 0)
  if (offerRecord) {
    addIdentifier(database, kind, namespace, id, offerRecord.productSlug, 'product-slug', 20)
    addIdentifier(database, kind, namespace, id, offerRecord.urlSlug, 'url-slug', 20)
  }
  const technicalIdentifiers: string[] = []
  const queryAssets = database.prepare(
    'SELECT artifact_id FROM catalog_assets WHERE item_namespace = ? AND item_id = ? LIMIT 500',
  )
  const queryApps = database.prepare(
    'SELECT app_id FROM catalog_release_apps WHERE item_namespace = ? AND item_id = ? LIMIT 500',
  )
  for (const item of items) {
    addIdentifier(database, kind, namespace, id, item.id, 'item-id', 1)
    for (const row of queryAssets.all(item.namespace, item.id) as unknown as Array<{
      artifact_id: string
    }>) {
      technicalIdentifiers.push(row.artifact_id)
      addIdentifier(database, kind, namespace, id, row.artifact_id, 'artifact-id', 2)
    }
    for (const row of queryApps.all(item.namespace, item.id) as unknown as Array<{
      app_id: string
    }>) {
      technicalIdentifiers.push(row.app_id)
      addIdentifier(database, kind, namespace, id, row.app_id, 'app-id', 2)
    }
  }
  database.prepare('DELETE FROM catalog_fts WHERE document_id = ?').run(idValue)
  database
    .prepare(
      `INSERT INTO catalog_fts
       (document_id, offer_title, parties, item_titles, descriptions, technical_details,
        custom_attributes, identifiers, slugs)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    )
    .run(
      idValue,
      offer?.title ?? '',
      [developer, publisher].filter(Boolean).join(' '),
      items.map((item) => item.title).join(' '),
      [
        offer?.description,
        offer?.long_description,
        ...items.flatMap((item) => [item.description, item.long_description]),
      ]
        .filter(Boolean)
        .join(' '),
      items.map((item) => item.technical_details).join(' '),
      itemRecords.map((item) => JSON.stringify(item.customAttributes)).join(' '),
      [namespace, id, ...items.map((item) => item.id), ...technicalIdentifiers].join(' '),
      [offerRecord?.productSlug, offerRecord?.urlSlug].filter(Boolean).join(' '),
    )
}

export function rebuildAffectedSearchDocuments(
  database: DatabaseSync,
  targets: readonly CatalogSearchTarget[],
): void {
  const unique = new Map(
    targets.map((target) => [
      `${target.kind}\0${compositeKey(target.namespace, target.id)}`,
      target,
    ]),
  )
  for (const target of unique.values()) {
    if (target.kind === 'offer') {
      deleteDocument(database, 'offer', target.namespace, target.id)
      const offer = database
        .prepare('SELECT * FROM catalog_offers WHERE namespace = ? AND id = ?')
        .get(target.namespace, target.id) as OfferRow | undefined
      if (offer)
        upsertDocument(
          database,
          'offer',
          target.namespace,
          target.id,
          offer,
          itemRowsForOffer(database, target.namespace, target.id),
        )
      continue
    }
    deleteDocument(database, 'orphan-item', target.namespace, target.id)
    const item = database
      .prepare('SELECT * FROM catalog_items WHERE namespace = ? AND id = ?')
      .get(target.namespace, target.id) as ItemRow | undefined
    if (!item) continue
    const edge = database
      .prepare('SELECT 1 FROM catalog_offer_items WHERE item_namespace = ? AND item_id = ? LIMIT 1')
      .get(target.namespace, target.id)
    if (!edge) upsertDocument(database, 'orphan-item', target.namespace, target.id, null, [item])
  }
}
