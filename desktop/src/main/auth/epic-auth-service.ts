import { BrowserWindow, session } from 'electron'

import { EpicAuthError } from './errors'
import type { TokenCipher, TokenPersistenceAdapter } from './token-persistence'
import type { AuthWindow, AuthWindowFactory, EpicAuthState, EpicAuthorizedRequester } from './types'

const TOKEN_ENDPOINT =
  'https://account-public-service-prod.ol.epicgames.com/account/api/oauth/token'
const LOGIN_ORIGIN = 'https://www.epicgames.com'
const LOGIN_PATH = '/id/login'
const REDIRECT_PATH = '/id/api/redirect'

// Epic's launcher client is required for the private EGS library and launcher
// asset services. These credentials are distributed with Epic Games Launcher
// clients and cannot be treated as confidential in a packaged desktop app.
export const EPIC_LAUNCHER_CLIENT_ID = '34a02cf8f4414e29b15921876da36f9a'
const EPIC_LAUNCHER_CLIENT_SECRET = 'daafbccc737745039dffe53d94fc76cf'
const EPIC_LAUNCHER_USER_AGENT =
  'UELauncher/11.0.1-14907503+++Portal+Release-Live Windows/10.0.19045.1.256.64bit'

export const EPIC_AUTH_PARTITION = 'persist:egdata-epic-auth'
export const EPIC_AUTH_ORIGINS = Object.freeze([
  'https://www.epicgames.com',
  'https://accounts.epicgames.com',
] as const)

interface TokenEnvelope {
  version: 1
  accessToken: string
  refreshToken: string
  accountId: string
  expiresAt: string
}

export interface EpicAuthServiceOptions {
  persistence: TokenPersistenceAdapter
  cipher: TokenCipher
  fetch?: typeof fetch
  createWindow?: AuthWindowFactory
  clientId?: string
  clientSecret?: string
  loginTimeoutMs?: number
  requestTimeoutMs?: number
  partition?: string
  now?: () => number
}

function createEpicAuthWindow(partition: string): AuthWindow {
  return new BrowserWindow({
    width: 520,
    height: 720,
    show: true,
    title: 'Sign in to Epic Games',
    autoHideMenuBar: true,
    webPreferences: {
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true,
      partition,
      webSecurity: true,
    },
  })
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
}

function readNonEmptyString(value: unknown): string | null {
  return typeof value === 'string' && value.trim().length > 0 ? value : null
}

function resolveClientCredential(
  explicitValue: string | undefined,
  environmentValue: string | undefined,
  launcherDefault: string,
): string {
  if (explicitValue !== undefined) return explicitValue.trim()
  if (environmentValue !== undefined) return environmentValue.trim()
  return launcherDefault
}

function parseTokenResponse(value: unknown, now: number): TokenEnvelope | null {
  if (!isRecord(value)) return null
  const accessToken = readNonEmptyString(value.access_token)
  const refreshToken = readNonEmptyString(value.refresh_token)
  const accountId = readNonEmptyString(value.account_id)
  if (!accessToken || !refreshToken || !accountId) return null

  const explicitExpiry = readNonEmptyString(value.expires_at)
  const expiresIn =
    typeof value.expires_in === 'number' && Number.isFinite(value.expires_in)
      ? Math.max(0, value.expires_in)
      : 0
  const expiresAt = explicitExpiry ?? new Date(now + expiresIn * 1_000).toISOString()
  if (Number.isNaN(Date.parse(expiresAt))) return null

  return { version: 1, accessToken, refreshToken, accountId, expiresAt }
}

function parsePersistedEnvelope(value: unknown): TokenEnvelope | null {
  if (!isRecord(value) || value.version !== 1) return null
  const accessToken = readNonEmptyString(value.accessToken)
  const refreshToken = readNonEmptyString(value.refreshToken)
  const accountId = readNonEmptyString(value.accountId)
  const expiresAt = readNonEmptyString(value.expiresAt)
  if (
    !accessToken ||
    !refreshToken ||
    !accountId ||
    !expiresAt ||
    Number.isNaN(Date.parse(expiresAt))
  ) {
    return null
  }
  return { version: 1, accessToken, refreshToken, accountId, expiresAt }
}

