export type EpicCloudErrorCode =
  | 'EPIC_NOT_AUTHENTICATED'
  | 'EPIC_SESSION_EXPIRED'
  | 'EPIC_LIBRARY_REQUEST_FAILED'
  | 'EPIC_LIBRARY_RESPONSE_INVALID'
  | 'EPIC_LIBRARY_PAGINATION_INVALID'
  | 'EPIC_MANIFEST_REQUEST_FAILED'
  | 'EPIC_MANIFEST_RESPONSE_INVALID'
  | 'EPIC_MANIFEST_DOWNLOAD_FAILED'
  | 'SYNC_CANCELLED'

const messages: Record<EpicCloudErrorCode, string> = {
  EPIC_NOT_AUTHENTICATED: 'Epic sign-in is required.',
  EPIC_SESSION_EXPIRED: 'The Epic session has expired.',
  EPIC_LIBRARY_REQUEST_FAILED: 'The Epic library could not be loaded.',
  EPIC_LIBRARY_RESPONSE_INVALID: 'Epic returned an invalid library response.',
  EPIC_LIBRARY_PAGINATION_INVALID: 'Epic returned invalid library pagination.',
  EPIC_MANIFEST_REQUEST_FAILED: 'Manifest information could not be loaded.',
  EPIC_MANIFEST_RESPONSE_INVALID: 'Epic returned invalid manifest information.',
  EPIC_MANIFEST_DOWNLOAD_FAILED: 'The cloud manifest could not be downloaded.',
  SYNC_CANCELLED: 'Cloud sync was cancelled.',
}

export class EpicCloudError extends Error {
  readonly code: EpicCloudErrorCode
  readonly statusCode: number | undefined

  constructor(code: EpicCloudErrorCode, options?: { statusCode?: number; cause?: unknown }) {
    super(messages[code], options?.cause === undefined ? undefined : { cause: options.cause })
    this.name = 'EpicCloudError'
    this.code = code
    this.statusCode = options?.statusCode
  }
}
