import { z } from 'zod'

const idSchema = z.string().trim().min(1).max(256)
const safeTextSchema = z.string().max(2_000)
const timestampSchema = z.string().datetime({ offset: true })

export const PlatformSchema = z.enum(['windows', 'macos'])
export type Platform = z.infer<typeof PlatformSchema>

export const ErrorCodeSchema = z.enum([
  'LOCAL_MANIFEST_DIRECTORY_MISSING',
  'LOCAL_ITEM_PERMISSION_DENIED',
  'LOCAL_ITEM_INVALID_JSON',
  'LOCAL_BINARY_MANIFEST_MISSING',
  'EPIC_NOT_AUTHENTICATED',
  'EPIC_LOGIN_CANCELLED',
  'EPIC_SESSION_EXPIRED',
  'EPIC_LIBRARY_REQUEST_FAILED',
  'EPIC_MANIFEST_UNAVAILABLE',
  'EPIC_MANIFEST_DOWNLOAD_FAILED',
  'UPLOAD_TIMEOUT',
  'UPLOAD_REJECTED',
  'UPLOAD_RESPONSE_INVALID',
  'SYNC_CANCELLED',
  'CATALOG_UNAVAILABLE',
  'CATALOG_SYNC_FAILED',
  'CATALOG_SYNC_CANCELLED',
  'CATALOG_RESPONSE_INVALID',
  'CATALOG_STORAGE_FAILED',
  'VALIDATION_FAILED',
  'INTERNAL_ERROR',
])
export type ErrorCode = z.infer<typeof ErrorCodeSchema>

export const SafeErrorSchema = z.object({
  code: ErrorCodeSchema,
  message: safeTextSchema,
  retryable: z.boolean().default(false),
  detail: safeTextSchema.optional(),
})
export type SafeError = z.infer<typeof SafeErrorSchema>

export const WindowBoundsSchema = z.object({
  x: z.number().int(),
  y: z.number().int(),
  width: z.number().int().min(640).max(10_000),
  height: z.number().int().min(480).max(10_000),
})
export type WindowBounds = z.infer<typeof WindowBoundsSchema>

export const AutomaticUploadIntervalMinutesSchema = z.union([
  z.literal(60),
  z.literal(180),
  z.literal(360),
  z.literal(720),
  z.literal(1_440),
  z.literal(4_320),
  z.literal(10_080),
])
export type AutomaticUploadIntervalMinutes = z.infer<typeof AutomaticUploadIntervalMinutesSchema>

export const UpdateChannelSchema = z.enum(['stable', 'beta'])
export type UpdateChannel = z.infer<typeof UpdateChannelSchema>

export const StoredSettingsSchema = z.object({
  contributionConsent: z.boolean(),
  automaticUploadsEnabled: z.boolean(),
  automaticLocalUploadIntervalMinutes: AutomaticUploadIntervalMinutesSchema,
  automaticCloudUploadIntervalMinutes: AutomaticUploadIntervalMinutesSchema,
  includePathsInDiagnostics: z.boolean(),
  updateChannel: UpdateChannelSchema,
  automaticallyCheckForUpdates: z.boolean(),
  automaticallyScanWindowsDrives: z.boolean(),
  launchAtStartup: z.boolean(),
})
export type StoredSettings = z.infer<typeof StoredSettingsSchema>

export const PublicSettingsSchema = StoredSettingsSchema.extend({
  launchAtStartupAvailable: z.boolean(),
})
export type PublicSettings = z.infer<typeof PublicSettingsSchema>

export const SettingsUpdateSchema = StoredSettingsSchema.partial().refine(
  (value) => Object.keys(value).length > 0,
  'At least one setting is required',
)
export type SettingsUpdate = z.infer<typeof SettingsUpdateSchema>

export const SettingsDocumentSchema = z.object({
  version: z.literal(4),
  window: z.object({
    bounds: WindowBoundsSchema.optional(),
    maximized: z.boolean(),
  }),
  preferences: StoredSettingsSchema,
})
export type SettingsDocument = z.infer<typeof SettingsDocumentSchema>

export const LocalScanRequestSchema = z.object({
  source: z.enum(['default', 'selected']),
})
export type LocalScanRequest = z.infer<typeof LocalScanRequestSchema>

