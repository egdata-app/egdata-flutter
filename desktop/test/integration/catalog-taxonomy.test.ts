import { mkdtemp, rm } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import path from 'node:path'
import { DatabaseSync } from 'node:sqlite'

import { afterEach, describe, expect, test, vi } from 'vitest'

import { CatalogDatabase, CatalogService, fetchCatalogTaxonomy } from '../../src/main/catalog'

const roots: string[] = []
afterEach(async () =>
  Promise.all(roots.splice(0).map((entry) => rm(entry, { recursive: true, force: true }))),
)

const tags = [
  { id: 'genre-action', name: 'Action', groupName: 'genre', status: 'active', ignored: true },
  { id: 'feature-coop', name: 'Co-op', groupName: 'epicfeature', status: 'active' },
  { id: 'ignored', name: 'Ignored', groupName: 'developer', status: 'active' },
]

describe('catalog taxonomy cache', () => {
  test('migrates to version 3 and persists only bounded Library taxonomy fields across reopen', async () => {
    const root = await mkdtemp(path.join(tmpdir(), 'egdata-taxonomy-'))
    roots.push(root)
    const filePath = path.join(root, 'catalog.v2.sqlite')
    const database = new CatalogDatabase(filePath)
    await database.initialize()
    database.replaceTaxonomy(
      [
        { id: 'genre-action', name: 'Action', groupName: 'genre', status: 'active' },
        { id: 'feature-coop', name: 'Co-op', groupName: 'epicfeature', status: 'active' },
      ],
      '2026-07-20T10:00:00.000Z',
    )
    database.close()

    const sqlite = new DatabaseSync(filePath)
    expect(
      (sqlite.prepare('PRAGMA user_version').get() as { user_version: number }).user_version,
    ).toBe(3)
    sqlite.close()

    const reopened = new CatalogDatabase(filePath)
    await reopened.initialize()
    expect(reopened.getTaxonomy()).toEqual({
      updatedAt: '2026-07-20T10:00:00.000Z',
      tags: [
        { id: 'genre-action', name: 'Action', groupName: 'genre', status: 'active' },
        { id: 'feature-coop', name: 'Co-op', groupName: 'epicfeature', status: 'active' },
      ],
    })
    reopened.close()
  })

  test('honors 24-hour freshness and preserves cached taxonomy after a failed forced refresh', async () => {
    const root = await mkdtemp(path.join(tmpdir(), 'egdata-taxonomy-'))
    roots.push(root)
    let now = new Date('2026-07-20T10:00:00.000Z')
    const fetchImpl = vi.fn<typeof fetch>(() =>
      Promise.resolve(
        new Response(JSON.stringify(tags), {
          status: 200,
          headers: { 'content-type': 'application/json' },
        }),
      ),
    )
    const service = new CatalogService({
      filePath: path.join(root, 'catalog.v2.sqlite'),
      fetchImpl,
      now: () => now,
    })
    await service.initialize()
    const first = await service.refreshTaxonomy(false)
    expect(first.updated).toBe(true)
    expect(first.snapshot.tags.map((entry) => entry.id)).toEqual(['genre-action', 'feature-coop'])
    await service.refreshTaxonomy(false)
    expect(fetchImpl).toHaveBeenCalledTimes(1)

    now = new Date('2026-07-21T10:00:01.000Z')
    fetchImpl.mockRejectedValueOnce(new Error('offline'))
    const failed = await service.refreshTaxonomy(false)
    expect(failed.warning).toMatch(/cached taxonomy/i)
    expect(failed.snapshot.tags).toEqual(first.snapshot.tags)
    service.close()
  })

  test('rejects malformed and oversized taxonomy responses', async () => {
    await expect(
      fetchCatalogTaxonomy(
        'https://api.example.test',
        vi.fn<typeof fetch>(() => Promise.resolve(new Response('{not-json', { status: 200 }))),
      ),
    ).rejects.toThrow(/invalid/i)

    await expect(
      fetchCatalogTaxonomy(
        'https://api.example.test',
        vi.fn<typeof fetch>(() =>
          Promise.resolve(
            new Response('[]', {
              status: 200,
              headers: { 'content-length': String(2 * 1024 * 1024 + 1) },
            }),
          ),
        ),
      ),
    ).rejects.toThrow(/too large/i)
  })
})
