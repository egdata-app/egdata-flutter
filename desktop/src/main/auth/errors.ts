export type EpicAuthErrorCode =
  | 'EPIC_CONFIGURATION_MISSING'
  | 'EPIC_LOGIN_CANCELLED'
  | 'EPIC_LOGIN_TIMEOUT'
  | 'EPIC_LOGIN_FAILED'
  | 'EPIC_SESSION_EXPIRED'
  | 'EPIC_NOT_AUTHENTICATED'

const messages: Record<EpicAuthErrorCode, string> = {
  EPIC_CONFIGURATION_MISSING: 'Epic authentication is not configured.',
  EPIC_LOGIN_CANCELLED: 'Epic sign-in was cancelled.',
  EPIC_LOGIN_TIMEOUT: 'Epic sign-in timed out.',
  EPIC_LOGIN_FAILED: 'Epic sign-in failed.',
  EPIC_SESSION_EXPIRED: 'The Epic session has expired.',
  EPIC_NOT_AUTHENTICATED: 'Epic sign-in is required.',
}

export class EpicAuthError extends Error {
  readonly code: EpicAuthErrorCode

  constructor(code: EpicAuthErrorCode, options?: ErrorOptions) {
    super(messages[code], options)
    this.name = 'EpicAuthError'
    this.code = code
  }
}