export const LocalManifestIssueSchema = z.object({
  id: idSchema,
  sourceFilename: z.string().max(512),
  error: SafeErrorSchema,
})
export type LocalManifestIssue = z.infer<typeof LocalManifestIssueSchema>

export const LocalManifestSchema = z.object({
  id: idSchema,
  appName: z.string().max(512),
  displayName: z.string().max(512),
  catalogItemId: z.string().max(256),
  namespace: z.string().max(256),
  sourceFilename: z.string().max(512),
  platform: PlatformSchema,
  kind: z.enum(['base-game', 'addon', 'unknown']),
  binaryManifestAvailable: z.boolean(),
  groupId: idSchema,
})
export type LocalManifest = z.infer<typeof LocalManifestSchema>

export const LocalScanSnapshotSchema = z.object({
  state: z.enum(['idle', 'scanning', 'complete', 'failed', 'cancelled']),
  scannedAt: timestampSchema.optional(),
  manifests: z.array(LocalManifestSchema).max(20_000),
  issues: z.array(LocalManifestIssueSchema).max(20_000),
  error: SafeErrorSchema.optional(),
})
export type LocalScanSnapshot = z.infer<typeof LocalScanSnapshotSchema>

export const DirectorySelectionSchema = z.object({
  cancelled: z.boolean(),
  displayPath: z.string().max(1_024).optional(),
})
export type DirectorySelection = z.infer<typeof DirectorySelectionSchema>

export const UploadResultStateSchema = z.enum([
  'pending',
  'uploading',
  'uploaded',
  'already-uploaded',
  'failed',
  'cancelled',
])
export type UploadResultState = z.infer<typeof UploadResultStateSchema>

export const LocalUploadRequestSchema = z.object({
  manifestIds: z
    .array(idSchema)
    .min(1)
    .max(20_000)
    .refine((ids) => new Set(ids).size === ids.length, 'Manifest IDs must be unique'),
})
export type LocalUploadRequest = z.infer<typeof LocalUploadRequestSchema>

export const LocalUploadItemSchema = z.object({
  manifestId: idSchema,
  state: UploadResultStateSchema,
  error: SafeErrorSchema.optional(),
})

export const LocalUploadSnapshotSchema = z.object({
  operationId: idSchema,
  state: z.enum(['running', 'complete', 'cancelled']),
  completed: z.number().int().nonnegative(),
  total: z.number().int().nonnegative(),
  items: z.array(LocalUploadItemSchema).max(20_000),
})
export type LocalUploadSnapshot = z.infer<typeof LocalUploadSnapshotSchema>

export const OperationIdSchema = z.object({ operationId: idSchema })
export type OperationId = z.infer<typeof OperationIdSchema>

export const LocalScanEventSchema = z.discriminatedUnion('type', [
  z.object({ type: z.literal('started') }),
  z.object({
    type: z.literal('progress'),
    discovered: z.number().int().nonnegative(),
    issues: z.number().int().nonnegative(),
  }),
  z.object({ type: z.literal('finished'), snapshot: LocalScanSnapshotSchema }),
])
export type LocalScanEvent = z.infer<typeof LocalScanEventSchema>

export const LibraryGameSchema = z.object({
  id: idSchema,
  displayName: z.string().max(512),
  appName: z.string().max(256),
  installLocation: z.string().max(4_096),
  installSize: z.number().nonnegative(),
  recordCount: z.number().int().positive(),
  movable: z.boolean(),
  issue: safeTextSchema.optional(),
})
export type LibraryGame = z.infer<typeof LibraryGameSchema>

export const RecoveryCandidateSchema = z.object({
  id: idSchema,
  displayName: z.string().max(512),
  installLocation: z.string().max(4_096),
  version: z.string().max(512),
  recordCount: z.number().int().positive(),
  kinds: z.array(z.enum(['base-game', 'addon', 'digital-extra'])).max(100),
  status: z.enum(['resolved', 'not-found', 'ambiguous', 'unsupported', 'conflict']),
  recoverable: z.boolean(),
  issue: safeTextSchema.optional(),
})
export type RecoveryCandidate = z.infer<typeof RecoveryCandidateSchema>

