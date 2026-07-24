import { createHash } from 'node:crypto'

import type {
  LibraryAddOn,
  LibraryCard,
  LibraryDetails,
  LibraryFacetOption,
  LibraryFacets,
  LibraryPage,
  LibraryQueryRequest,
  LibraryStatus,
  LocalManifest,
} from '../../shared/contracts'
import type { CatalogLibraryMetadata, CatalogTaxonomySnapshot } from '../catalog'
import type { EpicLibraryItem } from '../cloud'

export interface LibraryProjectionInput {
  owned: readonly EpicLibraryItem[]
  local: readonly LocalManifest[]
  taxonomy: CatalogTaxonomySnapshot
  resolveMetadata: (input: {
    namespace?: string
    catalogItemId?: string
    artifactId?: string
    appName?: string
    platform?: string
  }) => CatalogLibraryMetadata | null
  signedIn: boolean
  localScanState: LibraryStatus['localScanState']
  refreshing: boolean
  lastRefreshedAt: string | null
  warnings: readonly string[]
}

interface SourceEntry {
  title: string
  appName: string
  namespace: string
  catalogItemId: string
  platform: string
  epicOwned: boolean
  installed: boolean
  localKind: LocalManifest['kind'] | null
  localGroupId: string | null
}

interface ProjectedEntry {
  card: LibraryCard
  description: string
  longDescription: string
  identifiers: string[]
  genreIds: string[]
  featureIds: string[]
  typeIds: string[]
  platformIds: string[]
  subscriptionIds: string[]
  genreNames: string[]
  featureNames: string[]
  subscriptionNames: string[]
  searchText: string
  identityKeys: string[]
  namespaceKeys: string[]
  parentIdentityKey: string | null
  localGroupIds: string[]
  isAddOn: boolean
  addOns: ProjectedEntry[]
}

export interface LibraryProjection {
  entries: ProjectedEntry[]
  details: Map<string, LibraryDetails>
  status: LibraryStatus
}

const identityKey = (namespace: string, catalogItemId: string): string =>
  `${namespace.trim().toLocaleLowerCase()}\u0000${catalogItemId.trim().toLocaleLowerCase()}`

const namespaceKey = (namespace: string): string => namespace.trim().toLocaleLowerCase()

const stableId = (value: string): string =>
  createHash('sha256').update(value, 'utf8').digest('hex').slice(0, 32)

