import { mkdtemp, rm } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'

import { afterEach, describe, expect, it, vi } from 'vitest'

import type { LocalManifestUploadPayload } from '../../src/main/manifests/types'
import type { QueueItemSnapshot } from '../../src/main/queue'
import { ManifestCache } from '../../src/main/storage'
import { manifestContentHash, uploadManifestWithCache } from '../../src/main/uploads'

const temporaryDirectories: string[] = []
const openCaches: ManifestCache[] = []

afterEach(async () => {
  for (const cache of openCaches.splice(0)) cache.close()
  await Promise.all(
    temporaryDirectories
      .splice(0)
      .map((directory) => rm(directory, { recursive: true, force: true })),
  )
})

async function newCache(): Promise<{ cache: ManifestCache; filePath: string }> {
  const directory = await mkdtemp(join(tmpdir(), 'egdata-manifest-cache-'))
  temporaryDirectories.push(directory)
  const filePath = join(directory, 'manifest-cache.v1.sqlite')
  const cache = new ManifestCache(filePath)
  await cache.initialize()
  openCaches.push(cache)
  return { cache, filePath }
}

function payload(bytes = [1, 2, 3]): LocalManifestUploadPayload {
  return {
    itemId: 'manifest-id',
    rawItemText: '{}',
    manifestBytes: new Uint8Array(bytes),
    installationGuid: 'installation-guid',
  }
}

describe('manifest upload cache', () => {
  it('persists confirmed manifest hashes across database connections', async () => {
    const { cache, filePath } = await newCache()
    const contentHash = manifestContentHash(payload().manifestBytes)
    cache.confirm(contentHash, 'uploaded', 'server-hash')
    cache.close()
    openCaches.splice(openCaches.indexOf(cache), 1)

    const reopened = new ManifestCache(filePath)
    await reopened.initialize()
    openCaches.push(reopened)

    expect(reopened.find(contentHash)).toMatchObject({
      contentHash,
      serverManifestHash: 'server-hash',
      confirmation: 'uploaded',
    })
  })

  it('does not call the service again for an identical confirmed manifest', async () => {
    const { cache } = await newCache()
    const fetchImpl = vi.fn<typeof fetch>().mockResolvedValue(
      new Response(JSON.stringify({ status: 'uploaded', manifest_hash: 'server-hash' }), {
        status: 201,
      }),
    )

    const first = await uploadManifestWithCache(payload(), { platform: 'win32', fetchImpl }, cache)
    const second = await uploadManifestWithCache(payload(), { platform: 'win32', fetchImpl }, cache)

    expect(first.state).toBe('uploaded')
    expect(second).toMatchObject({
      state: 'already-uploaded',
      manifestHash: 'server-hash',
    })
    expect(fetchImpl).toHaveBeenCalledTimes(1)
  })

  it('remembers a server-reported duplicate as already online', async () => {
    const { cache } = await newCache()
    const fetchImpl = vi.fn<typeof fetch>().mockResolvedValue(new Response('', { status: 409 }))

    const first = await uploadManifestWithCache(payload(), { platform: 'win32', fetchImpl }, cache)
    const second = await uploadManifestWithCache(payload(), { platform: 'win32', fetchImpl }, cache)

    expect(first.state).toBe('already-uploaded')
    expect(second.state).toBe('already-uploaded')
    expect(second.message).toBe('Manifest already confirmed by egdata.app.')
    expect(fetchImpl).toHaveBeenCalledTimes(1)
  })

  it('retries failed uploads and uploads changed manifest content', async () => {
    const { cache } = await newCache()
    const fetchImpl = vi
      .fn<typeof fetch>()
      .mockResolvedValueOnce(new Response(JSON.stringify({ status: 'failed' }), { status: 500 }))
      .mockImplementation(() =>
        Promise.resolve(new Response(JSON.stringify({ status: 'uploaded' }), { status: 201 })),
      )

    expect(
      (await uploadManifestWithCache(payload(), { platform: 'win32', fetchImpl }, cache)).state,
    ).toBe('failed')
    expect(
      (await uploadManifestWithCache(payload(), { platform: 'win32', fetchImpl }, cache)).state,
    ).toBe('uploaded')
    expect(
      (await uploadManifestWithCache(payload([1, 2, 4]), { platform: 'win32', fetchImpl }, cache))
        .state,
    ).toBe('uploaded')
    expect(fetchImpl).toHaveBeenCalledTimes(3)
  })
})

