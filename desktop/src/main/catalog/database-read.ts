import { DatabaseSync } from 'node:sqlite'

import {
  CATALOG_DEFAULT_PAGE_SIZE,
  CATALOG_MAX_PAGE_SIZE,
  type CatalogAssetRecord,
  type CatalogDetails,
  type CatalogDetailsRequest,
  type CatalogItemRecord,
  type CatalogLauncherCandidateInput,
  type CatalogLauncherIdentity,
  type CatalogLauncherResolution,
  type CatalogLibraryMetadata,
  type CatalogNameResolution,
  type CatalogNameResolutionInput,
  type CatalogOfferRecord,
  type CatalogReleaseAppRecord,
  type CatalogSearchPage,
  type CatalogSearchRequest,
  type CatalogSearchResult,
  type CatalogSearchResultKind,
} from './types'
import {
  arrayAttribute,
  attributeMap,
  attributeValue,
  booleanAttribute,
  compositeKey,
  ftsQuery,
  imagesFromRecords,
  launcherKind,
  optionalString,
  parseJsonObject,
  stringList,
} from './database-utils'
import type { ItemRow, OfferRow, SearchDocumentRow } from './database-rows'

export function searchCatalog(
  database: DatabaseSync,
  request: CatalogSearchRequest,
): CatalogSearchPage {
  const page = Math.max(1, Math.min(1_000_000, request.page ?? 1))
  const pageSize = Math.max(
    1,
    Math.min(CATALOG_MAX_PAGE_SIZE, request.pageSize ?? CATALOG_DEFAULT_PAGE_SIZE),
  )
  const query = request.query.trim().slice(0, 512)
  const kind =
    request.resultKind === 'offers'
      ? 'offer'
      : request.resultKind === 'orphan-items'
        ? 'orphan-item'
        : null
  const offerType = request.offerType?.trim().slice(0, 128) || null
  const platform = request.platform?.trim().slice(0, 64).toLowerCase() || null
  const filters = [
    kind ? 'd.kind = ?' : '',
    offerType ? 'd.offer_type = ? COLLATE NOCASE' : '',
    platform ? 'instr(d.platforms_search, ?) > 0' : '',
  ].filter(Boolean)
  const filterValues: Array<string | number> = [
    ...(kind ? [kind] : []),
    ...(offerType ? [offerType] : []),
    ...(platform ? [`\n${platform}\n`] : []),
  ]
  const whereBase = filters.length ? filters.join(' AND ') : '1 = 1'
  const offset = (page - 1) * pageSize
  let rows: SearchDocumentRow[]
  let total: number
  if (!query) {
    total = Number(
      (
        database
          .prepare(`SELECT COUNT(*) AS total FROM catalog_search_documents d WHERE ${whereBase}`)
          .get(...filterValues) as { total: number }
      ).total,
    )
    rows = database
      .prepare(
        `SELECT d.kind, d.namespace, d.id, d.title, d.description, d.offer_type, d.developer,
       d.publisher, d.image_url, d.platforms_json, d.item_count
       FROM catalog_search_documents d WHERE ${whereBase}
       ORDER BY d.title COLLATE NOCASE, d.namespace, d.id LIMIT ? OFFSET ?`,
      )
      .all(...filterValues, pageSize, offset) as unknown as SearchDocumentRow[]
  } else {
    const match = ftsQuery(query)
    if (!match) {
      const where = `${whereBase} AND d.title LIKE ? COLLATE NOCASE`
      const values = [...filterValues, `%${query}%`]
      total = Number(
        (
          database
            .prepare(`SELECT COUNT(*) AS total FROM catalog_search_documents d WHERE ${where}`)
            .get(...values) as { total: number }
        ).total,
      )
      rows = database
        .prepare(
          `SELECT d.kind, d.namespace, d.id, d.title, d.description, d.offer_type, d.developer,
         d.publisher, d.image_url, d.platforms_json, d.item_count
         FROM catalog_search_documents d WHERE ${where}
         ORDER BY CASE WHEN d.title = ? COLLATE NOCASE THEN 0 ELSE 1 END,
         d.title COLLATE NOCASE, d.namespace, d.id LIMIT ? OFFSET ?`,
        )
        .all(...values, query, pageSize, offset) as unknown as SearchDocumentRow[]
    } else {
      const where = `${whereBase} AND catalog_fts MATCH ?`
      const values = [...filterValues, match]
      total = Number(
        (
          database
            .prepare(
              `SELECT COUNT(*) AS total FROM catalog_fts
         JOIN catalog_search_documents d ON d.document_id = catalog_fts.document_id WHERE ${where}`,
            )
            .get(...values) as { total: number }
        ).total,
      )
      rows = database
        .prepare(
          `SELECT d.kind, d.namespace, d.id, d.title, d.description, d.offer_type, d.developer,
         d.publisher, d.image_url, d.platforms_json, d.item_count
         FROM catalog_fts JOIN catalog_search_documents d ON d.document_id = catalog_fts.document_id
         WHERE ${where}
         ORDER BY COALESCE((SELECT MIN(i.priority) FROM catalog_identifiers i
           WHERE i.target_kind=d.kind AND i.target_namespace=d.namespace AND i.target_id=d.id
             AND i.identifier_lower=?), 100),
          CASE WHEN d.title=? COLLATE NOCASE THEN 0
               WHEN d.title LIKE (? || '%') COLLATE NOCASE THEN 1 ELSE 2 END,
          bm25(catalog_fts, 0, 16, 8, 12, 5, 4, 3, 14, 7),
          d.title COLLATE NOCASE, d.namespace, d.id LIMIT ? OFFSET ?`,
        )
        .all(
          ...values,
          query.toLowerCase(),
          query,
          query,
          pageSize,
          offset,
        ) as unknown as SearchDocumentRow[]
    }
  }
  const items = rows.map((row) => searchResult(database, row, query))
  return { items, total, page, pageSize, hasMore: offset + items.length < total }
}

