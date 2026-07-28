import { EpicAuthError } from '../auth/errors'
import type { EpicAuthorizedRequester } from '../auth/types'
import { EpicCloudError, type EpicCloudErrorCode } from './errors'

export interface TimedRequestOptions {
  timeoutMs: number
  signal?: AbortSignal | undefined
  failureCode: EpicCloudErrorCode
}

export async function timedOperation<T>(
  operation: (signal: AbortSignal) => Promise<T>,
  options: TimedRequestOptions,
): Promise<T> {
  const controller = new AbortController()
  const onAbort = () => controller.abort(options.signal?.reason)
  if (options.signal?.aborted) onAbort()
  else options.signal?.addEventListener('abort', onAbort, { once: true })

  const timer = setTimeout(() => {
    controller.abort()
  }, options.timeoutMs)

  try {
    return await operation(controller.signal)
  } catch (error) {
    if (error instanceof EpicCloudError) throw error
    if (options.signal?.aborted) throw new EpicCloudError('SYNC_CANCELLED', { cause: error })
    throw new EpicCloudError(options.failureCode, { cause: error })
  } finally {
    clearTimeout(timer)
    options.signal?.removeEventListener('abort', onAbort)
  }
}

export function timedFetch(
  fetcher: (signal: AbortSignal) => Promise<Response>,
  options: TimedRequestOptions,
): Promise<Response> {
  return timedOperation(fetcher, options)
}

export async function authorizedFetchWithOneRefresh(
  auth: EpicAuthorizedRequester,
  input: string | URL,
  init: RequestInit,
  options: TimedRequestOptions,
): Promise<Response> {
  if (!auth.isAuthenticated) throw new EpicCloudError('EPIC_NOT_AUTHENTICATED')

  const request = () =>
    timedFetch((signal) => auth.authorizedFetch(input, { ...init, signal }), options)
  let response = await request()
  if (response.status !== 401) return response

  try {
    await auth.refresh()
  } catch (error) {
    if (error instanceof EpicAuthError && error.code === 'EPIC_LOGIN_FAILED') {
      throw new EpicCloudError(options.failureCode, { cause: error })
    }
    if (error instanceof EpicAuthError && error.code === 'EPIC_SESSION_EXPIRED') {
      throw new EpicCloudError('EPIC_SESSION_EXPIRED', { cause: error })
    }
    await auth.logout().catch(() => undefined)
    throw new EpicCloudError('EPIC_SESSION_EXPIRED', { cause: error })
  }
  response = await request()
  if (response.status === 401) {
    await auth.logout().catch(() => undefined)
    throw new EpicCloudError('EPIC_SESSION_EXPIRED', { statusCode: 401 })
  }
  return response
}

export interface JsonResponseOptions extends TimedRequestOptions {
  maxBytes?: number
}

export function parseJson(
  response: Response,
  code: EpicCloudErrorCode,
  options: JsonResponseOptions,
): Promise<unknown> {
  return timedOperation(async (signal) => {
    const reader = response.body?.getReader()
    if (!reader) throw new EpicCloudError(code)
    const maxBytes = options.maxBytes ?? 5 * 1024 * 1024
    const chunks: Uint8Array[] = []
    let length = 0
    let completed = false
    const cancel = () => {
      void reader.cancel().catch(() => undefined)
    }
    signal.addEventListener('abort', cancel, { once: true })
    try {
      while (true) {
        const chunk = await reader.read()
        if (signal.aborted) throw new DOMException('Aborted', 'AbortError')
        if (chunk.done) {
          completed = true
          break
        }
        const value: unknown = chunk.value
        if (!(value instanceof Uint8Array)) throw new EpicCloudError(code)
        length += value.byteLength
        if (length > maxBytes) throw new EpicCloudError(code)
        chunks.push(value)
      }
    } finally {
      signal.removeEventListener('abort', cancel)
      if (!completed) void reader.cancel().catch(() => undefined)
    }

    const bytes = new Uint8Array(length)
    let offset = 0
    for (const chunk of chunks) {
      bytes.set(chunk, offset)
      offset += chunk.byteLength
    }
    try {
      return JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(bytes)) as unknown
    } catch (error) {
      throw new EpicCloudError(code, { cause: error })
    }
  }, options)
}