export const MoveSnapshotSchema = z.object({
  operationId: idSchema,
  gameId: idSchema,
  displayName: z.string().max(512),
  state: z.enum([
    'prepared',
    'copying',
    'updating-launcher',
    'deleting-source',
    'complete',
    'cancelled',
    'failed',
  ]),
  sourceLocation: z.string().max(4_096),
  destinationLocation: z.string().max(4_096),
  copiedBytes: z.number().nonnegative(),
  totalBytes: z.number().nonnegative(),
  copiedFiles: z.number().int().nonnegative(),
  totalFiles: z.number().int().nonnegative(),
  restartLauncher: z.boolean(),
  warning: safeTextSchema.optional(),
  error: SafeErrorSchema.optional(),
})
export type MoveSnapshot = z.infer<typeof MoveSnapshotSchema>

export const LibraryToolsSnapshotSchema = z.object({
  available: z.boolean(),
  state: z.enum(['idle', 'scanning', 'recovering']),
  scannedAt: timestampSchema.optional(),
  registeredGames: z.array(LibraryGameSchema).max(20_000),
  candidates: z.array(RecoveryCandidateSchema).max(20_000),
  issues: z.array(safeTextSchema).max(1_000),
  scanProgress: z
    .object({
      phase: z.enum(['discovering', 'parsing', 'resolving']),
      drivesCompleted: z.number().int().nonnegative(),
      totalDrives: z.number().int().nonnegative(),
      directoriesChecked: z.number().int().nonnegative(),
      manifestDirectories: z.number().int().nonnegative(),
      manifestsParsed: z.number().int().nonnegative(),
      currentDrive: z.string().max(16).optional(),
    })
    .optional(),
  move: MoveSnapshotSchema.optional(),
})
export type LibraryToolsSnapshot = z.infer<typeof LibraryToolsSnapshotSchema>

export const LauncherStatusSchema = z.object({ running: z.boolean() })
export type LauncherStatus = z.infer<typeof LauncherStatusSchema>

export const LibrarySelectionSchema = z.object({
  candidateIds: z
    .array(idSchema)
    .min(1)
    .max(100)
    .refine((ids) => new Set(ids).size === ids.length, 'Candidate IDs must be unique'),
})
export type LibrarySelection = z.infer<typeof LibrarySelectionSchema>

export const GameSelectionSchema = z.object({ gameId: idSchema })
export type GameSelection = z.infer<typeof GameSelectionSchema>

export const MovePreparationSchema = z.object({
  cancelled: z.boolean(),
  move: MoveSnapshotSchema.optional(),
})
export type MovePreparation = z.infer<typeof MovePreparationSchema>

export const LibraryToolsEventSchema = z.object({
  snapshot: LibraryToolsSnapshotSchema,
})
export type LibraryToolsEvent = z.infer<typeof LibraryToolsEventSchema>

export const AuthStatusSchema = z.object({
  state: z.enum(['signed-out', 'signing-in', 'signed-in', 'expired']),
  accountId: z.string().max(256).optional(),
  displayName: z.string().max(256).optional(),
  expiresAt: timestampSchema.optional(),
})
export type AuthStatus = z.infer<typeof AuthStatusSchema>

export const QueueItemStateSchema = z.enum([
  'pending',
  'running',
  'uploaded',
  'already-uploaded',
  'failed',
  'skipped',
  'cancelled',
  'removed',
])
export type QueueItemState = z.infer<typeof QueueItemStateSchema>

export const CloudQueueItemSchema = z.object({
  id: idSchema,
  appName: z.string().max(512),
  displayName: z.string().max(512),
  catalogItemId: z.string().max(256),
  namespace: z.string().max(256),
  state: QueueItemStateSchema,
  attempts: z.number().int().nonnegative(),
  startedAt: timestampSchema.optional(),
  finishedAt: timestampSchema.optional(),
  durationMs: z.number().int().nonnegative().optional(),
  error: SafeErrorSchema.optional(),
})
export type CloudQueueItem = z.infer<typeof CloudQueueItemSchema>

export const QueueCountsSchema = z.object({
  pending: z.number().int().nonnegative(),
  running: z.number().int().nonnegative(),
  uploaded: z.number().int().nonnegative(),
  alreadyUploaded: z.number().int().nonnegative(),
  failed: z.number().int().nonnegative(),
  skipped: z.number().int().nonnegative(),
  cancelled: z.number().int().nonnegative(),
})

