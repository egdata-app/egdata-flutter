import { createHash } from 'node:crypto'
import { lstat, mkdir, open, readdir, rename, rm } from 'node:fs/promises'
import { isAbsolute, relative, resolve, sep } from 'node:path'

import { gt, rcompare, valid } from 'semver'
import { z } from 'zod'

import type { UpdateChannel, UpdateInstallResult, UpdateStatus } from '../../shared'
import type { DiagnosticLogger } from '../diagnostics'

const GITHUB_API_ROOT = 'https://api.github.com/repos/egdata-app/egdata-flutter'
const GITHUB_RELEASES_URL = 'https://github.com/egdata-app/egdata-flutter/releases'
const GITHUB_API_VERSION = '2026-03-10'
const MAX_METADATA_BYTES = 1024 * 1024
const MAX_CHECKSUM_BYTES = 4 * 1024
const MAX_INSTALLER_BYTES = 512 * 1024 * 1024
const METADATA_TIMEOUT_MS = 15_000
const DOWNLOAD_TIMEOUT_MS = 30 * 60_000
const RELEASE_LIMIT = 20

const GitHubAssetSchema = z.object({
  id: z.number().int().positive(),
  name: z.string().min(1).max(256),
  state: z.literal('uploaded'),
  size: z.number().int().positive(),
  digest: z.string().max(128).nullable().optional(),
  browser_download_url: z.string().url().max(2_048),
})

const GitHubReleaseSchema = z.object({
  id: z.number().int().positive(),
  tag_name: z.string().min(1).max(128),
  html_url: z.string().url().max(2_048),
  draft: z.boolean(),
  prerelease: z.boolean(),
  assets: z.array(GitHubAssetSchema).max(100),
})

const GitHubReleaseListSchema = z.array(GitHubReleaseSchema).max(RELEASE_LIMIT)

type GitHubAsset = z.infer<typeof GitHubAssetSchema>
type GitHubRelease = z.infer<typeof GitHubReleaseSchema>

interface SelectedRelease {
  readonly id: number
  readonly tag: string
  readonly version: string
  readonly releaseNotesUrl: string
  readonly assets: readonly GitHubAsset[]
}

export interface UpdateServiceOptions {
  readonly currentVersion: string
  readonly channel: UpdateChannel
  readonly platform: NodeJS.Platform
  readonly windowsStore: boolean
  readonly isPackaged: boolean
  readonly userData: string
  readonly fetch?: typeof fetch
  readonly logger?: Pick<DiagnosticLogger, 'info' | 'warn'>
  readonly onStatus?: (status: UpdateStatus) => void
  readonly openPath: (filePath: string) => Promise<string>
  readonly quit: () => void
  readonly manifestWorkIsBusy: () => boolean
  readonly cancelManifestWork: () => Promise<void>
  readonly setInstallBarrier: (active: boolean) => void
}

export class UpdateService {
  readonly #currentVersion: string
  readonly #delivery: UpdateStatus['delivery']
  readonly #updatesRoot: string
  readonly #fetch: typeof fetch
  readonly #logger: Pick<DiagnosticLogger, 'info' | 'warn'> | undefined
  readonly #onStatus: ((status: UpdateStatus) => void) | undefined
  readonly #openPath: (filePath: string) => Promise<string>
  readonly #quit: () => void
  readonly #manifestWorkIsBusy: () => boolean
  readonly #cancelManifestWork: () => Promise<void>
  readonly #setInstallBarrier: (active: boolean) => void
  #channel: UpdateChannel
  #status: UpdateStatus
  #selectedRelease: SelectedRelease | null = null
  #installer: { path: string; sha256: string; size: number } | null = null
  #checkPromise: Promise<UpdateStatus> | null = null
  #downloadPromise: Promise<UpdateStatus> | null = null
  #checkController: AbortController | null = null
  #downloadController: AbortController | null = null
  #generation = 0

  constructor(options: UpdateServiceOptions) {
    if (!valid(options.currentVersion)) {
      throw new TypeError('The installed application version is not valid SemVer.')
    }
    this.#currentVersion = options.currentVersion
    this.#channel = options.channel
    this.#delivery = options.windowsStore
      ? 'store'
      : options.platform === 'win32' && options.isPackaged
        ? 'managed'
        : 'manual'
    this.#updatesRoot = resolve(options.userData, 'updates')
    this.#fetch = options.fetch ?? fetch
    this.#logger = options.logger
    this.#onStatus = options.onStatus
    this.#openPath = options.openPath
    this.#quit = options.quit
    this.#manifestWorkIsBusy = options.manifestWorkIsBusy
    this.#cancelManifestWork = options.cancelManifestWork
    this.#setInstallBarrier = options.setInstallBarrier
    this.#status = this.#initialStatus()
  }