function searchResult(
  database: DatabaseSync,
  row: SearchDocumentRow,
  query: string,
): CatalogSearchResult {
  const matchedIdentifiers = query
    ? (
        database
          .prepare(
            `SELECT identifier FROM catalog_identifiers WHERE target_kind=? AND target_namespace=?
         AND target_id=? AND identifier_lower LIKE ? ORDER BY priority, identifier COLLATE NOCASE LIMIT 500`,
          )
          .all(row.kind, row.namespace, row.id, `${query.toLowerCase()}%`) as unknown as Array<{
          identifier: string
        }>
      ).map((entry) => entry.identifier)
    : []
  const decoded: unknown = JSON.parse(row.platforms_json)
  return {
    kind: row.kind,
    namespace: row.namespace,
    id: row.id,
    title: row.title,
    description: row.description,
    offerType: row.offer_type,
    developer: row.developer,
    publisher: row.publisher,
    imageUrl: row.image_url,
    platforms: Array.isArray(decoded)
      ? decoded.filter((entry): entry is string => typeof entry === 'string').slice(0, 64)
      : [],
    itemCount: row.item_count,
    matchedIdentifiers,
  }
}

export function getCatalogDetails(
  database: DatabaseSync,
  request: CatalogDetailsRequest,
): CatalogDetails | null {
  if (request.kind === 'offer') {
    const offer = database
      .prepare('SELECT * FROM catalog_offers WHERE namespace=? AND id=?')
      .get(request.namespace, request.id) as OfferRow | undefined
    if (!offer) return null
    const items = database
      .prepare(
        `SELECT i.* FROM catalog_offer_items e JOIN catalog_items i
       ON i.namespace=e.item_namespace AND i.id=e.item_id
       WHERE e.offer_namespace=? AND e.offer_id=?
       ORDER BY i.title COLLATE NOCASE, i.namespace, i.id LIMIT 500`,
      )
      .all(request.namespace, request.id) as unknown as ItemRow[]
    return detailsFor(database, 'offer', offer, items)
  }
  const item = database
    .prepare('SELECT * FROM catalog_items WHERE namespace=? AND id=?')
    .get(request.namespace, request.id) as ItemRow | undefined
  return item ? detailsFor(database, 'orphan-item', null, [item]) : null
}