export const CloudQueueSnapshotSchema = z.object({
  state: z.enum(['idle', 'running', 'paused', 'cancelling', 'complete']),
  startedAt: timestampSchema.optional(),
  elapsedMs: z.number().int().nonnegative(),
  counts: QueueCountsSchema,
  items: z.array(CloudQueueItemSchema).max(50_000),
})
export type CloudQueueSnapshot = z.infer<typeof CloudQueueSnapshotSchema>

export const CloudQueueStartSchema = z.object({
  itemIds: z.array(idSchema).max(50_000).optional(),
})
export type CloudQueueStart = z.infer<typeof CloudQueueStartSchema>

export const QueueSelectionSchema = z.object({
  itemIds: z.array(idSchema).min(1).max(50_000),
})
export type QueueSelection = z.infer<typeof QueueSelectionSchema>

export const CloudQueueEventSchema = z.discriminatedUnion('type', [
  z.object({ type: z.literal('snapshot'), snapshot: CloudQueueSnapshotSchema }),
  z.object({ type: z.literal('item-updated'), item: CloudQueueItemSchema }),
  z.object({
    type: z.literal('state-changed'),
    state: CloudQueueSnapshotSchema.shape.state,
  }),
])
export type CloudQueueEvent = z.infer<typeof CloudQueueEventSchema>

export const LibraryInstalledFilterSchema = z.enum(['all', 'installed', 'not-installed'])
export type LibraryInstalledFilter = z.infer<typeof LibraryInstalledFilterSchema>

export const LibrarySortFieldSchema = z.enum(['title', 'releaseDate', 'lastModified'])
export type LibrarySortField = z.infer<typeof LibrarySortFieldSchema>

export const LibrarySortDirectionSchema = z.enum(['asc', 'desc'])
export type LibrarySortDirection = z.infer<typeof LibrarySortDirectionSchema>

const libraryFacetSelectionSchema = z.array(idSchema).max(100)

export const LibraryQueryRequestSchema = z.object({
  text: z.string().trim().max(512),
  page: z.number().int().min(1).max(1_000_000),
  pageSize: z.number().int().min(1).max(100),
  installed: LibraryInstalledFilterSchema,
  genreIds: libraryFacetSelectionSchema,
  featureIds: libraryFacetSelectionSchema,
  typeIds: libraryFacetSelectionSchema,
  platformIds: libraryFacetSelectionSchema,
  subscriptionIds: libraryFacetSelectionSchema,
  sortField: LibrarySortFieldSchema,
  sortDirection: LibrarySortDirectionSchema,
})
export type LibraryQueryRequest = z.infer<typeof LibraryQueryRequestSchema>

export const LibraryFacetOptionSchema = z.object({
  id: idSchema,
  label: z.string().trim().min(1).max(256),
  count: z.number().int().nonnegative(),
})
export type LibraryFacetOption = z.infer<typeof LibraryFacetOptionSchema>

export const LibraryFacetsSchema = z.object({
  genres: z.array(LibraryFacetOptionSchema).max(1_000),
  features: z.array(LibraryFacetOptionSchema).max(1_000),
  types: z.array(LibraryFacetOptionSchema).max(500),
  platforms: z.array(LibraryFacetOptionSchema).max(500),
  subscriptions: z.array(LibraryFacetOptionSchema).max(1_000),
})
export type LibraryFacets = z.infer<typeof LibraryFacetsSchema>

export const LibraryCardSchema = z.object({
  id: idSchema,
  title: z.string().max(512),
  appName: z.string().max(512),
  artworkUrl: z.string().url().max(4_096).nullable(),
  developer: z.string().max(512).nullable(),
  publisher: z.string().max(512).nullable(),
  type: z.string().max(128).nullable(),
  platforms: z.array(z.string().trim().min(1).max(64)).max(64),
  installed: z.boolean(),
  epicOwned: z.boolean(),
  addOnCount: z.number().int().nonnegative(),
  releaseDate: timestampSchema.nullable(),
  lastModified: timestampSchema.nullable(),
  metadataAvailable: z.boolean(),
})
export type LibraryCard = z.infer<typeof LibraryCardSchema>