  get status(): UpdateStatus {
    return structuredClone(this.#status)
  }

  async setChannel(channel: UpdateChannel): Promise<void> {
    if (channel === this.#channel) return
    this.#generation += 1
    this.#checkController?.abort()
    this.#downloadController?.abort()
    await Promise.allSettled(
      [this.#checkPromise, this.#downloadPromise].filter(
        (promise): promise is Promise<UpdateStatus> => promise !== null,
      ),
    )
    this.#channel = channel
    this.#selectedRelease = null
    this.#installer = null
    this.#setStatus(this.#initialStatus())
  }

  check(): Promise<UpdateStatus> {
    if (this.#delivery === 'store') return Promise.resolve(this.status)
    if (this.#downloadPromise) return this.#downloadPromise
    if (this.#checkPromise) return this.#checkPromise
    const generation = this.#generation
    const controller = new AbortController()
    this.#checkController = controller
    const operation = this.#performCheck(generation, controller.signal).finally(() => {
      if (this.#checkPromise === operation) this.#checkPromise = null
      if (this.#checkController === controller) this.#checkController = null
    })
    this.#checkPromise = operation
    return operation
  }

  download(): Promise<UpdateStatus> {
    if (this.#delivery !== 'managed') {
      return Promise.resolve(this.status)
    }
    if (this.#downloadPromise) return this.#downloadPromise
    const release = this.#selectedRelease
    if (!release) {
      return Promise.resolve(this.#setError('Check for an update before downloading it.', true))
    }
    const generation = this.#generation
    const controller = new AbortController()
    this.#downloadController = controller
    const operation = this.#performDownload(release, generation, controller.signal)
      .catch(async (error: unknown) => {
        if (generation !== this.#generation || controller.signal.aborted) return this.status
        await this.#logger?.warn('updates', 'Update download or verification failed', { error })
        return this.#setError(
          publicUpdateError(error, 'The update could not be downloaded and verified.'),
          true,
          release,
        )
      })
      .finally(() => {
        if (this.#downloadPromise === operation) this.#downloadPromise = null
        if (this.#downloadController === controller) this.#downloadController = null
      })
    this.#downloadPromise = operation
    return operation
  }

  async install(cancelActiveWork: boolean): Promise<UpdateInstallResult> {
    const release = this.#selectedRelease
    if (
      this.#delivery !== 'managed' ||
      this.#status.state !== 'downloaded' ||
      !this.#installer ||
      !release
    ) {
      throw new Error('No verified update is ready to install.')
    }
    if (this.#manifestWorkIsBusy() && !cancelActiveWork) {
      return { outcome: 'confirmation-required' }
    }

    const installer = this.#installer
    this.#setInstallBarrier(true)
    this.#setStatus({
      ...this.#baseStatus(),
      state: 'installing',
      availableVersion: release.version,
      releaseNotesUrl: release.releaseNotesUrl,
      message: 'Preparing egdata.app to install the verified update…',
    })

    try {
      if (this.#manifestWorkIsBusy()) await this.#cancelManifestWork()
      if (this.#manifestWorkIsBusy()) {
        throw new Error('Manifest work did not stop safely. Try installing again when it is idle.')
      }
      await this.#verifyInstallerFile(installer.path, installer.sha256, installer.size)
      const launchError = await this.#openPath(installer.path)
      if (launchError) throw new Error('Windows could not start the update installer.')
      await this.#logger?.info('updates', 'Verified update installer launched', {
        availableVersion: this.#selectedRelease?.version,
      })
      setTimeout(this.#quit, 0)
      return { outcome: 'started' }
    } catch (error) {
      this.#setInstallBarrier(false)
      this.#setStatus({
        ...this.#baseStatus(),
        state: 'downloaded',
        availableVersion: release.version,
        releaseNotesUrl: release.releaseNotesUrl,
        message: publicUpdateError(error, 'The verified update could not be installed.'),
        error: updateError(error, 'The verified update could not be installed.'),
      })
      await this.#logger?.warn('updates', 'Update installation could not start', { error })
      throw error
    }
  }

  dispose(): void {
    this.#generation += 1
    this.#checkController?.abort()
    this.#downloadController?.abort()
  }

  async #performCheck(generation: number, externalSignal: AbortSignal): Promise<UpdateStatus> {
    this.#setStatus({ ...this.#baseStatus(), state: 'checking' })
    try {
      const selected =
        this.#channel === 'stable'
          ? selectStableRelease(
              await this.#getJson(
                `${GITHUB_API_ROOT}/releases/latest`,
                GitHubReleaseSchema,
                externalSignal,
              ),
            )
          : selectBetaRelease(
              await this.#getJson(
                `${GITHUB_API_ROOT}/releases?per_page=${RELEASE_LIMIT}`,
                GitHubReleaseListSchema,
                externalSignal,
              ),
            )
      if (generation !== this.#generation) return this.status
      this.#selectedRelease = selected
      this.#installer = null

      if (!gt(selected.version, this.#currentVersion)) {
        return this.#setStatus({
          ...this.#baseStatus(),
          state: 'not-available',
          message: `Version ${this.#currentVersion} is up to date on the ${this.#channel} channel.`,
        })
      }

      const available = this.#setStatus({
        ...this.#baseStatus(),
        state: 'available',
        availableVersion: selected.version,
        releaseNotesUrl: selected.releaseNotesUrl,
        message:
          this.#delivery === 'manual'
            ? `Version ${selected.version} is available from GitHub.`
            : `Version ${selected.version} is available and will be downloaded.`,
      })
      if (this.#delivery === 'managed') {
        void this.download()
        return this.status
      }
      return available
    } catch (error) {
      if (generation !== this.#generation || externalSignal.aborted) return this.status
      await this.#logger?.warn('updates', 'GitHub release check failed', { error })
      return this.#setError('The GitHub update service could not be reached.', true)
    }
  }

  async #performDownload(
    release: SelectedRelease,
    generation: number,
    externalSignal: AbortSignal,
  ): Promise<UpdateStatus> {
    const installerName = `egdata-app-${release.version}-setup.exe`
    const checksumName = `${installerName}.sha256`
    const installerAsset = exactAsset(release, installerName)
    const checksumAsset = exactAsset(release, checksumName)
    assertManagedAsset(installerAsset, release.tag, installerName, MAX_INSTALLER_BYTES)
    assertManagedAsset(checksumAsset, release.tag, checksumName, MAX_CHECKSUM_BYTES)
    const assetDigest = parseAssetDigest(installerAsset.digest)

    this.#setStatus({
      ...this.#baseStatus(),
      state: 'downloading',
      availableVersion: release.version,
      releaseNotesUrl: release.releaseNotesUrl,
      progressPercent: 0,
      message: `Downloading egdata.app ${release.version}…`,
    })

    const versionDirectory = resolve(this.#updatesRoot, release.version)
    const installerPath = resolve(versionDirectory, installerName)
    const partialPath = resolve(versionDirectory, `${installerName}.${process.pid}.partial`)
    assertChildPath(this.#updatesRoot, versionDirectory)
    assertChildPath(versionDirectory, installerPath)
    assertChildPath(versionDirectory, partialPath)

    try {
      const checksumBytes = await this.#getBytes(
        checksumAsset.browser_download_url,
        MAX_CHECKSUM_BYTES,
        METADATA_TIMEOUT_MS,
        externalSignal,
      )
      if (checksumBytes.byteLength !== checksumAsset.size) {
        throw new Error('The published checksum size did not match GitHub release metadata.')
      }
      const checksumDigest = parseOptionalAssetDigest(checksumAsset.digest)
      if (checksumDigest && sha256(checksumBytes) !== checksumDigest) {
        throw new Error('The published checksum asset did not match its GitHub digest.')
      }
      const expectedHash = parseChecksum(checksumBytes.toString('utf8'), installerName)
      if (expectedHash !== assetDigest) {
        throw new Error('The published installer checksums do not agree.')
      }

      await mkdir(versionDirectory, { recursive: true, mode: 0o700 })
      if (await verifiedFileExists(installerPath, expectedHash, installerAsset.size)) {
        await removeOwnedFile(partialPath, versionDirectory)
        if (generation !== this.#generation) return this.status
        this.#installer = {
          path: installerPath,
          sha256: expectedHash,
          size: installerAsset.size,
        }
        await this.#cleanupStaleVersions(release.version)
        return this.#setDownloaded(release)
      }
      await removeOwnedFile(installerPath, versionDirectory)
      await removeOwnedFile(partialPath, versionDirectory)

      const signal = AbortSignal.any([externalSignal, AbortSignal.timeout(DOWNLOAD_TIMEOUT_MS)])
      const response = await this.#fetch(installerAsset.browser_download_url, {
        headers: githubHeaders(this.#currentVersion),
        redirect: 'follow',
        signal,
      })
      if (!response.ok || !response.body) {
        throw new Error(`GitHub returned HTTP ${response.status} for the installer.`)
      }
      const declaredLength = numberHeader(response.headers.get('content-length'))
      if (declaredLength !== null && declaredLength !== installerAsset.size) {
        throw new Error('The installer response size did not match GitHub release metadata.')
      }

      const handle = await open(partialPath, 'wx', 0o600)
      const hash = createHash('sha256')
      const reader = response.body.getReader()
      let received = 0
      let lastProgress = -1
      try {
        while (true) {
          const chunk = await reader.read()
          if (chunk.done) break
          received += chunk.value.byteLength
          if (received > installerAsset.size || received > MAX_INSTALLER_BYTES) {
            throw new Error('The update installer exceeded its declared size.')
          }
          hash.update(chunk.value)
          await handle.write(chunk.value)
          const progress = Math.min(100, Math.floor((received / installerAsset.size) * 100))
          if (progress !== lastProgress && generation === this.#generation) {
            lastProgress = progress
            this.#setStatus({
              ...this.#baseStatus(),
              state: 'downloading',
              availableVersion: release.version,
              releaseNotesUrl: release.releaseNotesUrl,
              progressPercent: progress,
              message: `Downloading egdata.app ${release.version}…`,
            })
          }
        }
        await handle.sync()
      } finally {
        await handle.close()
      }

      if (received !== installerAsset.size) {
        throw new Error('The downloaded installer was incomplete.')
      }
      if (hash.digest('hex') !== expectedHash) {
        throw new Error('The downloaded installer failed SHA-256 verification.')
      }
      await rename(partialPath, installerPath)
      if (generation !== this.#generation) return this.status
      this.#installer = { path: installerPath, sha256: expectedHash, size: installerAsset.size }
      await this.#cleanupStaleVersions(release.version)
      await this.#logger?.info('updates', 'Update downloaded and verified', {
        availableVersion: release.version,
        installerBytes: installerAsset.size,
      })
      return this.#setDownloaded(release)
    } catch (error) {
      await removeOwnedFile(partialPath, versionDirectory)
      if (generation !== this.#generation || externalSignal.aborted) return this.status
      await this.#logger?.warn('updates', 'Update download or verification failed', { error })
      return this.#setError(
        publicUpdateError(error, 'The update could not be downloaded and verified.'),
        true,
        release,
      )
    }
  }

  async #getJson<T>(url: string, schema: z.ZodType<T>, externalSignal: AbortSignal): Promise<T> {
    const response = await this.#fetch(url, {
      headers: githubHeaders(this.#currentVersion),
      signal: AbortSignal.any([externalSignal, AbortSignal.timeout(METADATA_TIMEOUT_MS)]),
    })
    if (!response.ok) throw new Error(`GitHub returned HTTP ${response.status}.`)
    const body = await readResponseBytes(response, MAX_METADATA_BYTES)
    let value: unknown
    try {
      value = JSON.parse(body.toString('utf8'))
    } catch (error) {
      throw new Error('GitHub returned malformed release metadata.', { cause: error })
    }
    return schema.parse(value)
  }

  async #getBytes(
    url: string,
    maximumBytes: number,
    timeoutMs: number,
    externalSignal: AbortSignal,
  ): Promise<Buffer> {
    const response = await this.#fetch(url, {
      headers: githubHeaders(this.#currentVersion),
      redirect: 'follow',
      signal: AbortSignal.any([externalSignal, AbortSignal.timeout(timeoutMs)]),
    })
    if (!response.ok) throw new Error(`GitHub returned HTTP ${response.status}.`)
    return readResponseBytes(response, maximumBytes)
  }

  async #verifyInstallerFile(filePath: string, expectedHash: string, expectedSize: number) {
    assertChildPath(this.#updatesRoot, filePath)
    const details = await lstat(filePath)
    if (!details.isFile() || details.isSymbolicLink() || details.size !== expectedSize) {
      throw new Error('The verified update installer is no longer valid.')
    }
    if ((await hashFile(filePath)) !== expectedHash) {
      throw new Error('The update installer changed after it was downloaded.')
    }
  }

  async #cleanupStaleVersions(currentVersion: string): Promise<void> {
    let entries
    try {
      entries = await readdir(this.#updatesRoot, { withFileTypes: true })
    } catch (error) {
      if (isMissingFile(error)) return
      throw error
    }
    for (const entry of entries) {
      if (entry.name === currentVersion) continue
      const target = resolve(this.#updatesRoot, entry.name)
      assertChildPath(this.#updatesRoot, target)
      await rm(target, { recursive: entry.isDirectory(), force: true })
    }
  }

  #initialStatus(): UpdateStatus {
    return {
      ...this.#baseStatus(),
      state: 'idle',
      ...(this.#delivery === 'store'
        ? { message: 'Updates for this installation are delivered by Microsoft Store.' }
        : {}),
    }
  }

  #baseStatus(): Pick<UpdateStatus, 'currentVersion' | 'channel' | 'delivery'> {
    return {
      currentVersion: this.#currentVersion,
      channel: this.#channel,
      delivery: this.#delivery,
    }
  }

  #setDownloaded(release: SelectedRelease): UpdateStatus {
    return this.#setStatus({
      ...this.#baseStatus(),
      state: 'downloaded',
      availableVersion: release.version,
      releaseNotesUrl: release.releaseNotesUrl,
      progressPercent: 100,
      message: `Version ${release.version} is verified and ready to install.`,
    })
  }

  #setError(
    message: string,
    retryable: boolean,
    release: SelectedRelease | null = this.#selectedRelease,
  ): UpdateStatus {
    return this.#setStatus({
      ...this.#baseStatus(),
      state: 'error',
      ...(release
        ? {
            availableVersion: release.version,
            releaseNotesUrl: release.releaseNotesUrl,
          }
        : { releaseNotesUrl: GITHUB_RELEASES_URL }),
      message,
      error: {
        code: 'INTERNAL_ERROR',
        message,
        retryable,
      },
    })
  }

  #setStatus(status: UpdateStatus): UpdateStatus {
    this.#status = structuredClone(status)
    this.#onStatus?.(this.status)
    return this.status
  }
}

