import { once } from 'node:events'
import { mkdtemp, rm } from 'node:fs/promises'
import { createServer, type IncomingMessage, type ServerResponse } from 'node:http'
import { join } from 'node:path'
import { tmpdir } from 'node:os'

import { afterEach, describe, expect, it } from 'vitest'

import type { LocalManifestUploadPayload } from '../../src/main/manifests/types'
import { ManifestCache } from '../../src/main/storage'
import {
  LocalManifestUploadService,
  manifestContentHash,
  uploadLocalManifest,
} from '../../src/main/uploads/index'

const servers: ReturnType<typeof createServer>[] = []
const manifestCaches: ManifestCache[] = []
const temporaryDirectories: string[] = []

afterEach(async () => {
  for (const cache of manifestCaches.splice(0)) cache.close()
  await Promise.all(
    servers
      .splice(0)
      .map((server) => new Promise<void>((resolve) => server.close(() => resolve()))),
  )
  await Promise.all(
    temporaryDirectories.splice(0).map((directory) =>
      rm(directory, {
        recursive: true,
        force: true,
      }),
    ),
  )
})

async function bodyOf(request: IncomingMessage): Promise<Buffer> {
  const chunks: Buffer[] = []
  for await (const chunk of request) chunks.push(Buffer.from(chunk as Uint8Array))
  return Buffer.concat(chunks)
}

function multipartPart(body: Buffer, boundary: string, name: string): Buffer {
  const markerAt = body.indexOf(Buffer.from(`name="${name}"`))
  expect(markerAt).toBeGreaterThan(-1)
  const valueAt = body.indexOf(Buffer.from('\r\n\r\n'), markerAt) + 4
  const valueEnd = body.indexOf(Buffer.from(`\r\n--${boundary}`), valueAt)
  return body.subarray(valueAt, valueEnd)
}

async function listeningServer(
  handler: (request: IncomingMessage, response: ServerResponse) => void | Promise<void>,
): Promise<{ endpoint: string }> {
  const server = createServer((request, response) => {
    void handler(request, response)
  })
  servers.push(server)
  server.listen(0, '127.0.0.1')
  await once(server, 'listening')
  const address = server.address()
  if (!address || typeof address === 'string') throw new Error('No test server address')
  return { endpoint: `http://127.0.0.1:${address.port}/upload-manifest` }
}

describe('local multipart upload', () => {
  it('transmits original item text, OS, and binary bytes unchanged', async () => {
    const originalText = '{\r\n  "Unknown": "  preserve  ",\r\n  "Number": 1\r\n}\r\n'
    const originalBytes = Buffer.from([0x00, 0x01, 0x0a, 0x0d, 0x7f, 0x80, 0xff])
    let received: Buffer | undefined
    let contentType = ''
    const { endpoint } = await listeningServer(async (request, response) => {
      contentType = String(request.headers['content-type'])
      received = await bodyOf(request)
      response.writeHead(201, { 'content-type': 'application/json' })
      response.end(JSON.stringify({ status: 'created' }))
    })

    const result = await uploadLocalManifest(
      {
        itemId: 'opaque-id',
        rawItemText: originalText,
        manifestBytes: originalBytes,
        manifestFileName: 'source name.manifest',
        installationGuid: 'guid',
      },
      { platform: 'win32', endpoint },
    )

    expect(result.state).toBe('uploaded')
    expect(result.contentHash).toBe(manifestContentHash(originalBytes))
    const boundary = /boundary=([^;]+)/.exec(contentType)?.[1]
    expect(boundary).toBeTruthy()
    expect(multipartPart(received!, boundary!, 'item')).toEqual(Buffer.from(originalText))
    expect(multipartPart(received!, boundary!, 'os').toString()).toBe('Windows')
    expect(multipartPart(received!, boundary!, 'manifest')).toEqual(originalBytes)
    expect(received!.toString('latin1')).toContain('filename="source_name.manifest"')
    expect(received!.toString('latin1')).toContain('Content-Type: application/octet-stream')
  })

  it('supports caller cancellation and bounded timeouts', async () => {
    const { endpoint } = await listeningServer(() => {})
    const payload: LocalManifestUploadPayload = {
      itemId: 'opaque-id',
      rawItemText: '{}',
      manifestBytes: new Uint8Array([1]),
      installationGuid: 'guid',
    }

    const timeout = await uploadLocalManifest(payload, {
      platform: 'darwin',
      endpoint,
      timeoutMs: 20,
    })
    expect(timeout.errorCode).toBe('UPLOAD_TIMEOUT')

    const controller = new AbortController()
    const upload = uploadLocalManifest(payload, {
      platform: 'darwin',
      endpoint,
      signal: controller.signal,
    })
    controller.abort()
    expect((await upload).state).toBe('cancelled')
  })

  it('upload-all uses every session source id rather than group representatives', async () => {
    const requested: string[] = []
    const scanner = {
      getSessionItemIds: () => ['base-id', 'addon-id'],
      getUploadPayload: (_sessionId: string, itemId: string) => {
        requested.push(itemId)
        return Promise.resolve({
          itemId,
          rawItemText: JSON.stringify({ InstallationGuid: itemId }),
          manifestBytes: new Uint8Array([1, 2, 3]),
          installationGuid: itemId,
        })
      },
    }
    const { endpoint } = await listeningServer(async (request, response) => {
      await bodyOf(request)
      response.writeHead(200, { 'content-type': 'application/json' })
      response.end(JSON.stringify({ status: 'uploaded' }))
    })
    const service = new LocalManifestUploadService(
      scanner as ConstructorParameters<typeof LocalManifestUploadService>[0],
      { platform: 'win32', endpoint },
      await createManifestCache(),
    )

    const results = await service.uploadAll('session')
    expect(requested).toEqual(['base-id', 'addon-id'])
    expect(results).toHaveLength(2)
    expect(results.map((result) => result.state)).toEqual(['uploaded', 'already-uploaded'])
  })
})

async function createManifestCache(): Promise<ManifestCache> {
  const directory = await mkdtemp(join(tmpdir(), 'egdata-manifest-cache-'))
  temporaryDirectories.push(directory)
  const cache = new ManifestCache(join(directory, 'cache.sqlite'))
  await cache.initialize()
  manifestCaches.push(cache)
  return cache
}
