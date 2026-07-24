export const CATALOG_SCHEMA_VERSION = 2
export const CATALOG_DEFAULT_PAGE_SIZE = 50
export const CATALOG_MAX_PAGE_SIZE = 100
export const CATALOG_MAX_ROOT_RECORDS = 500
export const CATALOG_MAX_ROOT_BYTES = 2 * 1024 * 1024

export interface CatalogCounts {
  offers: number
  items: number
  assets: number
  releaseApps: number
  offerItems: number
}

export interface CatalogKeyImage {
  type: string
  url: string
  [key: string]: unknown
}

export interface CatalogOfferRecord {
  type: 'offer'
  namespace: string
  id: string
  title: string
  description?: string
  longDescription?: string
  offerType?: string
  seller?: string
  developerDisplayName?: string
  publisherDisplayName?: string
  productSlug?: string
  urlSlug?: string
  url?: string
  keyImages: unknown[]
  tags: unknown[]
  categories: unknown[]
  customAttributes: unknown[] | Record<string, unknown>
  [key: string]: unknown
}

export interface CatalogItemRecord {
  type: 'item'
  namespace: string
  id: string
  title: string
  description?: string
  longDescription?: string
  technicalDetails?: string
  status?: string
  itemType?: string
  keyImages: unknown[]
  categories: unknown[]
  customAttributes: unknown[] | Record<string, unknown>
  installModes: unknown[]
  primaryOfferNamespace?: string
  primaryOfferId?: string
  [key: string]: unknown
}

export interface CatalogAssetRecord {
  type: 'asset'
  namespace: string
  artifactId: string
  platform: string
  itemNamespace: string
  itemId: string
  downloadSizeBytes?: number
  installedSizeBytes?: number
  primaryOfferNamespace?: string
  primaryOfferId?: string
}

export interface CatalogReleaseAppRecord {
  type: 'release-app'
  namespace: string
  appId: string
  platform: string
  itemNamespace: string
  itemId: string
  releaseId?: string
  primaryOfferNamespace?: string
  primaryOfferId?: string
}

export type CatalogOfferItemSource = 'direct' | 'subitem' | 'linked'

export interface CatalogOfferItemRecord {
  type: 'offer-item'
  offerNamespace: string
  offerId: string
  itemNamespace: string
  itemId: string
  sources: CatalogOfferItemSource[]
  isPrimary: boolean
}

export type CatalogRecord =
  | CatalogOfferRecord
  | CatalogItemRecord
  | CatalogAssetRecord
  | CatalogReleaseAppRecord
  | CatalogOfferItemRecord

export type CatalogHydrationIdentifier =
  | { type: 'item'; namespace: string; id: string }
  | {
      type: 'asset'
      namespace: string
      artifactId: string
      platform: string
    }
  | {
      type: 'release-app'
      namespace: string
      appId: string
      platform: string
    }

export interface CatalogHydrationKnownRoot {
  rootKey: string
  graphHash: string
}

export interface CatalogHydrationKnownRecord {
  recordKey: string
  sha256: string
}

export interface CatalogHydrationRequest {
  schemaVersion: 2
  identifiers: CatalogHydrationIdentifier[]
  knownRoots: CatalogHydrationKnownRoot[]
  knownRecords: CatalogHydrationKnownRecord[]
}

interface CatalogHydrationRootBase {
  schemaVersion: 2
  rootKey: string
  identifier: CatalogHydrationIdentifier
  hydratedAt: string
}

export interface CatalogHydrationRecord {
  recordKey: string
  sha256: string
  record: CatalogRecord
}

export type CatalogHydrationRootResult =
  | (CatalogHydrationRootBase & { status: 'unchanged'; graphHash: string })
  | (CatalogHydrationRootBase & { status: 'not-found' })
  | (CatalogHydrationRootBase & {
      status: 'resolved'
      graphHash: string
      recordKeys: string[]
      records: CatalogHydrationRecord[]
    })
  | (CatalogHydrationRootBase & {
      status: 'error'
      error: { code: string; message: string }
    })

export interface CatalogHydrationApplyResult {
  counts: CatalogCounts
  recordsChanged: number
  rootsChecked: number
  updated: boolean
}

export type CatalogSyncState = 'empty' | 'ready' | 'syncing' | 'failed' | 'cancelled'