export function getCatalogLibraryMetadata(
  database: DatabaseSync,
  input: CatalogNameResolutionInput,
): CatalogLibraryMetadata | null {
  const item = resolveItem(database, input)
  if (!item) return null
  const itemRecord = parseJsonObject<CatalogItemRecord>(item.raw_json)
  const offer = database
    .prepare(
      `SELECT o.* FROM catalog_offer_items link
       JOIN catalog_offers o ON o.namespace=link.offer_namespace AND o.id=link.offer_id
       WHERE link.item_namespace=? AND link.item_id=?
       ORDER BY link.is_primary DESC, o.title COLLATE NOCASE, o.id LIMIT 1`,
    )
    .get(item.namespace, item.id) as OfferRow | undefined
  const offerRecord = offer ? parseJsonObject<CatalogOfferRecord>(offer.raw_json) : null
  const images = imagesFromRecords([...(offerRecord ? [offerRecord] : []), itemRecord])
  const artwork =
    images.find((image) => image.type.toLowerCase() === 'dieselgameboxtall') ??
    images.find((image) => image.type.toLowerCase() === 'offerimagetall') ??
    images.find((image) => /tall|portrait|box/i.test(image.type)) ??
    images[0]
  const platformRows = database
    .prepare(
      `SELECT platform, artifact_id AS identifier FROM catalog_assets WHERE item_namespace=? AND item_id=?
       UNION SELECT platform, app_id AS identifier FROM catalog_release_apps WHERE item_namespace=? AND item_id=?`,
    )
    .all(item.namespace, item.id, item.namespace, item.id) as unknown as Array<{
    platform: string
    identifier: string
  }>
  const attributes = attributeMap(itemRecord)
  const mainNamespace = optionalString(
    attributeValue(attributes, 'mainGameCatalogNamespace', 'mainGameNamespace', 'parentNamespace'),
  )
  const mainItemId = optionalString(
    attributeValue(attributes, 'mainGameCatalogItemId', 'mainGameItemId', 'parentItemId'),
  )
  const mainArtifact = optionalString(
    attributeValue(attributes, 'mainGameAppName', 'mainGameArtifactId', 'parentArtifactId'),
  )
  const name = nameResolution(database, item)
  const tagIds = catalogTagIds([offerRecord?.tags, (itemRecord as Record<string, unknown>).tags])
  const releaseDate = catalogDate(
    offerRecord?.releaseDate ??
      offerRecord?.effectiveDate ??
      itemRecord.releaseDate ??
      itemRecord.effectiveDate,
  )
  const lastModified = catalogDate(
    offerRecord?.lastModifiedDate ??
      offerRecord?.lastModified ??
      offerRecord?.updatedAt ??
      itemRecord.lastModifiedDate ??
      itemRecord.lastModified ??
      itemRecord.updatedAt,
  )
  const kind = launcherKind(itemRecord)
  return {
    namespace: item.namespace,
    catalogItemId: item.id,
    offerId: offer?.id ?? null,
    title:
      (kind === 'base-game' ? offer?.title || item.title : item.title || offer?.title) ||
      name?.displayName ||
      input.appName ||
      '',
    description: offer?.description ?? item.description ?? '',
    longDescription: offer?.long_description ?? item.long_description ?? '',
    developer: offer?.developer ?? null,
    publisher: offer?.publisher ?? null,
    offerType: offer?.offer_type ?? optionalString(itemRecord.itemType),
    artworkUrl: artwork?.url ?? null,
    platforms: [...new Set(platformRows.map((row) => row.platform).filter(Boolean))].slice(0, 64),
    tagIds,
    identifiers: [
      item.namespace,
      item.id,
      ...(offer ? [offer.namespace, offer.id] : []),
      ...platformRows.map((row) => row.identifier),
    ].filter((value, index, values) => Boolean(value) && values.indexOf(value) === index),
    releaseDate,
    lastModified,
    kind,
    mainGame:
      mainNamespace && mainItemId && mainArtifact
        ? {
            catalogNamespace: mainNamespace,
            catalogItemId: mainItemId,
            artifactId: mainArtifact,
          }
        : null,
  }
}

