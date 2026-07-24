import { mkdtemp, rm } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import path from 'node:path'

import { afterEach, describe, expect, test, vi } from 'vitest'

import {
  CatalogService,
  catalogHydrationRootKey,
  catalogRecordKey,
  catalogSha256,
  stableJson,
  type CatalogHydrationIdentifier,
  type CatalogRecord,
} from '../../src/main/catalog'

const roots: string[] = []
afterEach(async () =>
  Promise.all(roots.splice(0).map((entry) => rm(entry, { recursive: true, force: true }))),
)

const lineFor = (identifier: CatalogHydrationIdentifier): string => {
  if (identifier.namespace === 'ue') {
    return JSON.stringify({
      schemaVersion: 2,
      rootKey: catalogHydrationRootKey(identifier),
      identifier,
      hydratedAt: '2026-07-20T10:00:00.000Z',
      status: 'not-found',
    })
  }
  const itemId = identifier.type === 'item' ? identifier.id : 'item'
  const record: CatalogRecord = {
    type: 'item',
    namespace: identifier.namespace,
    id: itemId,
    title: 'Streamed Game',
    keyImages: [],
    categories: [],
    customAttributes: [],
    installModes: [],
  }
  const envelope = {
    recordKey: catalogRecordKey(record),
    sha256: catalogSha256(stableJson(record)),
    record,
  }
  const graphHash = catalogSha256(stableJson([[envelope.recordKey, envelope.sha256]]))
  return JSON.stringify({
    schemaVersion: 2,
    rootKey: catalogHydrationRootKey(identifier),
    identifier,
    hydratedAt: '2026-07-20T10:00:00.000Z',
    status: 'resolved',
    graphHash,
    recordKeys: [envelope.recordKey],
    records: [envelope],
  })
}

const errorLineFor = (identifier: CatalogHydrationIdentifier, hydratedAt: string): string =>
  JSON.stringify({
    schemaVersion: 2,
    rootKey: catalogHydrationRootKey(identifier),
    identifier,
    hydratedAt,
    status: 'error',
    error: {
      code: 'CATALOG_ROOT_RESOLUTION_FAILED',
      message: 'This catalog root could not be hydrated.',
    },
  })

describe('catalog NDJSON synchronization', () => {
  test('commits roots incrementally and isolates an Unreal not-found root', async () => {
    const root = await mkdtemp(path.join(tmpdir(), 'egdata-catalog-service-'))
    roots.push(root)
    const fetchImpl = vi.fn<typeof fetch>((_input, init) => {
      if (typeof init?.body !== 'string') throw new Error('Expected a JSON request body')
      const request = JSON.parse(init.body) as {
        identifiers: CatalogHydrationIdentifier[]
      }
      const body = request.identifiers.map(lineFor).join('\n') + '\n'
      return Promise.resolve(
        new Response(body, {
          status: 200,
          headers: { 'content-type': 'application/x-ndjson' },
        }),
      )
    })
    const service = new CatalogService({
      filePath: path.join(root, 'catalog.v2.sqlite'),
      fetchImpl,
    })
    await service.initialize()
    const status = await service.reconcileIdentifiers('local:default', 'local-default', [
      { type: 'item', namespace: 'game', id: 'item' },
      { type: 'item', namespace: 'ue', id: 'fab-asset' },
    ])
    expect(status.counts.items).toBe(1)
    expect(status.error).toBeNull()
    expect(
      service.search({ query: 'Streamed', page: 1, pageSize: 50, resultKind: 'all' }).items[0]
        ?.title,
    ).toBe('Streamed Game')
    expect(fetchImpl).toHaveBeenCalledTimes(1)
    service.close()
  })

  test('keeps roots committed before a malformed later line and reports bounded failure', async () => {
    const root = await mkdtemp(path.join(tmpdir(), 'egdata-catalog-service-'))
    roots.push(root)
    const fetchImpl = vi.fn<typeof fetch>((_input, init) => {
      if (typeof init?.body !== 'string') throw new Error('Expected a JSON request body')
      const request = JSON.parse(init.body) as {
        identifiers: CatalogHydrationIdentifier[]
      }
      return Promise.resolve(
        new Response(`${lineFor(request.identifiers[0]!)}\n{malformed}\n`, {
          status: 200,
          headers: { 'content-type': 'application/x-ndjson' },
        }),
      )
    })
    const service = new CatalogService({
      filePath: path.join(root, 'catalog.v2.sqlite'),
      fetchImpl,
    })
    await service.initialize()
    const status = await service.reconcileIdentifiers('local:default', 'local-default', [
      { type: 'item', namespace: 'game', id: 'item' },
      { type: 'item', namespace: 'other', id: 'other' },
    ])
    expect(status.state).toBe('failed')
    expect(status.counts.items).toBe(1)
    expect(status.error?.code).toBe('CATALOG_RESPONSE_INVALID')
    service.close()
  })

  test('backs off root errors during automatic access while manual sync overrides the delay', async () => {
    const root = await mkdtemp(path.join(tmpdir(), 'egdata-catalog-service-'))
    roots.push(root)
    let now = new Date('2026-07-20T10:00:00.000Z')
    const fetchImpl = vi.fn<typeof fetch>((_input, init) => {
      if (typeof init?.body !== 'string') throw new Error('Expected a JSON request body')
      const request = JSON.parse(init.body) as { identifiers: CatalogHydrationIdentifier[] }
      return Promise.resolve(
        new Response(
          request.identifiers.map((entry) => errorLineFor(entry, now.toISOString())).join('\n') +
            '\n',
          { status: 200, headers: { 'content-type': 'application/x-ndjson' } },
        ),
      )
    })
    const service = new CatalogService({
      filePath: path.join(root, 'catalog.v2.sqlite'),
      fetchImpl,
      now: () => now,
    })
    await service.initialize()
    await service.reconcileIdentifiers('local:default', 'local-default', [
      { type: 'item', namespace: 'game', id: 'item' },
    ])
    expect(fetchImpl).toHaveBeenCalledTimes(1)

    for (let attempt = 0; attempt < 5; attempt += 1) {
      await service.hydrateNames([{ namespace: 'game', catalogItemId: 'item' }])
    }
    expect(fetchImpl).toHaveBeenCalledTimes(1)

    await service.refresh()
    expect(fetchImpl).toHaveBeenCalledTimes(2)
    now = new Date('2026-07-20T11:01:00.000Z')
    await service.hydrateNames([{ namespace: 'game', catalogItemId: 'item' }])
    expect(fetchImpl).toHaveBeenCalledTimes(3)
    service.close()
  })

  test('persists transport failure backoff instead of retaining an immediate in-memory retry', async () => {
    const root = await mkdtemp(path.join(tmpdir(), 'egdata-catalog-service-'))
    roots.push(root)
    const now = new Date('2026-07-20T10:00:00.000Z')
    const fetchImpl = vi.fn<typeof fetch>(() => Promise.reject(new Error('offline')))
    const service = new CatalogService({
      filePath: path.join(root, 'catalog.v2.sqlite'),
      fetchImpl,
      now: () => now,
    })
    await service.initialize()
    const status = await service.reconcileIdentifiers('local:default', 'local-default', [
      { type: 'item', namespace: 'game', id: 'item' },
    ])
    expect(status.state).toBe('failed')
    expect(fetchImpl).toHaveBeenCalledTimes(1)

    for (let attempt = 0; attempt < 5; attempt += 1) {
      await service.hydrateNames([{ namespace: 'game', catalogItemId: 'item' }])
    }
    expect(fetchImpl).toHaveBeenCalledTimes(1)
    service.close()
  })
})
