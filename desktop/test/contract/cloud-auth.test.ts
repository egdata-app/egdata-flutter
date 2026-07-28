import { EventEmitter } from 'node:events'

import { beforeEach, describe, expect, it, vi } from 'vitest'

const electron = vi.hoisted(() => ({
  clearStorageData: vi.fn(() => Promise.resolve()),
}))

vi.mock('electron', () => ({
  BrowserWindow: class {},
  session: {
    fromPartition: vi.fn(() => ({ clearStorageData: electron.clearStorageData })),
  },
}))

import {
  EPIC_AUTH_ORIGINS,
  EPIC_AUTH_PARTITION,
  EPIC_LAUNCHER_CLIENT_ID,
  EpicAuthService,
  type AuthWindow,
  type AuthWindowWebContents,
  type TokenCipher,
  type TokenPersistenceAdapter,
} from '../../src/main/auth'

class MemoryPersistence implements TokenPersistenceAdapter {
  value: string | null = null

  load(): Promise<string | null> {
    return Promise.resolve(this.value)
  }
  save(value: string): Promise<void> {
    this.value = value
    return Promise.resolve()
  }
  clear(): Promise<void> {
    this.value = null
    return Promise.resolve()
  }
}

const cipher: TokenCipher = {
  encrypt: (value) => `encrypted:${Buffer.from(value).toString('base64')}`,
  decrypt: (value) => Buffer.from(value.slice('encrypted:'.length), 'base64').toString(),
}

class FakeWebContents extends EventEmitter implements AuthWindowWebContents {
  currentUrl = 'about:blank'
  body = ''
  popupHandler: ((details: { url: string }) => { action: 'deny' }) | null = null

  setWindowOpenHandler(handler: (details: { url: string }) => { action: 'deny' }): void {
    this.popupHandler = handler
  }

  getURL(): string {
    return this.currentUrl
  }
  executeJavaScript(): Promise<unknown> {
    return Promise.resolve(this.body)
  }
}

class FakeWindow extends EventEmitter implements AuthWindow {
  readonly webContents = new FakeWebContents()
  destroyed = false
  loadedUrl = ''
  preventedExternalNavigation = false

  loadURL(login: string): Promise<void> {
    this.loadedUrl = login
    const redirect = new URL(new URL(login).searchParams.get('redirectUrl')!)
    redirect.searchParams.set('code', 'one-use-code')
    this.webContents.currentUrl = redirect.toString()
    const navigation = {
      preventDefault: () => {
        this.preventedExternalNavigation = true
      },
    }
    this.webContents.emit('will-navigate', navigation, 'https://attacker.invalid/callback')
    this.webContents.emit('did-navigate', {}, redirect.toString())
    return Promise.resolve()
  }

  close(): void {
    if (this.destroyed) return
    this.destroyed = true
    this.emit('closed')
  }

  isDestroyed(): boolean {
    return this.destroyed
  }
}

