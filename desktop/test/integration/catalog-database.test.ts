import { mkdtemp, stat, writeFile } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import path from 'node:path'

import { afterEach, describe, expect, test } from 'vitest'

import {
  CatalogDatabase,
  catalogHydrationRootKey,
  catalogRecordKey,
  catalogSha256,
  stableJson,
  type CatalogHydrationIdentifier,
  type CatalogRecord,
} from '../../src/main/catalog'

const directories: string[] = []
const temporaryDirectory = async (): Promise<string> => {
  const directory = await mkdtemp(path.join(tmpdir(), 'egdata-catalog-v2-'))
  directories.push(directory)
  return directory
}

afterEach(async () => {
  const { rm } = await import('node:fs/promises')
  await Promise.all(
    directories.splice(0).map((directory) => rm(directory, { recursive: true, force: true })),
  )
})

const identifier: CatalogHydrationIdentifier = {
  type: 'item',
  namespace: 'example',
  id: 'item-1',
}

const records: CatalogRecord[] = [
  {
    type: 'offer',
    namespace: 'example',
    id: 'offer-1',
    title: 'Canonical Game',
    description: 'Store description',
    keyImages: [],
    tags: [],
    categories: [],
    customAttributes: [],
    countriesBlacklist: [],
    countriesWhitelist: [],
    offerMappings: [],
  },
  {
    type: 'item',
    namespace: 'example',
    id: 'item-1',
    title: 'Technical Game',
    keyImages: [],
    categories: [],
    customAttributes: [{ key: 'canRunOffline', value: 'true' }],
    installModes: [],
    primaryOfferNamespace: 'example',
    primaryOfferId: 'offer-1',
  },
  {
    type: 'asset',
    namespace: 'example',
    artifactId: 'ExampleGame',
    platform: 'Windows',
    itemNamespace: 'example',
    itemId: 'item-1',
  },
  {
    type: 'offer-item',
    offerNamespace: 'example',
    offerId: 'offer-1',
    itemNamespace: 'example',
    itemId: 'item-1',
    sources: ['direct'],
    isPrimary: true,
  },
]

const resolved = (selected = records) => {
  const envelopes = selected.map((record) => ({
    recordKey: catalogRecordKey(record),
    sha256: catalogSha256(stableJson(record)),
    record,
  }))
  const graphHash = catalogSha256(
    stableJson(
      envelopes
        .map((entry) => [entry.recordKey, entry.sha256] as const)
        .sort(([left], [right]) => left.localeCompare(right)),
    ),
  )
  return {
    schemaVersion: 2,
    rootKey: catalogHydrationRootKey(identifier),
    identifier,
    hydratedAt: '2026-07-20T10:00:00.000Z',
    status: 'resolved',
    graphHash,
    recordKeys: envelopes.map((entry) => entry.recordKey).sort(),
    records: envelopes,
  }
}

