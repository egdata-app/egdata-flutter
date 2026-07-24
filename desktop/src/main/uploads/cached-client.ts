import type { LocalManifestUploadPayload } from '../manifests/types'
import type { ManifestCache } from '../storage'
import { manifestContentHash, uploadLocalManifest } from './client'
import type { LocalUploadOptions, UploadResult } from './types'

export async function uploadManifestWithCache(
  payload: LocalManifestUploadPayload,
  options: LocalUploadOptions,
  cache: ManifestCache,
): Promise<UploadResult> {
  const contentHash = manifestContentHash(payload.manifestBytes)

  try {
    const known = cache.find(contentHash)
    if (known) {
      return {
        itemId: payload.itemId,
        state: 'already-uploaded',
        message: 'Manifest already confirmed by egdata.app.',
        contentHash,
        ...(known.serverManifestHash ? { manifestHash: known.serverManifestHash } : {}),
      }
    }
  } catch {
    // A cache problem must not prevent a contribution attempt.
  }

  const result = await uploadLocalManifest(payload, options)
  if (result.state === 'uploaded' || result.state === 'already-uploaded') {
    try {
      cache.confirm(contentHash, result.state, result.manifestHash)
    } catch {
      // The server result remains authoritative even if the local cache cannot be updated.
    }
  }
  return result
}