function catalogTagIds(values: unknown[]): string[] {
  const result: string[] = []
  for (const value of values) {
    if (!Array.isArray(value)) continue
    for (const entry of value) {
      const id =
        typeof entry === 'string'
          ? entry.trim()
          : entry && typeof entry === 'object' && !Array.isArray(entry)
            ? (optionalString((entry as Record<string, unknown>).id) ??
              optionalString((entry as Record<string, unknown>).tagId))
            : null
      if (id && !result.includes(id)) result.push(id)
      if (result.length >= 1_000) return result
    }
  }
  return result
}

function catalogDate(value: unknown): string | null {
  if (typeof value !== 'string' && typeof value !== 'number') return null
  const timestamp = new Date(value).valueOf()
  return Number.isFinite(timestamp) ? new Date(timestamp).toISOString() : null
}

function detailsFor(
  database: DatabaseSync,
  kind: CatalogSearchResultKind,
  selectedOffer: OfferRow | null,
  itemRows: ItemRow[],
): CatalogDetails {
  const items = itemRows.map((row) => parseJsonObject<CatalogItemRecord>(row.raw_json))
  const assets: CatalogAssetRecord[] = []
  const releaseApps: CatalogReleaseAppRecord[] = []
  const offers = new Map<string, CatalogOfferRecord>()
  if (selectedOffer)
    offers.set(
      compositeKey(selectedOffer.namespace, selectedOffer.id),
      parseJsonObject<CatalogOfferRecord>(selectedOffer.raw_json),
    )
  const assetQuery = database.prepare(
    'SELECT raw_json FROM catalog_assets WHERE item_namespace=? AND item_id=? ORDER BY platform, artifact_id LIMIT 500',
  )
  const appQuery = database.prepare(
    'SELECT raw_json FROM catalog_release_apps WHERE item_namespace=? AND item_id=? ORDER BY platform, app_id LIMIT 500',
  )
  const offerQuery = database.prepare(
    `SELECT o.raw_json, o.namespace, o.id FROM catalog_offer_items e JOIN catalog_offers o
     ON o.namespace=e.offer_namespace AND o.id=e.offer_id
     WHERE e.item_namespace=? AND e.item_id=? ORDER BY e.is_primary DESC, o.title, o.id LIMIT 500`,
  )
  for (const item of itemRows) {
    for (const row of assetQuery.all(item.namespace, item.id) as unknown as Array<{
      raw_json: string
    }>)
      if (assets.length < 500) assets.push(parseJsonObject<CatalogAssetRecord>(row.raw_json))
    for (const row of appQuery.all(item.namespace, item.id) as unknown as Array<{
      raw_json: string
    }>)
      if (releaseApps.length < 500)
        releaseApps.push(parseJsonObject<CatalogReleaseAppRecord>(row.raw_json))
    for (const row of offerQuery.all(item.namespace, item.id) as unknown as Array<{
      raw_json: string
      namespace: string
      id: string
    }>) {
      if (offers.size < 500)
        offers.set(
          compositeKey(row.namespace, row.id),
          parseJsonObject<CatalogOfferRecord>(row.raw_json),
        )
    }
  }
  const offerRecord = selectedOffer
    ? parseJsonObject<CatalogOfferRecord>(selectedOffer.raw_json)
    : null
  const selectedItem = itemRows[0]
  return {
    kind,
    namespace: selectedOffer?.namespace ?? selectedItem?.namespace ?? '',
    id: selectedOffer?.id ?? selectedItem?.id ?? '',
    title: selectedOffer?.title ?? selectedItem?.title ?? '',
    description: selectedOffer?.description ?? selectedItem?.description ?? '',
    longDescription: selectedOffer?.long_description ?? selectedItem?.long_description ?? '',
    offer: offerRecord,
    items,
    offers: [...offers.values()],
    assets,
    releaseApps,
    platforms: [
      ...new Set([
        ...assets.map((entry) => entry.platform),
        ...releaseApps.map((entry) => entry.platform),
      ]),
    ].slice(0, 64),
    images: imagesFromRecords([...(offerRecord ? [offerRecord] : []), ...items]),
  }
}

