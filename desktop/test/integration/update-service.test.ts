import { createHash } from 'node:crypto'
import { mkdir, readFile, writeFile } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'

import { afterEach, describe, expect, test, vi } from 'vitest'

import { UpdateService, selectBetaRelease } from '../../src/main/updates'

const temporaryDirectories: string[] = []

afterEach(async () => {
  await Promise.all(
    temporaryDirectories.splice(0).map(async (directory) => {
      const { rm } = await import('node:fs/promises')
      await rm(directory, { recursive: true, force: true })
    }),
  )
})

describe('GitHub update release selection', () => {
  test('selects the highest valid stable or prerelease for the beta channel', () => {
    const selected = selectBetaRelease([
      release('1.5.0-beta.1', { prerelease: true }),
      release('invalid', { draft: false }),
      release('2.0.0-beta.1', { draft: true, prerelease: true }),
      release('1.4.2'),
      release('1.5.0-beta.3', { prerelease: true }),
    ])

    expect(selected.version).toBe('1.5.0-beta.3')
  })
})

describe('UpdateService', () => {
  test('checks stable releases with versioned GitHub headers and never downgrades', async () => {
    const requests: Array<{ url: string; headers: Headers }> = []
    const service = await createService({
      currentVersion: '1.4.0',
      isPackaged: false,
      fetcher: async (input, init) => {
        requests.push({
          url: requestUrl(input),
          headers: new Headers(init?.headers),
        })
        return jsonResponse(release('1.3.0'))
      },
    })

    await expect(service.instance.check()).resolves.toMatchObject({
      state: 'not-available',
      currentVersion: '1.4.0',
      channel: 'stable',
      delivery: 'manual',
    })
    expect(requests[0]?.url).toBe(
      'https://api.github.com/repos/egdata-app/egdata-flutter/releases/latest',
    )
    expect(requests[0]?.headers.get('x-github-api-version')).toBe('2026-03-10')
    expect(requests[0]?.headers.get('user-agent')).toBe('egdata.app/1.4.0')
  })

  test('uses the release list for beta and selects a newer prerelease', async () => {
    const service = await createService({
      currentVersion: '1.4.0',
      channel: 'beta',
      isPackaged: false,
      fetcher: async (input) => {
        expect(requestUrl(input)).toContain('/releases?per_page=20')
        return jsonResponse([
          release('1.4.1'),
          release('1.5.0-beta.2', { prerelease: true }),
          release('1.5.0-beta.1', { prerelease: true }),
        ])
      },
    })

    await expect(service.instance.check()).resolves.toMatchObject({
      state: 'available',
      availableVersion: '1.5.0-beta.2',
      channel: 'beta',
      delivery: 'manual',
    })
  })

  test('automatically downloads, verifies, caches, and reuses a Windows installer', async () => {
    const installer = Buffer.from('verified Windows installer fixture')
    const fixture = releaseWithInstaller('1.4.0', installer)
    let installerRequests = 0
    const statuses: string[] = []
    const service = await createService({
      currentVersion: '1.3.0',
      isPackaged: true,
      onStatus: (status) => statuses.push(status.state),
      fetcher: async (input) => {
        const url = requestUrl(input)
        if (url.includes('/releases/latest')) return jsonResponse(fixture.release)
        if (url.endsWith('.sha256')) return byteResponse(fixture.checksum)
        if (url.endsWith('.exe')) {
          installerRequests += 1
          return byteResponse(installer)
        }
        return new Response(null, { status: 404 })
      },
    })
    const staleDirectory = join(service.userData, 'updates', '1.2.0')
    await mkdir(staleDirectory, { recursive: true })
    await writeFile(join(staleDirectory, 'old.partial'), 'old')

    await service.instance.check()
    await expect(service.instance.download()).resolves.toMatchObject({
      state: 'downloaded',
      availableVersion: '1.4.0',
      progressPercent: 100,
    })
    const installerPath = join(service.userData, 'updates', '1.4.0', 'egdata-app-1.4.0-setup.exe')
    await expect(readFile(installerPath)).resolves.toEqual(installer)
    await expect(readFile(join(staleDirectory, 'old.partial'))).rejects.toMatchObject({
      code: 'ENOENT',
    })
    expect(statuses).toContain('downloading')
    expect(statuses).toContain('downloaded')

    await service.instance.check()
    await service.instance.download()
    expect(installerRequests).toBe(1)
  })

  test('fails closed when the checksum and GitHub digest disagree', async () => {
    const installer = Buffer.from('installer')
    const fixture = releaseWithInstaller('1.4.0', installer)
    fixture.release.assets[0]!.digest = `sha256:${'0'.repeat(64)}`
    const service = await createService({
      currentVersion: '1.3.0',
      isPackaged: true,
      fetcher: async (input) => {
        const url = requestUrl(input)
        if (url.includes('/releases/latest')) return jsonResponse(fixture.release)
        if (url.endsWith('.sha256')) return byteResponse(fixture.checksum)
        return byteResponse(installer)
      },
    })

    await service.instance.check()
    await expect(service.instance.download()).resolves.toMatchObject({
      state: 'error',
      availableVersion: '1.4.0',
      message: 'The published installer checksums do not agree.',
    })
  })

  test('bounds GitHub metadata responses', async () => {
    const service = await createService({
      currentVersion: '1.3.0',
      isPackaged: false,
      fetcher: async () => new Response('x'.repeat(1024 * 1024 + 1)),
    })

    await expect(service.instance.check()).resolves.toMatchObject({
      state: 'error',
      message: 'The GitHub update service could not be reached.',
    })
  })

  test('removes a partial installer when a download is interrupted', async () => {
    const installer = Buffer.from('an installer that will be interrupted')
    const fixture = releaseWithInstaller('1.4.0', installer)
    const service = await createService({
      currentVersion: '1.3.0',
      isPackaged: true,
      fetcher: async (input) => {
        const url = requestUrl(input)
        if (url.includes('/releases/latest')) return jsonResponse(fixture.release)
        if (url.endsWith('.sha256')) return byteResponse(fixture.checksum)
        const body = new ReadableStream<Uint8Array>({
          start(controller) {
            controller.enqueue(new Uint8Array(installer.subarray(0, 5)))
            controller.error(new Error('connection lost'))
          },
        })
        return new Response(body, {
          status: 200,
          headers: { 'content-length': String(installer.byteLength) },
        })
      },
    })

    await service.instance.check()
    await expect(service.instance.download()).resolves.toMatchObject({ state: 'error' })
    const partial = join(
      service.userData,
      'updates',
      '1.4.0',
      `egdata-app-1.4.0-setup.exe.${process.pid}.partial`,
    )
    await expect(readFile(partial)).rejects.toMatchObject({ code: 'ENOENT' })
  })

  test('keeps packaged macOS updates as manual GitHub downloads', async () => {
    const service = await createService({
      currentVersion: '1.3.0',
      platform: 'darwin',
      isPackaged: true,
      fetcher: async () => jsonResponse(release('1.4.0')),
    })

    await expect(service.instance.check()).resolves.toMatchObject({
      state: 'available',
      availableVersion: '1.4.0',
      delivery: 'manual',
    })
  })

  test('requires confirmation, cancels work, re-verifies, and launches the installer', async () => {
    let busy = true
    const barriers: boolean[] = []
    const opened: string[] = []
    const quit = vi.fn()
    const installer = Buffer.from('installer ready to launch')
    const fixture = releaseWithInstaller('1.4.0', installer)
    const service = await createService({
      currentVersion: '1.3.0',
      isPackaged: true,
      fetcher: releaseFetcher(fixture, installer),
      manifestWorkIsBusy: () => busy,
      cancelManifestWork: async () => {
        busy = false
      },
      setInstallBarrier: (active) => barriers.push(active),
      openPath: async (filePath) => {
        opened.push(filePath)
        return ''
      },
      quit,
    })
    await service.instance.check()
    await service.instance.download()

    await expect(service.instance.install(false)).resolves.toEqual({
      outcome: 'confirmation-required',
    })
    await expect(service.instance.install(true)).resolves.toEqual({ outcome: 'started' })
    await new Promise<void>((resolve) => setTimeout(resolve, 0))

    expect(barriers).toEqual([true])
    expect(opened[0]).toMatch(/egdata-app-1\.4\.0-setup\.exe$/)
    expect(quit).toHaveBeenCalledOnce()
  })

  test('restores the install barrier when Windows cannot launch the installer', async () => {
    const barriers: boolean[] = []
    const installer = Buffer.from('installer launch failure')
    const fixture = releaseWithInstaller('1.4.0', installer)
    const service = await createService({
      currentVersion: '1.3.0',
      isPackaged: true,
      fetcher: releaseFetcher(fixture, installer),
      setInstallBarrier: (active) => barriers.push(active),
      openPath: async () => 'Access denied',
    })
    await service.instance.check()
    await service.instance.download()

    await expect(service.instance.install(false)).rejects.toThrow(
      'Windows could not start the update installer.',
    )
    expect(barriers).toEqual([true, false])
    expect(service.instance.status).toMatchObject({
      state: 'downloaded',
      error: { retryable: true },
    })
  })

  test('re-verifies the installer immediately before launch', async () => {
    const barriers: boolean[] = []
    const installer = Buffer.from('installer integrity fixture')
    const fixture = releaseWithInstaller('1.4.0', installer)
    const service = await createService({
      currentVersion: '1.3.0',
      isPackaged: true,
      fetcher: releaseFetcher(fixture, installer),
      setInstallBarrier: (active) => barriers.push(active),
    })
    await service.instance.check()
    await service.instance.download()
    const installerPath = join(service.userData, 'updates', '1.4.0', 'egdata-app-1.4.0-setup.exe')
    await writeFile(installerPath, Buffer.alloc(installer.byteLength, 1))

    await expect(service.instance.install(false)).rejects.toThrow(
      'The update installer changed after it was downloaded.',
    )
    expect(barriers).toEqual([true, false])
  })

  test('leaves AppX updates to Microsoft Store without contacting GitHub', async () => {
    const fetcher = vi.fn<typeof fetch>()
    const service = await createService({
      currentVersion: '1.3.0',
      windowsStore: true,
      isPackaged: true,
      fetcher,
    })

    await expect(service.instance.check()).resolves.toMatchObject({
      state: 'idle',
      delivery: 'store',
      message: 'Updates for this installation are delivered by Microsoft Store.',
    })
    expect(fetcher).not.toHaveBeenCalled()
  })
})