export function buildLibraryProjection(input: LibraryProjectionInput): LibraryProjection {
  const taxonomy = new Map(input.taxonomy.tags.map((tag) => [tag.id, tag]))
  const sources: SourceEntry[] = [
    ...input.owned.map((item) => ({
      title: item.title || item.appName,
      appName: item.appName,
      namespace: item.namespace,
      catalogItemId: item.catalogItemId,
      platform: '',
      epicOwned: true,
      installed: false,
      localKind: null,
      localGroupId: null,
    })),
    ...input.local.map((item) => ({
      title: item.displayName || item.appName,
      appName: item.appName,
      namespace: item.namespace,
      catalogItemId: item.catalogItemId,
      platform: item.platform,
      epicOwned: false,
      installed: true,
      localKind: item.kind,
      localGroupId: item.groupId,
    })),
  ]
  const buckets = new Map<
    string,
    { sources: SourceEntry[]; metadata: CatalogLibraryMetadata | null }
  >()
  for (const source of sources) {
    let metadata: CatalogLibraryMetadata | null = null
    try {
      metadata = input.resolveMetadata({
        namespace: source.namespace,
        catalogItemId: source.catalogItemId,
        artifactId: source.appName,
        appName: source.appName,
        platform: source.platform,
      })
    } catch {
      metadata = null
    }
    const key = metadata
      ? identityKey(metadata.namespace, metadata.catalogItemId)
      : identityKey(source.namespace, source.catalogItemId || source.appName)
    const bucket = buckets.get(key)
    if (bucket) {
      bucket.sources.push(source)
      bucket.metadata ??= metadata
    } else {
      buckets.set(key, { sources: [source], metadata })
    }
  }

  const entries = [...buckets.entries()].map(([key, bucket]) =>
    projectBucket(key, bucket.sources, bucket.metadata, taxonomy),
  )
  const byIdentity = new Map<string, ProjectedEntry>()
  const byLocalGroup = new Map<string, ProjectedEntry>()
  const baseGameByNamespace = new Map<string, ProjectedEntry | null>()
  for (const entry of entries) {
    for (const key of entry.identityKeys) byIdentity.set(key, entry)
    if (!entry.isAddOn) {
      for (const groupId of entry.localGroupIds) byLocalGroup.set(groupId, entry)
      for (const key of entry.namespaceKeys) {
        baseGameByNamespace.set(key, baseGameByNamespace.has(key) ? null : entry)
      }
    }
  }
  const topLevel: ProjectedEntry[] = []
  for (const entry of entries) {
    const parent =
      (entry.parentIdentityKey ? byIdentity.get(entry.parentIdentityKey) : undefined) ??
      entry.localGroupIds.map((groupId) => byLocalGroup.get(groupId)).find(Boolean) ??
      entry.namespaceKeys.map((key) => baseGameByNamespace.get(key)).find(Boolean)
    if (entry.isAddOn && parent && parent !== entry) parent.addOns.push(entry)
    else topLevel.push(entry)
  }
  for (const entry of topLevel) {
    entry.addOns.sort((left, right) => compareTitle(left.card.title, right.card.title))
    entry.card = { ...entry.card, addOnCount: entry.addOns.length }
  }
  const details = new Map<string, LibraryDetails>()
  for (const entry of topLevel) details.set(entry.card.id, detailsFor(entry))
  const partialMetadata = topLevel.filter((entry) => !entry.card.metadataAvailable).length
  const status: LibraryStatus = {
    state: input.refreshing ? 'refreshing' : topLevel.length > 0 ? 'ready' : 'empty',
    total: topLevel.length,
    owned: topLevel.filter((entry) => entry.card.epicOwned).length,
    installed: topLevel.filter((entry) => entry.card.installed).length,
    partialMetadata,
    signedIn: input.signedIn,
    localScanState: input.localScanState,
    lastRefreshedAt: input.lastRefreshedAt,
    taxonomyUpdatedAt: input.taxonomy.updatedAt,
    warnings: [...input.warnings].slice(0, 20),
  }
  return { entries: topLevel, details, status }
}