export function resolveCatalogDisplayName(
  database: DatabaseSync,
  input: CatalogNameResolutionInput,
): CatalogNameResolution | null {
  const item = resolveItem(database, input)
  return item ? nameResolution(database, item) : null
}

export function resolveCatalogLauncherCandidate(
  database: DatabaseSync,
  input: CatalogLauncherCandidateInput,
): CatalogLauncherResolution | null {
  if (!input.buildAppName.trim() || !input.platform.trim()) return null
  const hint = input.catalogHint
  const item = resolveItem(database, {
    ...(hint?.catalogNamespace ? { namespace: hint.catalogNamespace } : {}),
    ...(hint?.catalogItemId ? { catalogItemId: hint.catalogItemId } : {}),
    ...(hint?.artifactId ? { artifactId: hint.artifactId } : {}),
    appName: input.buildAppName,
    platform: input.platform,
  })
  if (!item) return null
  const name = nameResolution(database, item)
  if (!name) return null
  const record = parseJsonObject<CatalogItemRecord>(item.raw_json)
  const attributes = attributeMap(record)
  const asset = database
    .prepare(
      `SELECT artifact_id FROM catalog_assets WHERE item_namespace=? AND item_id=? AND platform=? COLLATE NOCASE
     ORDER BY CASE WHEN artifact_id=? COLLATE NOCASE THEN 0 ELSE 1 END, artifact_id COLLATE NOCASE LIMIT 1`,
    )
    .get(item.namespace, item.id, input.platform, hint?.artifactId ?? input.buildAppName) as
    | { artifact_id: string }
    | undefined
  const mainNamespace = optionalString(
    attributeValue(attributes, 'mainGameCatalogNamespace', 'mainGameNamespace', 'parentNamespace'),
  )
  const mainItemId = optionalString(
    attributeValue(attributes, 'mainGameCatalogItemId', 'mainGameItemId', 'parentItemId'),
  )
  const mainArtifact = optionalString(
    attributeValue(attributes, 'mainGameAppName', 'mainGameArtifactId', 'parentArtifactId'),
  )
  const mainGame: CatalogLauncherIdentity | null =
    mainNamespace && mainItemId && mainArtifact
      ? { catalogNamespace: mainNamespace, catalogItemId: mainItemId, artifactId: mainArtifact }
      : null
  return {
    artifactId: asset?.artifact_id ?? hint?.artifactId?.trim() ?? input.buildAppName.trim(),
    catalogItemId: item.id,
    catalogNamespace: item.namespace,
    displayName: name.displayName,
    kind: launcherKind(record),
    appCategories: stringList(record.categories),
    mainGame,
    mandatoryAppFolderName:
      optionalString(attributeValue(attributes, 'mandatoryAppFolderName', 'folderName')) ?? '',
    canRunOffline: booleanAttribute(
      attributeValue(attributes, 'canRunOffline', 'bCanRunOffline'),
      false,
    ),
    requiresAuth: booleanAttribute(
      attributeValue(attributes, 'requiresAuth', 'bRequiresAuth'),
      true,
    ),
    ownershipToken: booleanAttribute(
      attributeValue(attributes, 'ownershipToken', 'requiresOwnershipToken'),
      false,
    ),
    ignoredProcessNames: arrayAttribute(
      attributeValue(attributes, 'ignoredProcessNames', 'processNamesToIgnore'),
    ),
  }
}