export const LibraryStatusSchema = z.object({
  state: z.enum(['empty', 'ready', 'refreshing']),
  total: z.number().int().nonnegative(),
  owned: z.number().int().nonnegative(),
  installed: z.number().int().nonnegative(),
  partialMetadata: z.number().int().nonnegative(),
  signedIn: z.boolean(),
  localScanState: LocalScanSnapshotSchema.shape.state,
  lastRefreshedAt: timestampSchema.nullable(),
  taxonomyUpdatedAt: timestampSchema.nullable(),
  warnings: z.array(safeTextSchema).max(20),
})
export type LibraryStatus = z.infer<typeof LibraryStatusSchema>

export const LibraryPageSchema = z.object({
  items: z.array(LibraryCardSchema).max(100),
  total: z.number().int().nonnegative(),
  page: z.number().int().min(1).max(1_000_000),
  pageSize: z.number().int().min(1).max(100),
  hasMore: z.boolean(),
  facets: LibraryFacetsSchema,
  status: LibraryStatusSchema,
})
export type LibraryPage = z.infer<typeof LibraryPageSchema>

export const LibraryDetailsRequestSchema = z.object({ id: idSchema })
export type LibraryDetailsRequest = z.infer<typeof LibraryDetailsRequestSchema>

export const LibraryAddOnSchema = z.object({
  id: idSchema,
  title: z.string().max(512),
  installed: z.boolean(),
  epicOwned: z.boolean(),
  type: z.string().max(128).nullable(),
})
export type LibraryAddOn = z.infer<typeof LibraryAddOnSchema>

export const LibraryDetailsSchema = LibraryCardSchema.extend({
  description: z.string().max(65_536),
  longDescription: z.string().max(65_536),
  genres: z.array(z.string().max(256)).max(1_000),
  features: z.array(z.string().max(256)).max(1_000),
  subscriptions: z.array(z.string().max(256)).max(1_000),
  identifiers: z.array(z.string().max(1_024)).max(500),
  addOns: z.array(LibraryAddOnSchema).max(1_000),
})
export type LibraryDetails = z.infer<typeof LibraryDetailsSchema>

export const LibraryRefreshResultSchema = z.object({
  status: LibraryStatusSchema,
  warnings: z.array(safeTextSchema).max(20),
})
export type LibraryRefreshResult = z.infer<typeof LibraryRefreshResultSchema>

export const LibraryChangedEventSchema = z.object({ status: LibraryStatusSchema })
export type LibraryChangedEvent = z.infer<typeof LibraryChangedEventSchema>

const catalogTitleSchema = z.string().max(512)
const catalogProseSchema = z.string().max(65_536)
const catalogUrlSchema = z.string().url().max(4_096)
const catalogPlatformSchema = z.string().trim().min(1).max(64)

export type CatalogJsonValue =
  | string
  | number
  | boolean
  | null
  | CatalogJsonValue[]
  | { [key: string]: CatalogJsonValue }

export const CatalogJsonValueSchema: z.ZodType<CatalogJsonValue> = z.lazy(() =>
  z.union([
    catalogProseSchema,
    z.number().finite(),
    z.boolean(),
    z.null(),
    z.array(CatalogJsonValueSchema).max(1_000),
    z
      .record(z.string().max(256), CatalogJsonValueSchema)
      .refine((value) => Object.keys(value).length <= 1_000, 'Too many catalog object keys'),
  ]),
)

export const CatalogJsonObjectSchema = z
  .record(z.string().max(256), CatalogJsonValueSchema)
  .refine((value) => Object.keys(value).length <= 1_000, 'Too many catalog object keys')
export type CatalogJsonObject = z.infer<typeof CatalogJsonObjectSchema>

export const CatalogResultKindSchema = z.enum(['offer', 'orphan-item'])
export type CatalogResultKind = z.infer<typeof CatalogResultKindSchema>

export const CatalogDetailsKindSchema = z.enum(['offer', 'orphan-item', 'item'])
export type CatalogDetailsKind = z.infer<typeof CatalogDetailsKindSchema>

export const CatalogResultFilterSchema = z.enum(['all', 'offers', 'orphan-items'])
export type CatalogResultFilter = z.infer<typeof CatalogResultFilterSchema>

export const CatalogCountsSchema = z.object({
  offers: z.number().int().nonnegative(),
  items: z.number().int().nonnegative(),
  assets: z.number().int().nonnegative(),
  releaseApps: z.number().int().nonnegative(),
  offerItems: z.number().int().nonnegative(),
})
export type CatalogCounts = z.infer<typeof CatalogCountsSchema>