export function selectStableRelease(release: GitHubRelease): SelectedRelease {
  if (release.draft || release.prerelease) {
    throw new Error('GitHub did not return a stable published release.')
  }
  return selectedRelease(release)
}

export function selectBetaRelease(releases: readonly GitHubRelease[]): SelectedRelease {
  const candidates = releases
    .filter((release) => !release.draft)
    .map((release) => {
      try {
        return selectedRelease(release)
      } catch {
        return null
      }
    })
    .filter((release): release is SelectedRelease => release !== null)
    .sort((left, right) => rcompare(left.version, right.version))
  const selected = candidates[0]
  if (!selected) throw new Error('GitHub did not return a valid published release.')
  return selected
}

function selectedRelease(release: GitHubRelease): SelectedRelease {
  const version = releaseVersion(release.tag_name)
  const releaseUrl = new URL(release.html_url)
  if (
    releaseUrl.protocol !== 'https:' ||
    releaseUrl.hostname !== 'github.com' ||
    !releaseUrl.pathname.startsWith('/egdata-app/egdata-flutter/releases/')
  ) {
    throw new Error('GitHub returned an unexpected release URL.')
  }
  return {
    id: release.id,
    tag: release.tag_name,
    version,
    releaseNotesUrl: releaseUrl.toString(),
    assets: release.assets,
  }
}

