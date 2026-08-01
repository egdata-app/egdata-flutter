import type { LocalManifestUploadPayload } from '../manifests/types'

export type UploadResultState = 'uploaded' | 'already-uploaded' | 'failed' | 'cancelled'

export type UploadErrorCode =
  | 'UPLOAD_TIMEOUT'
  | 'UPLOAD_REJECTED'
  | 'UPLOAD_RESPONSE_INVALID'
  | 'SYNC_CANCELLED'
  | 'LOCAL_BINARY_MANIFEST_MISSING'
  | 'LOCAL_ITEM_PERMISSION_DENIED'

export interface AcceptedUploadJob {
  jobId: string
  workflowId: string
  statusUrl: string
  deduplicated: boolean
}

export interface UploadResult {
  itemId: string
  state: UploadResultState
  message: string
  /** SHA-256 of the opaque manifest bytes, for cache lookup and diagnostics. */
  contentHash?: string
  manifestHash?: string
  statusCode?: number
  errorCode?: UploadErrorCode
  safeDetail?: string
  job?: AcceptedUploadJob
}

export interface LocalUploadOptions {
  platform: 'win32' | 'darwin'
  endpoint?: string
  timeoutMs?: number
  signal?: AbortSignal
  fetchImpl?: typeof fetch
}

export interface MultipartUpload {
  body: Buffer
  contentType: string
  contentLength: number
  filename: string
}

export type { LocalManifestUploadPayload }