export class EpicAuthService implements EpicAuthorizedRequester {
  readonly #persistence: TokenPersistenceAdapter
  readonly #cipher: TokenCipher
  readonly #fetch: typeof fetch
  readonly #createWindow: AuthWindowFactory
  readonly #clientId: string
  readonly #clientSecret: string
  readonly #loginTimeoutMs: number
  readonly #requestTimeoutMs: number
  readonly #partition: string
  readonly #now: () => number
  #tokens: TokenEnvelope | null = null
  #refreshPromise: Promise<void> | null = null

  constructor(options: EpicAuthServiceOptions) {
    this.#persistence = options.persistence
    this.#cipher = options.cipher
    this.#fetch = options.fetch ?? globalThis.fetch
    this.#createWindow = options.createWindow ?? createEpicAuthWindow
    this.#clientId = resolveClientCredential(
      options.clientId,
      process.env.EPIC_CLIENT_ID,
      EPIC_LAUNCHER_CLIENT_ID,
    )
    this.#clientSecret = resolveClientCredential(
      options.clientSecret,
      process.env.EPIC_CLIENT_SECRET,
      EPIC_LAUNCHER_CLIENT_SECRET,
    )
    this.#loginTimeoutMs = options.loginTimeoutMs ?? 5 * 60_000
    this.#requestTimeoutMs = options.requestTimeoutMs ?? 20_000
    this.#partition = options.partition ?? EPIC_AUTH_PARTITION
    this.#now = options.now ?? Date.now
  }

  get isAuthenticated(): boolean {
    return this.#tokens !== null
  }

  getState(): EpicAuthState {
    return {
      authenticated: this.#tokens !== null,
      accountId: this.#tokens?.accountId ?? null,
      expiresAt: this.#tokens?.expiresAt ?? null,
    }
  }

  async initialize(): Promise<EpicAuthState> {
    try {
      const encrypted = await this.#persistence.load()
      if (encrypted === null) return this.getState()
      const parsed = parsePersistedEnvelope(JSON.parse(this.#cipher.decrypt(encrypted)))
      if (parsed === null) {
        await this.#persistence.clear()
        return this.getState()
      }
      this.#tokens = parsed
      return this.getState()
    } catch {
      this.#tokens = null
      await this.#persistence.clear().catch(() => undefined)
      return this.getState()
    }
  }

  async login(): Promise<EpicAuthState> {
    this.#assertConfigured()
    const code = await this.#captureAuthorizationCode()
    await this.#exchange({ grant_type: 'authorization_code', code, token_type: 'eg1' })
    return this.getState()
  }

  async refresh(): Promise<void> {
    this.#assertConfigured()
    if (!this.#tokens) throw new EpicAuthError('EPIC_NOT_AUTHENTICATED')
    if (this.#refreshPromise) return this.#refreshPromise

    const refreshToken = this.#tokens.refreshToken
    this.#refreshPromise = this.#exchange({
      grant_type: 'refresh_token',
      refresh_token: refreshToken,
      token_type: 'eg1',
    })
      .catch(async (error) => {
        await this.logout()
        throw new EpicAuthError('EPIC_SESSION_EXPIRED', { cause: error })
      })
      .finally(() => {
        this.#refreshPromise = null
      })
    return this.#refreshPromise
  }

  async authorizedFetch(input: string | URL, init: RequestInit = {}): Promise<Response> {
    const accessToken = this.#tokens?.accessToken
    if (!accessToken) throw new EpicAuthError('EPIC_NOT_AUTHENTICATED')
    const headers = new Headers(init.headers)
    headers.set('Authorization', `Bearer ${accessToken}`)
    headers.set('User-Agent', EPIC_LAUNCHER_USER_AGENT)
    return this.#fetch(input, { ...init, headers })
  }

  async logout(): Promise<void> {
    this.#tokens = null
    const results = await Promise.allSettled([
      this.#persistence.clear(),
      session.fromPartition(this.#partition).clearStorageData({ storages: ['cookies'] }),
    ])
    const failure = results.find(
      (result): result is PromiseRejectedResult => result.status === 'rejected',
    )
    if (failure) throw failure.reason
  }

  #assertConfigured(): void {
    if (!this.#clientId || !this.#clientSecret) {
      throw new EpicAuthError('EPIC_CONFIGURATION_MISSING')
    }
  }

  async #exchange(fields: Record<string, string>): Promise<void> {
    const controller = new AbortController()
    const timer = setTimeout(() => controller.abort(), this.#requestTimeoutMs)
    try {
      const credentials = Buffer.from(`${this.#clientId}:${this.#clientSecret}`, 'utf8').toString(
        'base64',
      )
      const response = await this.#fetch(TOKEN_ENDPOINT, {
        method: 'POST',
        signal: controller.signal,
        headers: {
          Authorization: `Basic ${credentials}`,
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': EPIC_LAUNCHER_USER_AGENT,
        },
        body: new URLSearchParams(fields),
      })
      if (!response.ok) throw new EpicAuthError('EPIC_LOGIN_FAILED')
      let decoded: unknown
      try {
        decoded = await response.json()
      } catch (error) {
        throw new EpicAuthError('EPIC_LOGIN_FAILED', { cause: error })
      }
      const tokens = parseTokenResponse(decoded, this.#now())
      if (!tokens) throw new EpicAuthError('EPIC_LOGIN_FAILED')

      const encrypted = this.#cipher.encrypt(JSON.stringify(tokens))
      await this.#persistence.save(encrypted)
      this.#tokens = tokens
    } catch (error) {
      if (error instanceof EpicAuthError) throw error
      throw new EpicAuthError('EPIC_LOGIN_FAILED', { cause: error })
    } finally {
      clearTimeout(timer)
    }
  }

  async #captureAuthorizationCode(): Promise<string> {
    const redirectUrl = new URL(REDIRECT_PATH, LOGIN_ORIGIN)
    redirectUrl.searchParams.set('clientId', this.#clientId)
    redirectUrl.searchParams.set('responseType', 'code')
    const loginUrl = new URL(LOGIN_PATH, LOGIN_ORIGIN)
    loginUrl.searchParams.set('redirectUrl', redirectUrl.toString())

    const window = this.#createWindow(this.#partition)
    window.webContents.setWindowOpenHandler(() => ({ action: 'deny' }))

    let settled = false
    let resolveCode!: (code: string) => void
    let rejectCode!: (error: Error) => void
    const codePromise = new Promise<string>((resolve, reject) => {
      resolveCode = resolve
      rejectCode = reject
    })
    const finish = (code: string | null, error?: EpicAuthError) => {
      if (settled) return
      settled = true
      clearTimeout(timer)
      if (code) resolveCode(code)
      else rejectCode(error ?? new EpicAuthError('EPIC_LOGIN_CANCELLED'))
      if (!window.isDestroyed()) window.close()
    }

    const inspectUrl = (rawUrl: string) => {
      let target: URL
      try {
        target = new URL(rawUrl)
      } catch {
        return
      }
      if (target.origin !== LOGIN_ORIGIN || target.pathname !== REDIRECT_PATH) return
      const code = target.searchParams.get('code') ?? target.searchParams.get('authorizationCode')
      if (code?.trim()) finish(code)
    }

    const allowNavigation = (event: { preventDefault(): void }, rawUrl: string) => {
      try {
        if ((EPIC_AUTH_ORIGINS as readonly string[]).includes(new URL(rawUrl).origin)) return
      } catch {
        // Invalid and non-HTTP navigation is denied below.
      }
      event.preventDefault()
    }

    window.webContents.on('will-navigate', allowNavigation)
    window.webContents.on('will-redirect', allowNavigation)
    window.webContents.on('did-navigate', (_event, url) => inspectUrl(url))
    window.webContents.on('did-redirect-navigation', (_event, url) => inspectUrl(url))
    window.webContents.on('did-finish-load', () => {
      try {
        const current = new URL(window.webContents.getURL())
        if (current.origin !== LOGIN_ORIGIN || current.pathname !== REDIRECT_PATH) return
      } catch {
        return
      }
      void window.webContents
        .executeJavaScript('document.body.innerText', false)
        .then((body) => {
          if (settled || typeof body !== 'string') return
          try {
            const decoded: unknown = JSON.parse(body)
            if (!isRecord(decoded)) return
            const code =
              readNonEmptyString(decoded.authorizationCode) ?? readNonEmptyString(decoded.code)
            if (code) finish(code)
          } catch {
            // The expected redirect can carry the code in its URL instead.
          }
        })
        .catch(() => undefined)
    })
    window.on('closed', () => finish(null))

    const timer = setTimeout(
      () => finish(null, new EpicAuthError('EPIC_LOGIN_TIMEOUT')),
      this.#loginTimeoutMs,
    )
    try {
      await window.loadURL(loginUrl.toString())
    } catch (error) {
      finish(null, new EpicAuthError('EPIC_LOGIN_FAILED', { cause: error }))
    }
    return codePromise
  }
}
