import { describe, expect, test } from 'vitest'

import type { LibraryQueryRequest, LocalManifest } from '../../src/shared/contracts'
import type { CatalogLibraryMetadata, CatalogTaxonomySnapshot } from '../../src/main/catalog'
import { buildLibraryProjection, queryLibraryProjection } from '../../src/main/library/projection'
import type { EpicLibraryItem } from '../../src/main/cloud'

const taxonomy: CatalogTaxonomySnapshot = {
  updatedAt: '2026-07-20T10:00:00.000Z',
  tags: [
    { id: 'genre-action', name: 'Action', groupName: 'genre', status: 'active' },
    { id: 'genre-rpg', name: 'RPG', groupName: 'genre', status: 'active' },
    { id: 'feature-coop', name: 'Co-op', groupName: 'feature', status: 'active' },
    {
      id: 'feature-achievements',
      name: 'Achievements',
      groupName: 'epicfeature',
      status: 'active',
    },
    { id: 'subscription-plus', name: 'Epic Plus', groupName: 'subscription', status: 'active' },
  ],
}

const request = (patch: Partial<LibraryQueryRequest> = {}): LibraryQueryRequest => ({
  text: '',
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
  ...patch,
})

const owned = (catalogItemId: string, title: string, appName = catalogItemId): EpicLibraryItem => ({
  appName,
  title,
  catalogItemId,
  namespace: 'example',
  assetId: appName,
  buildVersion: null,
})

const local = (
  catalogItemId: string,
  title: string,
  groupId = catalogItemId,
  kind: LocalManifest['kind'] = 'base-game',
): LocalManifest => ({
  id: `local-${catalogItemId}`,
  appName: catalogItemId,
  displayName: title,
  catalogItemId,
  namespace: 'example',
  sourceFilename: `${catalogItemId}.item`,
  platform: 'windows',
  kind,
  binaryManifestAvailable: true,
  groupId,
})

const metadata = (
  catalogItemId: string,
  title: string,
  patch: Partial<CatalogLibraryMetadata> = {},
): CatalogLibraryMetadata => ({
  namespace: 'example',
  catalogItemId,
  offerId: `offer-${catalogItemId}`,
  title,
  description: `${title} description`,
  longDescription: '',
  developer: 'Example Studio',
  publisher: 'Example Publisher',
  offerType: 'BASE_GAME',
  artworkUrl: `https://cdn.example.test/${catalogItemId}.jpg`,
  platforms: ['Windows'],
  tagIds: [],
  identifiers: [catalogItemId],
  releaseDate: '2025-01-01T00:00:00.000Z',
  lastModified: '2026-01-01T00:00:00.000Z',
  kind: 'base-game',
  mainGame: null,
  ...patch,
})

function projection(options: {
  owned?: EpicLibraryItem[]
  local?: LocalManifest[]
  metadata?: CatalogLibraryMetadata[]
}) {
  const records = new Map((options.metadata ?? []).map((entry) => [entry.catalogItemId, entry]))
  return buildLibraryProjection({
    owned: options.owned ?? [],
    local: options.local ?? [],
    taxonomy,
    resolveMetadata: (input) => records.get(input.catalogItemId ?? '') ?? null,
    signedIn: true,
    localScanState: 'complete',
    refreshing: false,
    lastRefreshedAt: null,
    warnings: [],
  })
}