function resolveItem(database: DatabaseSync, input: CatalogNameResolutionInput): ItemRow | null {
  const namespace = input.namespace?.trim()
  const catalogItemId = input.catalogItemId?.trim()
  if (namespace && catalogItemId) {
    const exact = database
      .prepare('SELECT * FROM catalog_items WHERE namespace=? AND id=?')
      .get(namespace, catalogItemId) as ItemRow | undefined
    if (exact) return exact
  }
  const identifiers = [
    ...new Set(
      [input.artifactId, input.appName].map((entry) => entry?.trim()).filter(Boolean) as string[],
    ),
  ]
  if (!identifiers.length) return null
  const candidates = new Map<string, { namespace: string; id: string }>()
  for (const identifier of identifiers) {
    const platformClause = input.platform?.trim() ? ' AND platform=? COLLATE NOCASE' : ''
    const namespaceClause = namespace
      ? ' AND (namespace=? COLLATE NOCASE OR item_namespace=? COLLATE NOCASE)'
      : ''
    const values = [
      identifier,
      ...(input.platform?.trim() ? [input.platform.trim()] : []),
      ...(namespace ? [namespace, namespace] : []),
    ]
    const assets = database
      .prepare(
        `SELECT item_namespace, item_id FROM catalog_assets WHERE artifact_id=? COLLATE NOCASE${platformClause}${namespaceClause}`,
      )
      .all(...values) as unknown as Array<{ item_namespace: string; item_id: string }>
    const apps = database
      .prepare(
        `SELECT item_namespace, item_id FROM catalog_release_apps WHERE app_id=? COLLATE NOCASE${platformClause}${namespaceClause}`,
      )
      .all(...values) as unknown as Array<{ item_namespace: string; item_id: string }>
    for (const row of [...assets, ...apps])
      candidates.set(compositeKey(row.item_namespace, row.item_id), {
        namespace: row.item_namespace,
        id: row.item_id,
      })
  }
  if (candidates.size !== 1) return null
  const candidate = [...candidates.values()][0]
  return candidate
    ? ((database
        .prepare('SELECT * FROM catalog_items WHERE namespace=? AND id=?')
        .get(candidate.namespace, candidate.id) as ItemRow | undefined) ?? null)
    : null
}

function nameResolution(database: DatabaseSync, item: ItemRow): CatalogNameResolution | null {
  let offer: OfferRow | undefined
  if (item.primary_offer_namespace && item.primary_offer_id) {
    offer = database
      .prepare('SELECT * FROM catalog_offers WHERE namespace=? AND id=?')
      .get(item.primary_offer_namespace, item.primary_offer_id) as OfferRow | undefined
  }
  offer ??= database
    .prepare(
      `SELECT o.* FROM catalog_offer_items e JOIN catalog_offers o
     ON o.namespace=e.offer_namespace AND o.id=e.offer_id
     WHERE e.item_namespace=? AND e.item_id=? ORDER BY e.is_primary DESC,
      CASE json_extract(e.sources_json, '$[0]') WHEN 'direct' THEN 0 WHEN 'subitem' THEN 1 ELSE 2 END,
      o.id LIMIT 1`,
    )
    .get(item.namespace, item.id) as OfferRow | undefined
  const itemRecord = parseJsonObject<CatalogItemRecord>(item.raw_json)
  const displayName =
    launcherKind(itemRecord) === 'base-game'
      ? offer?.title || item.title
      : item.title || offer?.title
  return displayName
    ? {
        displayName,
        namespace: item.namespace,
        catalogItemId: item.id,
        itemTitle: item.title || null,
        offerNamespace: offer?.namespace ?? null,
        offerId: offer?.id ?? null,
        offerTitle: offer?.title ?? null,
      }
    : null
}