export interface CatalogProgress {
  processed: number
  total: number
  updated: number
  failed: number
}

export interface CatalogSafeError {
  code:
    | 'CATALOG_UNAVAILABLE'
    | 'CATALOG_SYNC_FAILED'
    | 'CATALOG_SYNC_CANCELLED'
    | 'CATALOG_RESPONSE_INVALID'
    | 'CATALOG_STORAGE_FAILED'
  message: string
  retryable: boolean
}

export interface CatalogStatus {
  available: boolean
  state: CatalogSyncState
  lastSyncedAt: string | null
  progress: CatalogProgress | null
  counts: CatalogCounts
  error: CatalogSafeError | null
}

export type CatalogSearchResultKind = 'offer' | 'orphan-item'

export interface CatalogSearchRequest {
  query: string
  page?: number
  pageSize?: number
  offerType?: string
  platform?: string
  resultKind?: 'all' | 'offers' | 'orphan-items'
}

export interface CatalogSearchResult {
  kind: CatalogSearchResultKind
  namespace: string
  id: string
  title: string
  description: string
  offerType: string | null
  developer: string | null
  publisher: string | null
  imageUrl: string | null
  platforms: string[]
  itemCount: number
  matchedIdentifiers: string[]
}

export interface CatalogSearchPage {
  items: CatalogSearchResult[]
  total: number
  page: number
  pageSize: number
  hasMore: boolean
}

export interface CatalogDetailsRequest {
  kind: CatalogSearchResultKind | 'item'
  namespace: string
  id: string
}

export interface CatalogImage {
  type: string
  url: string
}

export interface CatalogDetails {
  kind: CatalogSearchResultKind
  namespace: string
  id: string
  title: string
  description: string
  longDescription: string
  offer: CatalogOfferRecord | null
  items: CatalogItemRecord[]
  offers: CatalogOfferRecord[]
  assets: CatalogAssetRecord[]
  releaseApps: CatalogReleaseAppRecord[]
  platforms: string[]
  images: CatalogImage[]
}

export type CatalogTaxonomyGroup = 'genre' | 'feature' | 'epicfeature' | 'platform' | 'subscription'

export interface CatalogTaxonomyTag {
  id: string
  name: string
  groupName: CatalogTaxonomyGroup
  status: string
}

export interface CatalogTaxonomySnapshot {
  tags: CatalogTaxonomyTag[]
  updatedAt: string | null
}

export interface CatalogLibraryMetadata {
  namespace: string
  catalogItemId: string
  offerId: string | null
  title: string
  description: string
  longDescription: string
  developer: string | null
  publisher: string | null
  offerType: string | null
  artworkUrl: string | null
  platforms: string[]
  tagIds: string[]
  identifiers: string[]
  releaseDate: string | null
  lastModified: string | null
  kind: CatalogLauncherRecordKind
  mainGame: CatalogLauncherIdentity | null
}

export interface CatalogNameResolutionInput {
  namespace?: string
  catalogItemId?: string
  artifactId?: string
  appName?: string
  platform?: string
}

export interface CatalogNameResolution {
  displayName: string
  namespace: string
  catalogItemId: string
  itemTitle: string | null
  offerNamespace: string | null
  offerId: string | null
  offerTitle: string | null
}

export interface CatalogLauncherHint {
  artifactId?: string
  catalogItemId?: string
  catalogNamespace?: string
}

export interface CatalogLauncherCandidateInput {
  buildAppName: string
  platform: string
  catalogHint?: CatalogLauncherHint
}

export type CatalogLauncherRecordKind = 'base-game' | 'addon' | 'digital-extra'

export interface CatalogLauncherIdentity {
  artifactId: string
  catalogItemId: string
  catalogNamespace: string
}

export interface CatalogLauncherResolution extends CatalogLauncherIdentity {
  displayName: string
  kind: CatalogLauncherRecordKind
  appCategories: string[]
  mainGame: CatalogLauncherIdentity | null
  mandatoryAppFolderName: string
  canRunOffline: boolean
  requiresAuth: boolean
  ownershipToken: boolean
  ignoredProcessNames: string[]
}

export type CatalogInterestScopeKind =
  | 'local-default'
  | 'local-selected'
  | 'cloud-account'
  | 'library-tools'