describe('Library projection', () => {
  test('deduplicates ownership and installation under a stable catalog identity', () => {
    const first = projection({
      owned: [owned('game', 'Launcher title')],
      local: [local('game', 'Local title')],
      metadata: [metadata('game', 'Hydrated title')],
    })
    const second = projection({
      local: [local('game', 'Changed local title')],
      owned: [owned('game', 'Changed launcher title')],
      metadata: [metadata('game', 'Hydrated title')],
    })

    expect(first.entries).toHaveLength(1)
    expect(first.entries[0]?.card).toMatchObject({
      title: 'Hydrated title',
      installed: true,
      epicOwned: true,
      metadataAvailable: true,
    })
    expect(second.entries[0]?.card.id).toBe(first.entries[0]?.card.id)
  })

  test('groups resolved, locally associated, and namespace-matched extras', () => {
    const result = projection({
      owned: [owned('base', 'Base'), owned('addon', 'DLC'), owned('orphan', 'Orphan DLC')],
      local: [local('base', 'Base', 'group'), local('local-addon', 'Local DLC', 'group', 'addon')],
      metadata: [
        metadata('base', 'Base'),
        metadata('addon', 'Story DLC', {
          kind: 'addon',
          mainGame: {
            catalogNamespace: 'example',
            catalogItemId: 'base',
            artifactId: 'base',
          },
        }),
        metadata('orphan', 'Orphan DLC', { kind: 'addon' }),
      ],
    })

    expect(result.entries.map((entry) => entry.card.title)).toEqual(['Base'])
    const base = result.entries.find((entry) => entry.card.title === 'Base')
    expect(base?.card.addOnCount).toBe(3)
    expect(result.details.get(base!.card.id)?.addOns.map((entry) => entry.title)).toEqual([
      'Local DLC',
      'Orphan DLC',
      'Story DLC',
    ])
  })

  test('groups every non-base item with the sole base game in its namespace', () => {
    const result = projection({
      owned: [owned('base', 'Base'), owned('extra', 'Extra')],
      metadata: [
        metadata('base', 'Base'),
        metadata('extra', 'Extra', { kind: 'digital-extra', mainGame: null }),
      ],
    })

    expect(result.entries.map((entry) => entry.card.title)).toEqual(['Base'])
    expect(
      result.details.get(result.entries[0]!.card.id)?.addOns.map((entry) => entry.title),
    ).toEqual(['Extra'])
  })

  test('applies OR within facets, AND between facets, contextual counts, and tag search', () => {
    const result = projection({
      owned: [owned('alpha', 'Alpha'), owned('beta', 'Beta'), owned('gamma', 'Gamma')],
      metadata: [
        metadata('alpha', 'Alpha', {
          tagIds: ['genre-action', 'feature-coop', 'subscription-plus'],
        }),
        metadata('beta', 'Beta', { tagIds: ['genre-rpg', 'feature-achievements'] }),
        metadata('gamma', 'Gamma', {
          tagIds: ['genre-action', 'genre-rpg', 'feature-achievements'],
        }),
      ],
    })

    const filtered = queryLibraryProjection(
      result,
      request({ genreIds: ['genre-action', 'genre-rpg'], featureIds: ['feature-coop'] }),
    )
    expect(filtered.items.map((item) => item.title)).toEqual(['Alpha'])
    expect(filtered.facets.features).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ id: 'feature-coop', count: 1 }),
        expect.objectContaining({ id: 'feature-achievements', count: 2 }),
      ]),
    )
    expect(queryLibraryProjection(result, request({ text: 'epic plus' })).items[0]?.title).toBe(
      'Alpha',
    )
  })

  test('keeps null dates last in both directions and paginates deterministically', () => {
    const result = projection({
      owned: [owned('alpha', 'Alpha'), owned('beta', 'Beta'), owned('gamma', 'Gamma')],
      metadata: [
        metadata('alpha', 'Alpha', { releaseDate: '2024-01-01T00:00:00.000Z' }),
        metadata('beta', 'Beta', { releaseDate: null }),
        metadata('gamma', 'Gamma', { releaseDate: '2026-01-01T00:00:00.000Z' }),
      ],
    })

    expect(
      queryLibraryProjection(
        result,
        request({ sortField: 'releaseDate', sortDirection: 'desc', pageSize: 2 }),
      ).items.map((entry) => entry.title),
    ).toEqual(['Gamma', 'Alpha'])
    expect(
      queryLibraryProjection(
        result,
        request({
          sortField: 'releaseDate',
          sortDirection: 'desc',
          page: 2,
          pageSize: 2,
        }),
      ).items.map((entry) => entry.title),
    ).toEqual(['Beta'])
  })

  test('uses sanitized source metadata when hydration is missing', () => {
    const result = projection({ local: [local('unknown', 'Local fallback')] })
    expect(result.entries[0]?.card).toMatchObject({
      title: 'Local fallback',
      artworkUrl: null,
      metadataAvailable: false,
      installed: true,
      epicOwned: false,
    })
    expect(result.status.partialMetadata).toBe(1)
  })
})
