import { readFile } from 'node:fs/promises'

import { describe, expect, it, vi } from 'vitest'

import type { EpicAuthorizedRequester } from '../../src/main/auth/types'
import { EpicLibraryService } from '../../src/main/cloud'

const fixture = (name: string) =>
  readFile(new URL(`../fixtures/cloud/${name}`, import.meta.url), 'utf8')

describe('EpicLibraryService', () => {
  it('paginates with exact parameters, filters records, dedupes, and refreshes once', async () => {
    const [pageOne, pageTwo] = await Promise.all([
      fixture('library-page-1.json'),
      fixture('library-page-2.json'),
    ])
    const requests: URL[] = []
    let calls = 0
    const authorizedFetch = vi.fn((input: string | URL) => {
      requests.push(new URL(input))
      calls += 1
      if (calls === 1) return Promise.resolve(new Response(null, { status: 401 }))
      return Promise.resolve(
        new Response(calls === 2 ? pageOne : pageTwo, {
          status: 200,
          headers: { 'content-type': 'application/json' },
        }),
      )
    })
    const refresh = vi.fn(() => Promise.resolve())
    const logout = vi.fn(() => Promise.resolve())
    const auth: EpicAuthorizedRequester = {
      isAuthenticated: true,
      authorizedFetch,
      refresh,
      logout,
    }
    const service = new EpicLibraryService({ auth, platform: 'Mac', pageLimit: 500 })

    const result = await service.getLibrary()

    expect(refresh).toHaveBeenCalledTimes(1)
    expect(logout).not.toHaveBeenCalled()
    expect(result.map((entry) => entry.catalogItemId)).toEqual(['catalog-alpha', 'catalog-beta'])
    expect(result[1]!.buildVersion).toBe('2.4.1')
    for (const request of requests) {
      expect(request.searchParams.get('includeMetadata')).toBe('true')
      expect(request.searchParams.get('platform')).toBe('Mac')
      expect(request.searchParams.get('excludeNs')).toBe('ue')
      expect(request.searchParams.get('limit')).toBe('200')
    }
    expect(requests[2]!.searchParams.get('cursor')).toBe('page two/+=')
  })

  it('ends the session when the one refreshed request is also unauthorized', async () => {
    const authorizedFetch = vi.fn(() => Promise.resolve(new Response(null, { status: 401 })))
    const refresh = vi.fn(() => Promise.resolve())
    const logout = vi.fn(() => Promise.resolve())
    const auth: EpicAuthorizedRequester = {
      isAuthenticated: true,
      authorizedFetch,
      refresh,
      logout,
    }

    await expect(
      new EpicLibraryService({ auth, platform: 'Windows' }).getLibrary(),
    ).rejects.toMatchObject({ code: 'EPIC_SESSION_EXPIRED' })
    expect(refresh).toHaveBeenCalledTimes(1)
    expect(authorizedFetch).toHaveBeenCalledTimes(2)
    expect(logout).toHaveBeenCalledTimes(1)
  })

  it('bounds reading of a stalled response body', async () => {
    const auth: EpicAuthorizedRequester = {
      isAuthenticated: true,
      authorizedFetch: vi.fn(() =>
        Promise.resolve(new Response(new ReadableStream({ start() {} }), { status: 200 })),
      ),
      refresh: vi.fn(() => Promise.resolve()),
      logout: vi.fn(() => Promise.resolve()),
    }

    await expect(
      new EpicLibraryService({
        auth,
        platform: 'Windows',
        requestTimeoutMs: 10,
      }).getLibrary(),
    ).rejects.toMatchObject({ code: 'EPIC_LIBRARY_REQUEST_FAILED' })
  })
})