describe('cloud sync database', () => {
  const libraryItem = (buildVersion: string) => ({
    id: 'namespace:catalog:app',
    title: 'Example Game',
    value: {
      appName: 'ExampleGame',
      title: 'Example Game',
      catalogItemId: 'catalog',
      namespace: 'namespace',
      assetId: 'asset',
      buildVersion,
    },
  })

  it('reconciles the library while preserving sync results for unchanged builds', async () => {
    const { cache, filePath } = await newCache()
    const first = cache.reconcileCloudLibrary('account-a', 'Windows', [
      libraryItem('1.0'),
      {
        ...libraryItem('1.0'),
        id: 'namespace:other:app',
        value: { ...libraryItem('1.0').value, catalogItemId: 'other' },
      },
    ])
    expect(first.map((item) => item.state)).toEqual(['pending', 'pending'])
    cache.updateCloudBuildVersion('account-a', 'Windows', first[0]!.id, '1.0-live')
    expect(cache.loadCloudQueue('account-a', 'Windows')[0]!.value.buildVersion).toBe('1.0-live')
    cache.updateCloudBuildVersion('account-a', 'Windows', first[0]!.id, '1.0')

    const completed: QueueItemSnapshot<(typeof first)[number]['value']> = {
      ...first[0]!,
      state: 'uploaded',
      attempts: 1,
      startedAt: '2026-01-01T00:00:00.000Z',
      finishedAt: '2026-01-01T00:00:01.000Z',
      error: null,
      message: 'Uploaded',
    }
    cache.saveCloudQueueItems('account-a', 'Windows', [completed])
    cache.close()
    openCaches.splice(openCaches.indexOf(cache), 1)

    const reopened = new ManifestCache(filePath)
    await reopened.initialize()
    openCaches.push(reopened)
    expect(reopened.loadCloudQueue('account-a', 'Windows')[0]).toMatchObject({
      state: 'uploaded',
      attempts: 1,
    })

    const unchanged = reopened.reconcileCloudLibrary('account-a', 'Windows', [libraryItem('1.0')])
    expect(unchanged).toHaveLength(1)
    expect(unchanged[0]).toMatchObject({ state: 'uploaded', attempts: 1 })

    const changed = reopened.reconcileCloudLibrary('account-a', 'Windows', [libraryItem('2.0')])
    expect(changed[0]).toMatchObject({
      state: 'pending',
      attempts: 0,
      startedAt: null,
      finishedAt: null,
    })
  })

  it('keeps cached cloud libraries isolated by Epic account and platform', async () => {
    const { cache } = await newCache()
    cache.reconcileCloudLibrary('account-a', 'Windows', [libraryItem('1.0')])

    expect(cache.loadCloudQueue('account-a', 'Windows')).toHaveLength(1)
    expect(cache.loadCloudQueue('account-b', 'Windows')).toEqual([])
    expect(cache.loadCloudQueue('account-a', 'Mac')).toEqual([])
  })

  it('preserves explicitly removed cloud items across library refreshes', async () => {
    const { cache } = await newCache()
    const [item] = cache.reconcileCloudLibrary('account-a', 'Windows', [libraryItem('1.0')])
    cache.saveCloudQueueItems('account-a', 'Windows', [
      {
        ...item!,
        state: 'removed',
        attempts: 1,
        startedAt: null,
        finishedAt: '2026-01-01T00:00:01.000Z',
        error: null,
        message: 'Removed from queue',
      },
    ])

    expect(cache.reconcileCloudLibrary('account-a', 'Windows', [libraryItem('2.0')])).toEqual([])
    expect(cache.reconcileCloudLibrary('account-a', 'Windows', [libraryItem('3.0')])).toEqual([])
  })

  it('distinguishes a cached empty library from one that has never been fetched', async () => {
    const { cache } = await newCache()
    expect(cache.hasCloudLibrarySnapshot('account-a', 'Windows')).toBe(false)

    cache.reconcileCloudLibrary('account-a', 'Windows', [])

    expect(cache.hasCloudLibrarySnapshot('account-a', 'Windows')).toBe(true)
    expect(cache.loadCloudQueue('account-a', 'Windows')).toEqual([])
  })
})