function releaseVersion(tag: string): string {
  const match = /^v?(\d+\.\d+\.\d+(?:-[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?)$/.exec(tag)
  const version = match?.[1]
  if (!version || !valid(version)) throw new Error('The GitHub release tag is not valid SemVer.')
  return version
}

function exactAsset(release: SelectedRelease, name: string): GitHubAsset {
  const matches = release.assets.filter((asset) => asset.name === name)
  if (matches.length !== 1) {
    throw new Error(`The GitHub release must contain exactly one ${name} asset.`)
  }
  return matches[0]!
}

function assertManagedAsset(
  asset: GitHubAsset,
  tag: string,
  expectedName: string,
  maximumBytes: number,
): void {
  if (asset.size > maximumBytes) throw new Error(`The ${expectedName} asset is too large.`)
  const expectedUrl = `https://github.com/egdata-app/egdata-flutter/releases/download/${tag}/${expectedName}`
  if (asset.browser_download_url !== expectedUrl) {
    throw new Error(`The ${expectedName} asset has an unexpected download URL.`)
  }
}

function parseAssetDigest(value: string | null | undefined): string {
  const digest = parseOptionalAssetDigest(value)
  if (!digest) throw new Error('The GitHub installer asset does not include a SHA-256 digest.')
  return digest
}

function parseOptionalAssetDigest(value: string | null | undefined): string | null {
  if (value === null || value === undefined) return null
  const match = /^sha256:([a-f0-9]{64})$/i.exec(value)
  if (!match) throw new Error('GitHub returned an invalid asset digest.')
  return match[1]!.toLowerCase()
}

function parseChecksum(value: string, expectedName: string): string {
  const escapedName = expectedName.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
  const match = new RegExp(`^([a-f0-9]{64})[ \\t]+\\*?${escapedName}\\r?\\n?$`, 'i').exec(value)
  if (!match) throw new Error('The published checksum file is malformed.')
  return match[1]!.toLowerCase()
}

function githubHeaders(version: string): Record<string, string> {
  return {
    Accept: 'application/vnd.github+json',
    'X-GitHub-Api-Version': GITHUB_API_VERSION,
    'User-Agent': `egdata.app/${version}`,
  }
}

async function readResponseBytes(response: Response, maximumBytes: number): Promise<Buffer> {
  const declaredLength = numberHeader(response.headers.get('content-length'))
  if (declaredLength !== null && declaredLength > maximumBytes) {
    throw new Error('The response exceeded the allowed size.')
  }
  if (!response.body) throw new Error('The response did not contain a body.')
  const reader = response.body.getReader()
  const chunks: Uint8Array[] = []
  let received = 0
  while (true) {
    const chunk = await reader.read()
    if (chunk.done) break
    received += chunk.value.byteLength
    if (received > maximumBytes) throw new Error('The response exceeded the allowed size.')
    chunks.push(chunk.value)
  }
  return Buffer.concat(chunks, received)
}

function numberHeader(value: string | null): number | null {
  if (value === null) return null
  const parsed = Number.parseInt(value, 10)
  return Number.isSafeInteger(parsed) && parsed >= 0 ? parsed : null
}

function sha256(value: Uint8Array): string {
  return createHash('sha256').update(value).digest('hex')
}

async function verifiedFileExists(
  filePath: string,
  expectedHash: string,
  expectedSize: number,
): Promise<boolean> {
  try {
    const details = await lstat(filePath)
    if (!details.isFile() || details.isSymbolicLink() || details.size !== expectedSize) return false
    return (await hashFile(filePath)) === expectedHash
  } catch (error) {
    if (isMissingFile(error)) return false
    throw error
  }
}

async function removeOwnedFile(filePath: string, ownerDirectory: string): Promise<void> {
  assertChildPath(ownerDirectory, filePath)
  await rm(filePath, { force: true })
}

function assertChildPath(parent: string, child: string): void {
  const relation = relative(resolve(parent), resolve(child))
  if (!relation || relation === '..' || relation.startsWith(`..${sep}`) || isAbsolute(relation)) {
    throw new Error('The update path escaped its controlled directory.')
  }
}

async function hashFile(filePath: string): Promise<string> {
  const handle = await open(filePath, 'r')
  const hash = createHash('sha256')
  const buffer = Buffer.allocUnsafe(1024 * 1024)
  let position = 0
  try {
    while (true) {
      const { bytesRead } = await handle.read(buffer, 0, buffer.byteLength, position)
      if (bytesRead === 0) break
      hash.update(buffer.subarray(0, bytesRead))
      position += bytesRead
    }
    return hash.digest('hex')
  } finally {
    await handle.close()
  }
}

function updateError(error: unknown, fallback: string): UpdateStatus['error'] {
  return {
    code: 'INTERNAL_ERROR',
    message: publicUpdateError(error, fallback),
    retryable: true,
  }
}

function publicUpdateError(error: unknown, fallback: string): string {
  if (!(error instanceof Error)) return fallback
  const allowed = [
    'The GitHub release must contain exactly one',
    'The GitHub installer asset does not include',
    'The published checksum',
    'The published installer checksums do not agree.',
    'The downloaded installer',
    'The update installer',
    'Manifest work did not stop safely.',
    'Windows could not start',
  ]
  return allowed.some((prefix) => error.message.startsWith(prefix)) ? error.message : fallback
}

function isMissingFile(error: unknown): boolean {
  return error instanceof Error && 'code' in error && error.code === 'ENOENT'
}