export const CatalogSyncProgressSchema = z
  .object({
    processed: z.number().int().nonnegative(),
    total: z.number().int().nonnegative(),
    updated: z.number().int().nonnegative(),
    failed: z.number().int().nonnegative(),
  })
  .refine((value) => value.processed <= value.total, 'Catalog root progress is invalid')
  .refine(
    (value) => value.updated + value.failed <= value.processed,
    'Catalog root outcomes are invalid',
  )
export type CatalogSyncProgress = z.infer<typeof CatalogSyncProgressSchema>

export const CatalogStatusSchema = z.object({
  state: z.enum(['empty', 'ready', 'syncing', 'failed', 'cancelled']),
  available: z.boolean(),
  lastSyncedAt: timestampSchema.nullable(),
  progress: CatalogSyncProgressSchema.nullable(),
  counts: CatalogCountsSchema,
  error: SafeErrorSchema.nullable(),
})
export type CatalogStatus = z.infer<typeof CatalogStatusSchema>

export const CatalogSearchRequestSchema = z.object({
  query: z.string().trim().max(512),
  page: z.number().int().min(1).max(1_000_000),
  pageSize: z.number().int().min(1).max(100),
  offerType: z.string().trim().min(1).max(128).optional(),
  platform: catalogPlatformSchema.optional(),
  resultKind: CatalogResultFilterSchema,
})
export type CatalogSearchRequest = z.infer<typeof CatalogSearchRequestSchema>

export const CatalogSearchItemSchema = z.object({
  kind: CatalogResultKindSchema,
  namespace: idSchema,
  id: idSchema,
  title: catalogTitleSchema,
  description: catalogProseSchema,
  offerType: z.string().max(128).nullable(),
  developer: catalogTitleSchema.nullable(),
  publisher: catalogTitleSchema.nullable(),
  imageUrl: catalogUrlSchema.nullable(),
  platforms: z.array(catalogPlatformSchema).max(64),
  itemCount: z.number().int().nonnegative(),
  matchedIdentifiers: z.array(z.string().max(1_024)).max(500),
})
export type CatalogSearchItem = z.infer<typeof CatalogSearchItemSchema>

export const CatalogSearchResponseSchema = z.object({
  items: z.array(CatalogSearchItemSchema).max(100),
  total: z.number().int().nonnegative(),
  page: z.number().int().min(1).max(1_000_000),
  pageSize: z.number().int().min(1).max(100),
  hasMore: z.boolean(),
})
export type CatalogSearchResponse = z.infer<typeof CatalogSearchResponseSchema>

export const CatalogDetailsRequestSchema = z.object({
  kind: CatalogDetailsKindSchema,
  namespace: idSchema,
  id: idSchema,
})
export type CatalogDetailsRequest = z.infer<typeof CatalogDetailsRequestSchema>

export const CatalogAssetSchema = z.object({
  type: z.literal('asset'),
  namespace: idSchema,
  artifactId: idSchema,
  itemNamespace: idSchema,
  platform: catalogPlatformSchema,
  itemId: idSchema,
  downloadSizeBytes: z.number().int().nonnegative().optional(),
  installedSizeBytes: z.number().int().nonnegative().optional(),
  primaryOfferNamespace: idSchema.optional(),
  primaryOfferId: idSchema.optional(),
})
export type CatalogAsset = z.infer<typeof CatalogAssetSchema>

export const CatalogReleaseAppSchema = z.object({
  type: z.literal('release-app'),
  namespace: idSchema,
  appId: idSchema,
  itemNamespace: idSchema,
  platform: catalogPlatformSchema,
  itemId: idSchema,
  releaseId: idSchema.optional(),
  primaryOfferNamespace: idSchema.optional(),
  primaryOfferId: idSchema.optional(),
})
export type CatalogReleaseApp = z.infer<typeof CatalogReleaseAppSchema>

export const CatalogImageSchema = z.object({
  type: z.string().max(128),
  url: catalogUrlSchema,
})
export type CatalogImage = z.infer<typeof CatalogImageSchema>