interface MutableAsset {
  id: number
  name: string
  state: 'uploaded'
  size: number
  digest: string
  browser_download_url: string
}

interface MutableRelease {
  id: number
  tag_name: string
  html_url: string
  draft: boolean
  prerelease: boolean
  assets: MutableAsset[]
}

function release(
  version: string,
  overrides: Partial<Pick<MutableRelease, 'draft' | 'prerelease'>> = {},
): MutableRelease {
  return {
    id: Math.max(1, version.length),
    tag_name: version === 'invalid' ? version : `v${version}`,
    html_url: `https://github.com/egdata-app/egdata-flutter/releases/tag/v${version}`,
    draft: overrides.draft ?? false,
    prerelease: overrides.prerelease ?? false,
    assets: [],
  }
}

function releaseWithInstaller(version: string, installer: Buffer) {
  const installerName = `egdata-app-${version}-setup.exe`
  const hash = digest(installer)
  const checksum = Buffer.from(`${hash}  ${installerName}\n`)
  const value = release(version)
  value.assets = [
    asset(value.tag_name, installerName, installer, 1),
    asset(value.tag_name, `${installerName}.sha256`, checksum, 2),
  ]
  return { release: value, checksum }
}

function asset(tag: string, name: string, contents: Buffer, id: number): MutableAsset {
  return {
    id,
    name,
    state: 'uploaded',
    size: contents.byteLength,
    digest: `sha256:${digest(contents)}`,
    browser_download_url: `https://github.com/egdata-app/egdata-flutter/releases/download/${tag}/${name}`,
  }
}