describe('catalog v2 database', () => {
  test('creates v2 first, removes legacy files, reopens, and preserves incremental FTS', async () => {
    const root = await temporaryDirectory()
    const legacy = path.join(root, 'catalog.v1.sqlite')
    await writeFile(legacy, 'legacy')
    const database = new CatalogDatabase(path.join(root, 'catalog.v2.sqlite'))
    await database.initialize()
    database.reconcileScope('local:default', 'local-default', [identifier])
    database.applyHydrationRoot(resolved())
    expect(
      database.search({ query: 'Canonical', page: 1, pageSize: 50, resultKind: 'all' }).items[0],
    ).toMatchObject({ kind: 'offer', title: 'Canonical Game' })
    expect(
      database.resolveDisplayName({ namespace: 'example', catalogItemId: 'item-1' })?.displayName,
    ).toBe('Canonical Game')
    await expect(stat(legacy)).rejects.toMatchObject({ code: 'ENOENT' })
    database.close()

    const reopened = new CatalogDatabase(path.join(root, 'catalog.v2.sqlite'))
    await reopened.initialize()
    expect(reopened.getState().counts).toEqual({
      offers: 1,
      items: 1,
      assets: 1,
      releaseApps: 0,
      offerItems: 1,
    })
    reopened.close()
  })

  test('prunes only after the final authoritative scope drops a shared root', async () => {
    const root = await temporaryDirectory()
    const database = new CatalogDatabase(path.join(root, 'catalog.v2.sqlite'))
    await database.initialize()
    database.reconcileScope('local:default', 'local-default', [identifier])
    database.reconcileScope('cloud:opaque:windows', 'cloud-account', [identifier])
    database.applyHydrationRoot(resolved())
    database.reconcileScope('local:default', 'local-default', [])
    expect(database.getState().counts.items).toBe(1)
    database.removeScope('cloud:opaque:windows')
    expect(database.getState().counts).toEqual({
      offers: 0,
      items: 0,
      assets: 0,
      releaseApps: 0,
      offerItems: 0,
    })
    expect(database.search({ query: '', page: 1, pageSize: 50, resultKind: 'all' }).total).toBe(0)
    database.close()
  })

  test('uses a digital extra item title instead of its parent offer title', async () => {
    const root = await temporaryDirectory()
    const database = new CatalogDatabase(path.join(root, 'catalog.v2.sqlite'))
    await database.initialize()
    database.reconcileScope('local:default', 'local-default', [identifier])
    const digitalExtra: CatalogRecord = {
      type: 'item',
      namespace: 'example',
      id: 'redmod',
      title: 'Cyberpunk 2077 - REDmod',
      keyImages: [],
      categories: ['applications', 'digitalextras'],
      customAttributes: [],
      installModes: [],
      primaryOfferNamespace: 'example',
      primaryOfferId: 'offer-1',
    }
    const offerItem: CatalogRecord = {
      type: 'offer-item',
      offerNamespace: 'example',
      offerId: 'offer-1',
      itemNamespace: 'example',
      itemId: 'redmod',
      sources: ['direct'],
      isPrimary: true,
    }
    database.applyHydrationRoot(resolved([...records, digitalExtra, offerItem]))

    expect(
      database.resolveDisplayName({ namespace: 'example', catalogItemId: 'redmod' })?.displayName,
    ).toBe('Cyberpunk 2077 - REDmod')
    expect(
      database.getLibraryMetadata({ namespace: 'example', catalogItemId: 'redmod' }),
    ).toMatchObject({
      title: 'Cyberpunk 2077 - REDmod',
      kind: 'digital-extra',
    })
    database.close()
  })

  test('rolls back a malformed delta and authoritatively clears not-found roots', async () => {
    const root = await temporaryDirectory()
    const database = new CatalogDatabase(path.join(root, 'catalog.v2.sqlite'))
    await database.initialize()
    database.reconcileScope('local:default', 'local-default', [identifier])
    database.applyHydrationRoot(resolved())
    const malformed = { ...resolved(), records: [] }
    malformed.graphHash = 'a'.repeat(64)
    expect(() => database.applyHydrationRoot(malformed)).toThrow(/omitted|hash/i)
    expect(database.getState().counts.items).toBe(1)
    database.applyHydrationRoot({
      schemaVersion: 2,
      rootKey: catalogHydrationRootKey(identifier),
      identifier,
      hydratedAt: '2026-07-21T10:00:00.000Z',
      status: 'not-found',
    })
    expect(database.getState().counts.items).toBe(0)
    database.close()
  })

  test('honors error retry times for automatic access while manual sync still selects the root', async () => {
    const root = await temporaryDirectory()
    const database = new CatalogDatabase(path.join(root, 'catalog.v2.sqlite'))
    await database.initialize()
    database.reconcileScope(
      'local:default',
      'local-default',
      [identifier],
      '2026-07-20T10:00:00.000Z',
    )
    database.applyHydrationRoot(resolved())
    database.applyHydrationRoot({
      schemaVersion: 2,
      rootKey: catalogHydrationRootKey(identifier),
      identifier,
      hydratedAt: '2026-07-20T10:30:00.000Z',
      status: 'error',
      error: {
        code: 'CATALOG_ROOT_RESOLUTION_FAILED',
        message: 'This catalog root could not be hydrated.',
      },
    })

    const staleBefore = '2026-07-21T00:00:00.000Z'
    const beforeRetry = '2026-07-20T11:00:00.000Z'
    const afterRetry = '2026-07-20T11:31:00.000Z'
    expect(database.listHydrationIdentifiers(staleBefore, beforeRetry)).toEqual([])
    expect(database.filterInterestedIdentifiers([identifier], staleBefore, beforeRetry)).toEqual([])
    expect(
      database.listIdentifiersForDetails(
        { kind: 'offer', namespace: 'example', id: 'offer-1' },
        staleBefore,
        beforeRetry,
      ),
    ).toEqual([])

    expect(database.listHydrationIdentifiers()).toEqual([identifier])
    expect(database.listHydrationIdentifiers(staleBefore, afterRetry)).toEqual([identifier])
    expect(database.filterInterestedIdentifiers([identifier], staleBefore, afterRetry)).toEqual([
      identifier,
    ])
    database.close()
  })
})
