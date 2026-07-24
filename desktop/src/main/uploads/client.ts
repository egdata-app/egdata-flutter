import { createHash } from 'node:crypto'

import { buildLocalManifestMultipart } from './multipart'
import { classifyUploadResponse } from './response'
import type { LocalManifestUploadPayload, LocalUploadOptions, UploadResult } from './types'

export const DEFAULT_LOCAL_UPLOAD_ENDPOINT =
  'https://egdata-builds-api.snpm.workers.dev/upload-manifest'

export function manifestContentHash(manifestBytes: Uint8Array): string {
  return createHash('sha256').update(manifestBytes).digest('hex')
}

async function boundedResponseText(response: Response): Promise<string> {
  const reader = response.body?.getReader()
  if (!reader) return (await response.text()).slice(0, 4096)

  const chunks: Uint8Array[] = []
  let total = 0
  while (total <= 4096) {
    const next = await reader.read()
    if (next.done) break
    const value: unknown = next.value
    if (!(value instanceof Uint8Array)) {
      await reader.cancel()
      break
    }
    const remaining = 4097 - total
    const chunk = value.subarray(0, remaining)
    chunks.push(chunk)
    total += chunk.byteLength
    if (total > 4096) {
      await reader.cancel()
      break
    }
  }
  return new TextDecoder()
    .decode(Buffer.concat(chunks.map((chunk) => Buffer.from(chunk))))
    .slice(0, 4096)
}

export async function uploadLocalManifest(
  payload: LocalManifestUploadPayload,
  options: LocalUploadOptions,
): Promise<UploadResult> {
  const contentHash = manifestContentHash(payload.manifestBytes)
  let multipart
  try {
    multipart = buildLocalManifestMultipart(payload, options.platform)
  } catch {
    return {
      itemId: payload.itemId,
      state: 'failed',
      message: 'The manifest upload could not be prepared.',
      errorCode: 'UPLOAD_REJECTED',
      contentHash,
    }
  }
  const controller = new AbortController()
  let timedOut = false
  const abortFromCaller = () => controller.abort(options.signal?.reason)
  if (options.signal?.aborted) abortFromCaller()
  else options.signal?.addEventListener('abort', abortFromCaller, { once: true })

  const timeoutMs = Math.max(1, options.timeoutMs ?? 30_000)
  const timeout = setTimeout(() => {
    timedOut = true
    controller.abort(new Error('upload timeout'))
  }, timeoutMs)

  try {
    const fetchImpl = options.fetchImpl ?? fetch
    const requestBody = new Uint8Array(multipart.body.byteLength)
    requestBody.set(multipart.body)
    const response = await fetchImpl(options.endpoint ?? DEFAULT_LOCAL_UPLOAD_ENDPOINT, {
      method: 'POST',
      headers: {
        'content-type': multipart.contentType,
        'content-length': String(multipart.contentLength),
      },
      body: requestBody,
      signal: controller.signal,
    })
    const bodyText = await boundedResponseText(response)
    return { ...classifyUploadResponse(payload.itemId, response.status, bodyText), contentHash }
  } catch {
    if (timedOut) {
      return {
        itemId: payload.itemId,
        state: 'failed',
        message: 'The manifest upload timed out.',
        errorCode: 'UPLOAD_TIMEOUT',
        contentHash,
      }
    }
    if (options.signal?.aborted) {
      return {
        itemId: payload.itemId,
        state: 'cancelled',
        message: 'The manifest upload was cancelled.',
        errorCode: 'SYNC_CANCELLED',
        contentHash,
      }
    }
    return {
      itemId: payload.itemId,
      state: 'failed',
      message: 'The manifest upload could not reach the service.',
      errorCode: 'UPLOAD_REJECTED',
      contentHash,
    }
  } finally {
    clearTimeout(timeout)
    options.signal?.removeEventListener('abort', abortFromCaller)
  }
}
