import { randomUUID } from 'node:crypto'

import type { LocalManifestPlatform } from '../manifests/types'
import type { LocalManifestUploadPayload, MultipartUpload } from './types'

function safeManifestFilename(payload: LocalManifestUploadPayload): string {
  const supplied = payload.manifestFileName?.toLowerCase().endsWith('.manifest')
    ? payload.manifestFileName
    : `${payload.installationGuid || payload.itemId}.manifest`
  const sanitized = supplied.replace(/[^a-zA-Z0-9._-]/g, '_')
  return sanitized && sanitized !== '.manifest' ? sanitized : `${payload.itemId}.manifest`
}

function partHeader(name: string, filename?: string): Buffer {
  const disposition = filename
    ? `Content-Disposition: form-data; name="${name}"; filename="${filename}"\r\nContent-Type: application/octet-stream`
    : `Content-Disposition: form-data; name="${name}"`
  return Buffer.from(`${disposition}\r\n\r\n`, 'utf8')
}

export function buildLocalManifestMultipart(
  payload: LocalManifestUploadPayload,
  platform: LocalManifestPlatform,
  suppliedBoundary?: string,
): MultipartUpload {
  const boundary = suppliedBoundary ?? `----egdata-${randomUUID()}`
  if (!/^[a-zA-Z0-9'-]{1,70}$/.test(boundary)) {
    throw new Error('Invalid multipart boundary')
  }

  const filename = safeManifestFilename(payload)
  const delimiter = Buffer.from(`--${boundary}\r\n`, 'ascii')
  const separator = Buffer.from('\r\n', 'ascii')
  const ending = Buffer.from(`--${boundary}--\r\n`, 'ascii')
  const body = Buffer.concat([
    delimiter,
    partHeader('item'),
    Buffer.from(payload.rawItemText, 'utf8'),
    separator,
    delimiter,
    partHeader('os'),
    Buffer.from(platform === 'win32' ? 'Windows' : 'Mac', 'ascii'),
    separator,
    delimiter,
    partHeader('manifest', filename),
    Buffer.from(payload.manifestBytes),
    separator,
    ending,
  ])

  return {
    body,
    contentType: `multipart/form-data; boundary=${boundary}`,
    contentLength: body.byteLength,
    filename,
  }
}