function projectBucket(
  canonicalKey: string,
  sources: SourceEntry[],
  metadata: CatalogLibraryMetadata | null,
  taxonomy: Map<string, CatalogTaxonomySnapshot['tags'][number]>,
): ProjectedEntry {
  const tags = (metadata?.tagIds ?? []).flatMap((id) => {
    const tag = taxonomy.get(id)
    return tag ? [{ id, name: tag.name, groupName: tag.groupName }] : []
  })
  const genres = tags.filter((tag) => tag.groupName === 'genre')
  const features = tags.filter(
    (tag) => tag.groupName === 'feature' || tag.groupName === 'epicfeature',
  )
  const subscriptions = tags.filter((tag) => tag.groupName === 'subscription')
  const taxonomyPlatforms = tags.filter((tag) => tag.groupName === 'platform')
  const platforms = unique([
    ...(metadata?.platforms ?? []),
    ...sources.map((source) => source.platform),
    ...taxonomyPlatforms.map((tag) => tag.name),
  ]).map(platformLabel)
  const type = metadata?.offerType?.trim() || null
  const title =
    metadata?.title.trim() || sources.find((source) => source.title.trim())?.title || 'Unknown game'
  const appName = sources.find((source) => source.appName.trim())?.appName ?? ''
  const identifiers = unique([
    ...(metadata?.identifiers ?? []),
    ...sources.flatMap((source) => [source.appName, source.namespace, source.catalogItemId]),
  ]).slice(0, 500)
  const identityKeys = unique([
    canonicalKey,
    ...sources.map((source) =>
      identityKey(source.namespace, source.catalogItemId || source.appName),
    ),
  ])
  const localKinds = sources.flatMap((source) => (source.localKind ? [source.localKind] : []))
  const isAddOn =
    (metadata !== null && metadata.kind !== 'base-game') ||
    (metadata === null && localKinds.length > 0 && localKinds.every((kind) => kind === 'addon'))
  const card: LibraryCard = {
    id: stableId(canonicalKey),
    title,
    appName,
    artworkUrl: metadata?.artworkUrl ?? null,
    developer: metadata?.developer ?? null,
    publisher: metadata?.publisher ?? null,
    type,
    platforms,
    installed: sources.some((source) => source.installed),
    epicOwned: sources.some((source) => source.epicOwned),
    addOnCount: 0,
    releaseDate: metadata?.releaseDate ?? null,
    lastModified: metadata?.lastModified ?? null,
    metadataAvailable: metadata !== null,
  }
  const searchText = unique([
    title,
    appName,
    metadata?.developer ?? '',
    metadata?.publisher ?? '',
    ...identifiers,
    ...tags.map((tag) => tag.name),
  ])
    .join('\n')
    .normalize('NFKC')
    .toLocaleLowerCase()
  return {
    card,
    description: metadata?.description ?? '',
    longDescription: metadata?.longDescription ?? '',
    identifiers,
    genreIds: genres.map((tag) => tag.id),
    featureIds: features.map((tag) => tag.id),
    typeIds: type ? [facetId(type)] : [],
    platformIds: platforms.map(facetId),
    subscriptionIds: subscriptions.map((tag) => tag.id),
    genreNames: genres.map((tag) => tag.name),
    featureNames: features.map((tag) => tag.name),
    subscriptionNames: subscriptions.map((tag) => tag.name),
    searchText,
    identityKeys,
    namespaceKeys: unique(sources.map((source) => namespaceKey(source.namespace))),
    parentIdentityKey: metadata?.mainGame
      ? identityKey(metadata.mainGame.catalogNamespace, metadata.mainGame.catalogItemId)
      : null,
    localGroupIds: unique(sources.flatMap((source) => source.localGroupId ?? [])),
    isAddOn,
    addOns: [],
  }
}

export function queryLibraryProjection(
  projection: LibraryProjection,
  request: LibraryQueryRequest,
): LibraryPage {
  const filtered = projection.entries.filter((entry) => matches(entry, request))
  const sorted = [...filtered].sort((left, right) => compareEntries(left, right, request))
  const offset = (request.page - 1) * request.pageSize
  const items = sorted.slice(offset, offset + request.pageSize).map((entry) => ({ ...entry.card }))
  return {
    items,
    total: filtered.length,
    page: request.page,
    pageSize: request.pageSize,
    hasMore: offset + items.length < filtered.length,
    facets: contextualFacets(projection.entries, request),
    status: projection.status,
  }
}

function matches(
  entry: ProjectedEntry,
  request: LibraryQueryRequest,
  omittedFacet?: keyof Pick<
    LibraryQueryRequest,
    'genreIds' | 'featureIds' | 'typeIds' | 'platformIds' | 'subscriptionIds'
  >,
): boolean {
  const query = request.text.normalize('NFKC').toLocaleLowerCase()
  if (query && !entry.searchText.includes(query)) return false
  if (request.installed === 'installed' && !entry.card.installed) return false
  if (request.installed === 'not-installed' && entry.card.installed) return false
  const filters = [
    ['genreIds', entry.genreIds],
    ['featureIds', entry.featureIds],
    ['typeIds', entry.typeIds],
    ['platformIds', entry.platformIds],
    ['subscriptionIds', entry.subscriptionIds],
  ] as const
  return filters.every(([key, values]) =>
    omittedFacet === key || request[key].length === 0
      ? true
      : request[key].some((selected) => values.includes(selected)),
  )
}