export const CatalogManifestMatchSchema = z.object({
  source: z.enum(['local', 'cloud']),
  id: idSchema,
  displayName: catalogTitleSchema,
  appName: z.string().max(512),
  platform: catalogPlatformSchema,
})
export type CatalogManifestMatch = z.infer<typeof CatalogManifestMatchSchema>

export const CatalogDetailsSchema = z.object({
  kind: CatalogResultKindSchema,
  namespace: idSchema,
  id: idSchema,
  title: catalogTitleSchema,
  description: catalogProseSchema,
  longDescription: catalogProseSchema,
  offer: CatalogJsonObjectSchema.nullable(),
  items: z.array(CatalogJsonObjectSchema).max(500),
  offers: z.array(CatalogJsonObjectSchema).max(500),
  assets: z.array(CatalogAssetSchema).max(500),
  releaseApps: z.array(CatalogReleaseAppSchema).max(500),
  platforms: z.array(catalogPlatformSchema).max(64),
  images: z.array(CatalogImageSchema).max(100),
  matchingManifests: z.array(CatalogManifestMatchSchema).max(20_000).optional(),
})
export type CatalogDetails = z.infer<typeof CatalogDetailsSchema>

export const DiagnosticLevelSchema = z.enum(['debug', 'info', 'warn', 'error'])
export const DiagnosticEntrySchema = z.object({
  timestamp: timestampSchema,
  level: DiagnosticLevelSchema,
  scope: z.string().max(128),
  message: safeTextSchema,
  context: z.record(z.string(), z.unknown()).optional(),
})
export type DiagnosticEntry = z.infer<typeof DiagnosticEntrySchema>

export const DiagnosticsSnapshotSchema = z.object({
  logDirectory: z.string().max(1_024),
  fileCount: z.number().int().nonnegative(),
  totalBytes: z.number().int().nonnegative(),
  recentEntries: z.array(DiagnosticEntrySchema).max(500),
  logger: z.object({
    pendingEntries: z.number().int().nonnegative(),
    droppedEntries: z.number().int().nonnegative(),
    writeFailures: z.number().int().nonnegative(),
    lastWriteError: safeTextSchema.nullable(),
  }),
})
export type DiagnosticsSnapshot = z.infer<typeof DiagnosticsSnapshotSchema>

export const DiagnosticExportRequestSchema = z.object({
  includePaths: z.boolean().default(false),
})
export type DiagnosticExportRequest = z.infer<typeof DiagnosticExportRequestSchema>

export const DiagnosticExportResultSchema = z.object({
  cancelled: z.boolean(),
  filePath: z.string().max(1_024).optional(),
})
export type DiagnosticExportResult = z.infer<typeof DiagnosticExportResultSchema>

export const UpdateStatusSchema = z.object({
  state: z.enum([
    'idle',
    'checking',
    'available',
    'not-available',
    'downloading',
    'downloaded',
    'installing',
    'error',
  ]),
  currentVersion: z.string().max(64),
  channel: UpdateChannelSchema,
  delivery: z.enum(['managed', 'manual', 'store']),
  availableVersion: z.string().max(64).optional(),
  progressPercent: z.number().min(0).max(100).optional(),
  releaseNotesUrl: z.string().url().optional(),
  message: safeTextSchema.optional(),
  error: SafeErrorSchema.optional(),
})
export type UpdateStatus = z.infer<typeof UpdateStatusSchema>

export const UpdateInstallRequestSchema = z.object({
  cancelActiveWork: z.boolean(),
})
export type UpdateInstallRequest = z.infer<typeof UpdateInstallRequestSchema>

export const UpdateInstallResultSchema = z.object({
  outcome: z.enum(['started', 'confirmation-required']),
})
export type UpdateInstallResult = z.infer<typeof UpdateInstallResultSchema>

export const AboutInfoSchema = z.object({
  productName: z.literal('egdata.app'),
  version: z.string().max(64),
  platform: PlatformSchema,
  architecture: z.string().max(64),
  electronVersion: z.string().max(64),
  licensesUrl: z.string().url(),
  privacyUrl: z.string().url(),
  websiteUrl: z.string().url(),
})
export type AboutInfo = z.infer<typeof AboutInfoSchema>

export const EmptyResultSchema = z.object({ ok: z.literal(true) })
export type EmptyResult = z.infer<typeof EmptyResultSchema>
