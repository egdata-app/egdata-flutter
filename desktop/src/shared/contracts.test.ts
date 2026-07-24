import { describe, expect, it } from 'vitest'

import {
  CloudQueueEventSchema,
  CatalogDetailsSchema,
  CatalogSearchRequestSchema,
  CatalogStatusSchema,
  LocalUploadRequestSchema,
  LibraryDetailsSchema,
  LibraryPageSchema,
  LibraryQueryRequestSchema,
  SettingsUpdateSchema,
  UpdateInstallRequestSchema,
  UpdateStatusSchema,
} from './contracts'

describe('shared contracts', () => {
  it('rejects empty and duplicate upload selections at the boundary', () => {
    expect(LocalUploadRequestSchema.safeParse({ manifestIds: [] }).success).toBe(false)
    expect(
      LocalUploadRequestSchema.safeParse({ manifestIds: ['manifest-1', 'manifest-1'] }).success,
    ).toBe(false)
    expect(LocalUploadRequestSchema.safeParse({ manifestIds: ['manifest-1'] }).success).toBe(true)
  })

  it('requires a non-empty settings patch', () => {
    expect(SettingsUpdateSchema.safeParse({}).success).toBe(false)
    expect(SettingsUpdateSchema.safeParse({ updateChannel: 'stable' }).success).toBe(true)
    expect(SettingsUpdateSchema.safeParse({ launchAtStartup: true }).success).toBe(true)
    expect(
      SettingsUpdateSchema.safeParse({ automaticLocalUploadIntervalMinutes: 360 }).success,
    ).toBe(true)
    expect(
      SettingsUpdateSchema.safeParse({ automaticCloudUploadIntervalMinutes: 15 }).success,
    ).toBe(false)
    expect(SettingsUpdateSchema.safeParse({ launchAtStartupAvailable: true }).success).toBe(false)
  })

  it('validates queue events by discriminator', () => {
    expect(
      CloudQueueEventSchema.safeParse({ type: 'state-changed', state: 'paused' }).success,
    ).toBe(true)
    expect(
      CloudQueueEventSchema.safeParse({ type: 'state-changed', state: 'unknown' }).success,
    ).toBe(false)
  })

  it('rejects unsafe update links', () => {
    const result = UpdateStatusSchema.safeParse({
      state: 'available',
      currentVersion: '1.3.0',
      channel: 'stable',
      delivery: 'managed',
      releaseNotesUrl: 'not a URL',
    })
    expect(result.success).toBe(false)
  })

  it('requires an explicit manifest-work cancellation choice for update installation', () => {
    expect(UpdateInstallRequestSchema.safeParse({ cancelActiveWork: false }).success).toBe(true)
    expect(UpdateInstallRequestSchema.safeParse({}).success).toBe(false)
  })
  it('bounds catalog search pagination and filters', () => {
    const request = {
      query: 'fortnite',
      page: 1,
      pageSize: 100,
      resultKind: 'offers',
      platform: 'Windows',
    }
    expect(CatalogSearchRequestSchema.safeParse(request).success).toBe(true)
    expect(CatalogSearchRequestSchema.safeParse({ ...request, pageSize: 101 }).success).toBe(false)
    expect(CatalogSearchRequestSchema.safeParse({ ...request, resultKind: 'items' }).success).toBe(
      false,
    )
  })

  it('rejects inconsistent catalog sync progress', () => {
    const status = {
      state: 'syncing',
      available: false,
      lastSyncedAt: null,
      progress: {
        processed: 2,
        total: 1,
        updated: 1,
        failed: 0,
      },
      counts: { offers: 0, items: 0, assets: 0, releaseApps: 0, offerItems: 0 },
      error: null,
    }
    expect(CatalogStatusSchema.safeParse(status).success).toBe(false)
    expect(
      CatalogStatusSchema.safeParse({
        ...status,
        progress: { processed: 1, total: 1, updated: 1, failed: 0 },
      }).success,
    ).toBe(true)
  })

  it('validates composite asset and release-app ownership in details', () => {
    const details = {
      kind: 'offer',
      namespace: 'catalog-namespace',
      id: 'offer-id',
      title: 'Example game',
      description: '',
      longDescription: '',
      offer: { id: 'offer-id' },
      items: [{ id: 'item-id' }],
      offers: [],
      assets: [
        {
          type: 'asset',
          namespace: 'artifact-namespace',
          artifactId: 'artifact-id',
          itemNamespace: 'catalog-namespace',
          itemId: 'item-id',
          platform: 'Windows',
        },
      ],
      releaseApps: [
        {
          type: 'release-app',
          namespace: 'catalog-namespace',
          appId: 'app-name',
          itemNamespace: 'catalog-namespace',
          itemId: 'item-id',
          platform: 'Windows',
        },
      ],
      platforms: ['Windows'],
      images: [{ type: 'DieselStoreFrontWide', url: 'https://cdn.example.test/image.jpg' }],
    }
    expect(CatalogDetailsSchema.safeParse(details).success).toBe(true)
    expect(
      CatalogDetailsSchema.safeParse({
        ...details,
        assets: [{ ...details.assets[0], itemNamespace: undefined }],
      }).success,
    ).toBe(false)
    expect(
      CatalogDetailsSchema.safeParse({
        ...details,
        offer: { unsafe: () => 'not JSON' },
      }).success,
    ).toBe(false)
  })

  it('bounds Library requests and rejects unsupported sort fields', () => {
    const request = {
      text: 'fortnite',
      page: 1,
      pageSize: 48,
      installed: 'all',
      genreIds: [],
      featureIds: [],
      typeIds: [],
      platformIds: [],
      subscriptionIds: [],
      sortField: 'title',
      sortDirection: 'asc',
    }
    expect(LibraryQueryRequestSchema.safeParse(request).success).toBe(true)
    expect(LibraryQueryRequestSchema.safeParse({ ...request, pageSize: 101 }).success).toBe(false)
    expect(
      LibraryQueryRequestSchema.safeParse({ ...request, sortField: 'purchased' }).success,
    ).toBe(false)
    expect(
      LibraryQueryRequestSchema.safeParse({ ...request, genreIds: Array(101).fill('genre') })
        .success,
    ).toBe(false)
  })

  it('sanitizes Library cards and details without paths or raw catalog records', () => {
    const card = {
      id: 'opaque-id',
      title: 'Example',
      appName: 'ExampleApp',
      artworkUrl: null,
      developer: null,
      publisher: null,
      type: 'BASE_GAME',
      platforms: ['Windows'],
      installed: true,
      epicOwned: true,
      addOnCount: 0,
      releaseDate: null,
      lastModified: null,
      metadataAvailable: true,
      localPath: 'C:\\private\\game',
      rawCatalog: { secret: true },
    }
    const details = LibraryDetailsSchema.parse({
      ...card,
      description: '',
      longDescription: '',
      genres: [],
      features: [],
      subscriptions: [],
      identifiers: ['ExampleApp'],
      addOns: [],
    })
    expect(details).not.toHaveProperty('localPath')
    expect(details).not.toHaveProperty('rawCatalog')

    expect(
      LibraryPageSchema.safeParse({
        items: [card],
        total: 1,
        page: 1,
        pageSize: 48,
        hasMore: false,
        facets: { genres: [], features: [], types: [], platforms: [], subscriptions: [] },
        status: {
          state: 'ready',
          total: 1,
          owned: 1,
          installed: 1,
          partialMetadata: 0,
          signedIn: true,
          localScanState: 'complete',
          lastRefreshedAt: null,
          taxonomyUpdatedAt: null,
          warnings: [],
        },
      }).success,
    ).toBe(true)
  })
})
