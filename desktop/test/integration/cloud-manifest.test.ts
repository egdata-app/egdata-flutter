import { readFile } from 'node:fs/promises'

import { describe, expect, it, vi } from 'vitest'

import type { EpicAuthorizedRequester } from '../../src/main/auth/types'
import { EpicManifestService, type EpicLibraryItem } from '../../src/main/cloud'

const item: EpicLibraryItem = {
  appName: 'app',
  title: 'Game',
  catalogItemId: 'catalog',
  namespace: 'namespace',
  assetId: 'asset',
  buildVersion: null,
}

function authReturning(response: Response): EpicAuthorizedRequester {
  return {
    isAuthenticated: true,
    authorizedFetch: vi.fn(() => Promise.resolve(response)),
    refresh: vi.fn(() => Promise.resolve()),
    logout: vi.fn(() => Promise.resolve()),
  }
}

describe('EpicManifestService', () => {
  it('merges existing and returned parameters and downloads opaque bytes', async () => {
    const assetJson = await readFile(
      new URL('../fixtures/cloud/launcher-asset.json', import.meta.url),
      'utf8',
    )
    let downloadUrl = ''
    const service = new EpicManifestService({
      auth: authReturning(new Response(assetJson, { status: 200 })),
      platform: 'Windows',
      fetch: vi.fn((input: string | URL | Request) => {
        downloadUrl = new URL(
          typeof input === 'string' || input instanceof URL ? input : input.url,
        ).toString()
        return Promise.resolve(
          new Response(new Uint8Array([0, 7, 255]), {
            status: 200,
            headers: { 'content-length': '3' },
          }),
        )
      }),
    })

    const result = await service.getManifest(item)

    expect(result?.bytes).toEqual(new Uint8Array([0, 7, 255]))
    expect(result?.buildVersion).toBe('5.0.7')
    const parsedDownloadUrl = new URL(downloadUrl)
    expect(parsedDownloadUrl.searchParams.get('existing')).toBe('kept')
    expect(parsedDownloadUrl.searchParams.get('signature')).toBe('sanitized-signature')
    expect(parsedDownloadUrl.searchParams.get('expires')).toBe('123456')
  })

  it('returns null for an asset 404 without starting a download', async () => {
    const download = vi.fn<typeof fetch>()
    const service = new EpicManifestService({
      auth: authReturning(new Response(null, { status: 404 })),
      platform: 'Mac',
      fetch: download,
    })
    await expect(service.getManifest(item)).resolves.toBeNull()
    expect(download).not.toHaveBeenCalled()
  })

  it('aborts an active binary body download', async () => {
    const asset = JSON.stringify({
      elements: [{ manifests: [{ uri: 'https://download.example.invalid/file.manifest' }] }],
    })
    let observedSignal: AbortSignal | undefined
    const service = new EpicManifestService({
      auth: authReturning(new Response(asset, { status: 200 })),
      platform: 'Windows',
      fetch: vi.fn((_input: string | URL | Request, init?: RequestInit) => {
        observedSignal = init?.signal ?? undefined
        return Promise.resolve(
          new Response(
            new ReadableStream({
              start(streamController) {
                observedSignal?.addEventListener(
                  'abort',
                  () => {
                    streamController.error(new DOMException('Aborted', 'AbortError'))
                  },
                  { once: true },
                )
              },
            }),
            { status: 200 },
          ),
        )
      }),
      downloadTimeoutMs: 10_000,
    })
    const controller = new AbortController()
    const operation = service.getManifest(item, { signal: controller.signal })
    await vi.waitFor(() => expect(observedSignal).toBeDefined())
    controller.abort()

    await expect(operation).rejects.toMatchObject({ code: 'SYNC_CANCELLED' })
    expect(observedSignal?.aborted).toBe(true)
  })
})
