export interface EpicAuthState {
  authenticated: boolean
  accountId: string | null
  expiresAt: string | null
}

export interface EpicAuthorizedRequester {
  readonly isAuthenticated: boolean
  authorizedFetch(input: string | URL, init?: RequestInit): Promise<Response>
  refresh(): Promise<void>
  logout(): Promise<void>
}

export interface AuthWindowWebContents {
  on(
    event: 'will-navigate' | 'will-redirect',
    listener: (event: { preventDefault(): void }, url: string) => void,
  ): this
  on(
    event: 'did-navigate' | 'did-redirect-navigation',
    listener: (event: unknown, url: string) => void,
  ): this
  on(event: 'did-finish-load', listener: () => void): this
  setWindowOpenHandler(handler: (details: { url: string }) => { action: 'deny' }): void
  getURL(): string
  executeJavaScript(script: string, userGesture?: boolean): Promise<unknown>
}

export interface AuthWindow {
  readonly webContents: AuthWindowWebContents
  on(event: 'closed', listener: () => void): this
  loadURL(url: string): Promise<void>
  close(): void
  isDestroyed(): boolean
}

export type AuthWindowFactory = (partition: string) => AuthWindow
