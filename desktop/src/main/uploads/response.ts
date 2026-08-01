import type { AcceptedUploadJob, UploadResult } from './types'

const UPLOADED_ALIASES = new Set(['uploaded', 'success', 'created', 'ok'])
const DUPLICATE_ALIASES = new Set(['already_uploaded', 'exists', 'duplicate'])
const FAILED_ALIASES = new Set(['failed', 'error'])

function record(value: unknown): Record<string, unknown> | null {
  return value && typeof value === 'object' && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : null
}

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
  success?: boolean
  status?: string
  message?: string
  manifestHash?: string
  job?: AcceptedUploadJob
} | null {
  const value = record(body)
  if (!value) return null
  const data = record(value.data)
  const jobValue = record(data?.job) ?? record(value.job)
  const job =
    jobValue &&
    typeof jobValue.jobId === 'string' &&
    typeof jobValue.workflowId === 'string' &&
    typeof jobValue.statusUrl === 'string' &&
    typeof jobValue.deduplicated === 'boolean'
      ? {
          jobId: jobValue.jobId,
          workflowId: jobValue.workflowId,
          statusUrl: jobValue.statusUrl,
          deduplicated: jobValue.deduplicated,
        }
      : undefined
  const status = safeString(value.status, 64)?.toLowerCase()
  const message = safeString(value.message)
  const manifestHash =
    safeString(value.manifest_hash, 128) ??
    safeString(data?.manifest_hash, 128) ??
    safeString(data?.manifestHash, 128) ??
    safeString(data?.fileHash, 128)
  return {
    ...(value.success === true ? { success: true } : {}),
    ...(status ? { status } : {}),
    ...(message ? { message } : {}),
    ...(manifestHash ? { manifestHash } : {}),
    ...(job ? { job } : {}),
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
    if (fields?.success === true && fields.job) {
      return {
        itemId,
        state: 'uploaded',
        message: fields.message ?? 'Manifest uploaded.',
        ...(fields.manifestHash ? { manifestHash: fields.manifestHash } : {}),
        statusCode,
        job: fields.job,
      }
    }
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
