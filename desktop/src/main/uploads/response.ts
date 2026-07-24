import type { UploadResult } from './types'

const UPLOADED_ALIASES = new Set(['uploaded', 'success', 'created', 'ok'])
const DUPLICATE_ALIASES = new Set(['already_uploaded', 'exists', 'duplicate'])
const FAILED_ALIASES = new Set(['failed', 'error'])

function safeString(value: unknown, maximum = 300): string | undefined {
  if (typeof value !== 'string') return undefined
  const compact = value
    .replace(/[\r\n\t]+/g, ' ')
    .trim()
    .slice(0, maximum)
  if (!compact) return undefined
  return compact
    .replace(
      /(authorization|access[_ -]?token|refresh[_ -]?token|cookie)\s*[:=]\s*\S+/gi,
      '$1=[redacted]',
    )
    .replace(/https?:\/\/\S+/gi, '[redacted-url]')
}

function responseFields(body: unknown): {
  status?: string
  message?: string
  manifestHash?: string
} | null {
  if (!body || typeof body !== 'object' || Array.isArray(body)) return null
  const value = body as Record<string, unknown>
  const status = safeString(value.status, 64)?.toLowerCase()
  const message = safeString(value.message)
  const manifestHash = safeString(value.manifest_hash, 128)
  return {
    ...(status ? { status } : {}),
    ...(message ? { message } : {}),
    ...(manifestHash ? { manifestHash } : {}),
  }
}

export function classifyUploadResponse(
  itemId: string,
  statusCode: number,
  bodyText: string,
): UploadResult {
  if (statusCode === 409) {
    return {
      itemId,
      state: 'already-uploaded',
      message: 'Manifest already exists.',
      statusCode,
    }
  }

  let decoded: unknown
  try {
    decoded = JSON.parse(bodyText)
  } catch {
    decoded = undefined
  }
  const fields = responseFields(decoded)

  if (statusCode === 200 || statusCode === 201) {
    if (!fields?.status) {
      return {
        itemId,
        state: 'failed',
        message: 'The upload service returned an invalid response.',
        statusCode,
        errorCode: 'UPLOAD_RESPONSE_INVALID',
      }
    }
    if (UPLOADED_ALIASES.has(fields.status)) {
      return {
        itemId,
        state: 'uploaded',
        message: fields.message ?? 'Manifest uploaded.',
        ...(fields.manifestHash ? { manifestHash: fields.manifestHash } : {}),
        statusCode,
      }
    }
    if (DUPLICATE_ALIASES.has(fields.status)) {
      return {
        itemId,
        state: 'already-uploaded',
        message: fields.message ?? 'Manifest already exists.',
        ...(fields.manifestHash ? { manifestHash: fields.manifestHash } : {}),
        statusCode,
      }
    }
    if (FAILED_ALIASES.has(fields.status)) {
      return {
        itemId,
        state: 'failed',
        message: fields.message ?? 'The upload service rejected the manifest.',
        statusCode,
        errorCode: 'UPLOAD_REJECTED',
      }
    }
    return {
      itemId,
      state: 'failed',
      message: 'The upload service returned an unknown status.',
      statusCode,
      errorCode: 'UPLOAD_RESPONSE_INVALID',
      safeDetail: `status=${fields.status}`,
    }
  }

  const safeDetail = fields
    ? [fields.status && `status=${fields.status}`, fields.message].filter(Boolean).join('; ') ||
      undefined
    : undefined
  return {
    itemId,
    state: 'failed',
    message: `Upload failed with HTTP status ${statusCode}.`,
    statusCode,
    errorCode: 'UPLOAD_REJECTED',
    ...(safeDetail ? { safeDetail } : {}),
  }
}
