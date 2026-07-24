import { LocalManifestAccessError, type LocalManifestScanner } from '../manifests/scanner'
import type { ManifestCache } from '../storage'
import { uploadManifestWithCache } from './cached-client'
import type { LocalUploadOptions, UploadResult } from './types'

export class LocalManifestUploadService {
  constructor(
    private readonly scanner: LocalManifestScanner,
    private readonly options: Omit<LocalUploadOptions, 'signal'>,
    private readonly cache: ManifestCache,
  ) {}

  async uploadOne(sessionId: string, itemId: string, signal?: AbortSignal): Promise<UploadResult> {
    try {
      const payload = await this.scanner.getUploadPayload(sessionId, itemId)
      return uploadManifestWithCache(
        payload,
        {
          ...this.options,
          ...(signal ? { signal } : {}),
        },
        this.cache,
      )
    } catch (error) {
      if (error instanceof LocalManifestAccessError) {
        return {
          itemId,
          state: 'failed',
          message: error.message,
          errorCode:
            error.code === 'LOCAL_ITEM_PERMISSION_DENIED'
              ? 'LOCAL_ITEM_PERMISSION_DENIED'
              : 'LOCAL_BINARY_MANIFEST_MISSING',
        }
      }
      return {
        itemId,
        state: 'failed',
        message: 'The local manifest scan is no longer available.',
        errorCode: 'LOCAL_BINARY_MANIFEST_MISSING',
      }
    }
  }

  async uploadAll(
    sessionId: string,
    options: {
      signal?: AbortSignal
      onProgress?: (result: UploadResult) => void
    } = {},
  ): Promise<UploadResult[]> {
    const itemIds = this.scanner.getSessionItemIds(sessionId)
    const results: UploadResult[] = []
    for (const itemId of itemIds) {
      const result = await this.uploadOne(sessionId, itemId, options.signal)
      results.push(result)
      options.onProgress?.(result)
    }
    return results
  }
}