function releaseFetcher(fixture: ReturnType<typeof releaseWithInstaller>, installer: Buffer) {
  return async (input: string | URL | Request) => {
    const url = requestUrl(input)
    if (url.includes('/releases/latest')) return jsonResponse(fixture.release)
    if (url.endsWith('.sha256')) return byteResponse(fixture.checksum)
    if (url.endsWith('.exe')) return byteResponse(installer)
    return new Response(null, { status: 404 })
  }
}

async function createService(options: {
  currentVersion: string
  channel?: 'stable' | 'beta'
  platform?: NodeJS.Platform
  windowsStore?: boolean
  isPackaged: boolean
  fetcher: typeof fetch
  onStatus?: ConstructorParameters<typeof UpdateService>[0]['onStatus']
  manifestWorkIsBusy?: () => boolean
  cancelManifestWork?: () => Promise<void>
  setInstallBarrier?: (active: boolean) => void
  openPath?: (filePath: string) => Promise<string>
  quit?: () => void
}) {
  const { mkdtemp } = await import('node:fs/promises')
  const userData = await mkdtemp(join(tmpdir(), 'egdata-update-test-'))
  temporaryDirectories.push(userData)
  return {
    userData,
    instance: new UpdateService({
      currentVersion: options.currentVersion,
      channel: options.channel ?? 'stable',
      platform: options.platform ?? 'win32',
      windowsStore: options.windowsStore ?? false,
      isPackaged: options.isPackaged,
      userData,
      fetch: options.fetcher,
      ...(options.onStatus ? { onStatus: options.onStatus } : {}),
      openPath: options.openPath ?? (async () => ''),
      quit: options.quit ?? (() => undefined),
      manifestWorkIsBusy: options.manifestWorkIsBusy ?? (() => false),
      cancelManifestWork: options.cancelManifestWork ?? (async () => undefined),
      setInstallBarrier: options.setInstallBarrier ?? (() => undefined),
    }),
  }
}

function jsonResponse(value: unknown): Response {
  return new Response(JSON.stringify(value), {
    status: 200,
    headers: { 'content-type': 'application/json' },
  })
}

function byteResponse(value: Buffer): Response {
  return new Response(new Uint8Array(value), {
    status: 200,
    headers: { 'content-length': String(value.byteLength) },
  })
}

function digest(value: Buffer): string {
  return createHash('sha256').update(value).digest('hex')
}

function requestUrl(input: string | URL | Request): string {
  if (typeof input === 'string') return input
  return input instanceof URL ? input.toString() : input.url
}