function contextualFacets(entries: ProjectedEntry[], request: LibraryQueryRequest): LibraryFacets {
  return {
    genres: countFacet(
      entries,
      request,
      'genreIds',
      (entry) => entry.genreIds,
      (entry, id) =>
        entry.genreIds.indexOf(id) >= 0 ? entry.genreNames[entry.genreIds.indexOf(id)] : undefined,
    ),
    features: countFacet(
      entries,
      request,
      'featureIds',
      (entry) => entry.featureIds,
      (entry, id) =>
        entry.featureIds.indexOf(id) >= 0
          ? entry.featureNames[entry.featureIds.indexOf(id)]
          : undefined,
    ),
    types: countFacet(
      entries,
      request,
      'typeIds',
      (entry) => entry.typeIds,
      (entry) => entry.card.type ?? undefined,
    ),
    platforms: countFacet(
      entries,
      request,
      'platformIds',
      (entry) => entry.platformIds,
      (entry, id) =>
        entry.platformIds.indexOf(id) >= 0
          ? entry.card.platforms[entry.platformIds.indexOf(id)]
          : undefined,
    ),
    subscriptions: countFacet(
      entries,
      request,
      'subscriptionIds',
      (entry) => entry.subscriptionIds,
      (entry, id) =>
        entry.subscriptionIds.indexOf(id) >= 0
          ? entry.subscriptionNames[entry.subscriptionIds.indexOf(id)]
          : undefined,
    ),
  }
}

function countFacet(
  entries: ProjectedEntry[],
  request: LibraryQueryRequest,
  key: 'genreIds' | 'featureIds' | 'typeIds' | 'platformIds' | 'subscriptionIds',
  ids: (entry: ProjectedEntry) => string[],
  label: (entry: ProjectedEntry, id: string) => string | undefined,
): LibraryFacetOption[] {
  const counts = new Map<string, { label: string; count: number }>()
  for (const entry of entries) {
    if (!matches(entry, request, key)) continue
    for (const id of ids(entry)) {
      const optionLabel = label(entry, id)
      if (!optionLabel) continue
      const current = counts.get(id)
      counts.set(id, { label: optionLabel, count: (current?.count ?? 0) + 1 })
    }
  }
  return [...counts.entries()]
    .filter(([id, value]) => value.count > 0 || request[key].includes(id))
    .map(([id, value]) => ({ id, ...value }))
    .sort((left, right) => compareTitle(left.label, right.label))
    .slice(0, 1_000)
}

function compareEntries(
  left: ProjectedEntry,
  right: ProjectedEntry,
  request: LibraryQueryRequest,
): number {
  let result: number
  if (request.sortField === 'title') result = compareTitle(left.card.title, right.card.title)
  else {
    const leftDate = left.card[request.sortField]
    const rightDate = right.card[request.sortField]
    if (leftDate === null || rightDate === null) {
      if (leftDate === rightDate) result = 0
      else result = leftDate === null ? 1 : -1
    } else result = Date.parse(leftDate) - Date.parse(rightDate)
  }
  if (
    request.sortDirection === 'desc' &&
    left.card[request.sortField] !== null &&
    right.card[request.sortField] !== null
  ) {
    result *= -1
  }
  return (
    result ||
    compareTitle(left.card.title, right.card.title) ||
    left.card.id.localeCompare(right.card.id)
  )
}

function detailsFor(entry: ProjectedEntry): LibraryDetails {
  const addOns: LibraryAddOn[] = entry.addOns.map((addOn) => ({
    id: addOn.card.id,
    title: addOn.card.title,
    installed: addOn.card.installed,
    epicOwned: addOn.card.epicOwned,
    type: addOn.card.type,
  }))
  return {
    ...entry.card,
    description: entry.description,
    longDescription: entry.longDescription,
    genres: entry.genreNames,
    features: entry.featureNames,
    subscriptions: entry.subscriptionNames,
    identifiers: entry.identifiers,
    addOns,
  }
}

function unique(values: readonly string[]): string[] {
  return [...new Set(values.map((value) => value.trim()).filter(Boolean))]
}

function facetId(value: string): string {
  return value
    .normalize('NFKC')
    .trim()
    .toLocaleLowerCase()
    .replace(/[^\p{L}\p{N}]+/gu, '-')
}

function platformLabel(value: string): string {
  const normalized = value.trim().toLocaleLowerCase()
  if (normalized === 'win32' || normalized === 'windows') return 'Windows'
  if (normalized === 'darwin' || normalized === 'mac' || normalized === 'macos') return 'macOS'
  if (normalized === 'linux') return 'Linux'
  return value.trim()
}

function compareTitle(left: string, right: string): number {
  return left.localeCompare(right, undefined, { sensitivity: 'base', numeric: true })
}