describe('EpicAuthService contract', () => {
  beforeEach(() => electron.clearStorageData.mockClear())

  it('uses launcherAppClient2 by default for Epic authorization', async () => {
    const persistence = new MemoryPersistence()
    const window = new FakeWindow()
    let tokenRequest: { input: string; init?: RequestInit } | null = null
    const service = new EpicAuthService({
      persistence,
      cipher,
      createWindow: () => window,
      fetch: (input, init) => {
        const requestUrl =
          typeof input === 'string' ? input : input instanceof URL ? input.toString() : input.url
        tokenRequest = { input: requestUrl, init }
        return Promise.resolve(
          new Response(
            JSON.stringify({
              access_token: 'private-access',
              refresh_token: 'private-refresh',
              account_id: 'account-id',
              expires_in: 3600,
            }),
            { status: 200 },
          ),
        )
      },
    })

    await service.login()

    const loginUrl = new URL(window.loadedUrl)
    const redirectUrl = new URL(loginUrl.searchParams.get('redirectUrl')!)
    expect(redirectUrl.searchParams.get('clientId')).toBe(EPIC_LAUNCHER_CLIENT_ID)
    expect(redirectUrl.searchParams.get('responseType')).toBe('code')
    expect(tokenRequest).not.toBeNull()
    expect(tokenRequest!.input).toBe(
      'https://account-public-service-prod.ol.epicgames.com/account/api/oauth/token',
    )
    const headers = new Headers(tokenRequest!.init?.headers)
    const basicCredentials = Buffer.from(
      headers.get('Authorization')!.slice('Basic '.length),
      'base64',
    ).toString('utf8')
    expect(basicCredentials).toMatch(new RegExp(`^${EPIC_LAUNCHER_CLIENT_ID}:.+`))
    expect(headers.get('User-Agent')).toContain('UELauncher/')
    const requestBody = tokenRequest!.init?.body
    expect(requestBody).toBeInstanceOf(URLSearchParams)
    expect((requestBody as URLSearchParams).get('grant_type')).toBe('authorization_code')
  })

  it('returns the stable configuration error before opening a window', async () => {
    const createWindow = vi.fn(() => new FakeWindow())
    const service = new EpicAuthService({
      persistence: new MemoryPersistence(),
      cipher,
      clientId: '',
      clientSecret: '',
      createWindow,
    })

    await expect(service.login()).rejects.toMatchObject({ code: 'EPIC_CONFIGURATION_MISSING' })
    expect(createWindow).not.toHaveBeenCalled()
  })

  it('captures a code only through the expected redirect and never returns tokens', async () => {
    const persistence = new MemoryPersistence()
    const window = new FakeWindow()
    const tokenRequest = vi.fn(() =>
      Promise.resolve(
        new Response(
          JSON.stringify({
            access_token: 'private-access',
            refresh_token: 'private-refresh',
            account_id: 'account-id',
            expires_in: 3600,
          }),
          { status: 200 },
        ),
      ),
    )
    let partition = ''
    const service = new EpicAuthService({
      persistence,
      cipher,
      clientId: 'environment-client-id',
      clientSecret: 'environment-client-secret',
      createWindow: (value) => {
        partition = value
        return window
      },
      fetch: tokenRequest,
      now: () => Date.parse('2026-01-01T00:00:00.000Z'),
    })

    const state = await service.login()

    expect(state).toEqual({
      authenticated: true,
      accountId: 'account-id',
      expiresAt: '2026-01-01T01:00:00.000Z',
    })
    expect(state).not.toHaveProperty('accessToken')
    expect(state).not.toHaveProperty('refreshToken')
    expect(persistence.value).toMatch(/^encrypted:/)
    expect(persistence.value).not.toContain('private-access')
    expect(partition).toBe(EPIC_AUTH_PARTITION)
    expect(window.preventedExternalNavigation).toBe(true)
    expect(window.webContents.popupHandler?.({ url: 'https://attacker.invalid' })).toEqual({
      action: 'deny',
    })
    expect(EPIC_AUTH_ORIGINS).toEqual([
      'https://www.epicgames.com',
      'https://accounts.epicgames.com',
    ])
  })

  it('clears the encrypted envelope and isolated partition cookies on logout', async () => {
    const persistence = new MemoryPersistence()
    persistence.value = 'encrypted:anything'
    const service = new EpicAuthService({
      persistence,
      cipher,
      clientId: 'id',
      clientSecret: 'secret',
    })

    await service.logout()

    expect(persistence.value).toBeNull()
    expect(electron.clearStorageData).toHaveBeenCalledWith({ storages: ['cookies'] })
  })

  it('refreshes internally without exposing either token', async () => {
    const persistence = new MemoryPersistence()
    const window = new FakeWindow()
    let tokenRequestCount = 0
    const service = new EpicAuthService({
      persistence,
      cipher,
      clientId: 'environment-client-id',
      clientSecret: 'environment-client-secret',
      createWindow: () => window,
      fetch: () => {
        tokenRequestCount += 1
        return Promise.resolve(
          new Response(
            JSON.stringify({
              access_token: `private-access-${tokenRequestCount}`,
              refresh_token: `private-refresh-${tokenRequestCount}`,
              account_id: 'account-id',
              expires_in: 3600,
            }),
            { status: 200 },
          ),
        )
      },
      now: () => Date.parse('2026-01-01T00:00:00.000Z'),
    })
    await service.login()

    await service.refresh()

    expect(tokenRequestCount).toBe(2)
    expect(service.getState()).toEqual({
      authenticated: true,
      accountId: 'account-id',
      expiresAt: '2026-01-01T01:00:00.000Z',
    })
    expect(persistence.value).not.toContain('private-access-2')
    expect(persistence.value).not.toContain('private-refresh-2')
    service.dispose()
  })

  it('renews a restored session once in the background shortly before expiry', async () => {
    vi.useFakeTimers()
    vi.setSystemTime('2026-01-01T00:00:00.000Z')
    const persistence = new MemoryPersistence()
    persistence.value = cipher.encrypt(
      JSON.stringify({
        version: 1,
        accessToken: 'private-access-1',
        refreshToken: 'private-refresh-1',
        accountId: 'account-id',
        expiresAt: '2026-01-01T01:00:00.000Z',
      }),
    )
    const tokenRequest = vi.fn(() =>
      Promise.resolve(
        new Response(
          JSON.stringify({
            access_token: 'private-access-2',
            refresh_token: 'private-refresh-2',
            account_id: 'account-id',
            expires_in: 3600,
          }),
          { status: 200 },
        ),
      ),
    )
    const onBackgroundRefresh = vi.fn()
    const service = new EpicAuthService({
      persistence,
      cipher,
      clientId: 'environment-client-id',
      clientSecret: 'environment-client-secret',
      fetch: tokenRequest,
      onBackgroundRefresh,
    })

    try {
      await service.initialize()
      await vi.advanceTimersByTimeAsync(54 * 60_000 + 59_999)
      expect(tokenRequest).not.toHaveBeenCalled()

      await vi.advanceTimersByTimeAsync(1)

      expect(tokenRequest).toHaveBeenCalledOnce()
      const requestBody = tokenRequest.mock.calls[0]?.[1]?.body
      expect(requestBody).toBeInstanceOf(URLSearchParams)
      expect((requestBody as URLSearchParams).get('grant_type')).toBe('refresh_token')
      expect((requestBody as URLSearchParams).get('refresh_token')).toBe('private-refresh-1')
      expect(onBackgroundRefresh).toHaveBeenCalledWith(null)
      expect(service.getState()).toEqual({
        authenticated: true,
        accountId: 'account-id',
        expiresAt: '2026-01-01T01:55:00.000Z',
      })
    } finally {
      service.dispose()
      vi.useRealTimers()
    }
  })

  it('backs off after a temporary background renewal failure without losing the session', async () => {
    vi.useFakeTimers()
    vi.setSystemTime('2026-01-01T00:00:00.000Z')
    const persistence = new MemoryPersistence()
    persistence.value = cipher.encrypt(
      JSON.stringify({
        version: 1,
        accessToken: 'private-access-1',
        refreshToken: 'private-refresh-1',
        accountId: 'account-id',
        expiresAt: '2026-01-01T00:05:00.000Z',
      }),
    )
    const tokenRequest = vi
      .fn()
      .mockResolvedValueOnce(new Response(null, { status: 503 }))
      .mockResolvedValueOnce(
        new Response(
          JSON.stringify({
            access_token: 'private-access-2',
            refresh_token: 'private-refresh-2',
            account_id: 'account-id',
            expires_in: 3600,
          }),
          { status: 200 },
        ),
      )
    const onBackgroundRefresh = vi.fn()
    const service = new EpicAuthService({
      persistence,
      cipher,
      clientId: 'environment-client-id',
      clientSecret: 'environment-client-secret',
      fetch: tokenRequest,
      onBackgroundRefresh,
    })

    try {
      await service.initialize()
      await vi.advanceTimersByTimeAsync(0)

      expect(tokenRequest).toHaveBeenCalledOnce()
      expect(service.isAuthenticated).toBe(true)
      expect(onBackgroundRefresh).toHaveBeenCalledTimes(1)
      expect(onBackgroundRefresh.mock.calls[0]?.[0]).toBeInstanceOf(Error)

      await vi.advanceTimersByTimeAsync(59_999)
      expect(tokenRequest).toHaveBeenCalledOnce()
      await vi.advanceTimersByTimeAsync(1)

      expect(tokenRequest).toHaveBeenCalledTimes(2)
      expect(service.isAuthenticated).toBe(true)
      expect(onBackgroundRefresh).toHaveBeenLastCalledWith(null)
    } finally {
      service.dispose()
      vi.useRealTimers()
    }
  })

  it('does not restore a session when logout wins a race with background renewal', async () => {
    vi.useFakeTimers()
    vi.setSystemTime('2026-01-01T00:00:00.000Z')
    const persistence = new MemoryPersistence()
    persistence.value = cipher.encrypt(
      JSON.stringify({
        version: 1,
        accessToken: 'private-access-1',
        refreshToken: 'private-refresh-1',
        accountId: 'account-id',
        expiresAt: '2026-01-01T00:05:00.000Z',
      }),
    )
    let resolveTokenRequest!: (response: Response) => void
    const tokenRequest = vi.fn(
      () =>
        new Promise<Response>((resolve) => {
          resolveTokenRequest = resolve
        }),
    )
    const onBackgroundRefresh = vi.fn()
    const service = new EpicAuthService({
      persistence,
      cipher,
      clientId: 'environment-client-id',
      clientSecret: 'environment-client-secret',
      fetch: tokenRequest,
      onBackgroundRefresh,
    })

    try {
      await service.initialize()
      await vi.advanceTimersByTimeAsync(0)
      expect(tokenRequest).toHaveBeenCalledOnce()

      await service.logout()
      resolveTokenRequest(
        new Response(
          JSON.stringify({
            access_token: 'stale-private-access',
            refresh_token: 'stale-private-refresh',
            account_id: 'account-id',
            expires_in: 3600,
          }),
          { status: 200 },
        ),
      )
      await vi.advanceTimersByTimeAsync(0)

      expect(service.isAuthenticated).toBe(false)
      expect(persistence.value).toBeNull()
      expect(onBackgroundRefresh).not.toHaveBeenCalled()
      expect(vi.getTimerCount()).toBe(0)
    } finally {
      service.dispose()
      vi.useRealTimers()
    }
  })
})
