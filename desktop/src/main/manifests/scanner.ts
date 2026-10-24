import { randomUUID } from 'node:crypto'
import { constants as fsConstants } from 'node:fs'
import { access, readFile, readdir, stat } from 'node:fs/promises'
import path from 'node:path'

import { z } from 'zod'

import { groupLocalManifests, toPublicManifestItem } from './grouping'
import { parseNewLauncherIndex, type ManifestDiscoverySource } from './new-launcher'
import { parseLocalItem } from './parser'
import {
  isAbsoluteManifestDirectory,
  normalizeInstallPath,
  resolveDefaultManifestDirectory,
  resolveNewLauncherDirectory,
} from './paths'
import type {
  LocalManifestDiagnostic,
  LocalManifestErrorCode,
  LocalManifestPlatform,
  LocalManifestScanResult,
  LocalManifestSource,
  LocalManifestUploadPayload,
} from './types'

export const localManifestScanRequestSchema = z
  .object({
    source: z.enum(['default', 'selected']).optional(),
    manifestDirectory: z.string().min(1).max(4096).optional(),
  })
  .strict()
  .refine(
    (value) => value.source !== 'selected' || Boolean(value.manifestDirectory),
    'A selected scan requires a main-process-approved directory',
  )

export interface LocalManifestScannerOptions {
  platform: LocalManifestPlatform
  environment?: NodeJS.ProcessEnv
  /** Only enable for test fixtures or a main-process-approved folder picker. */
  allowCustomDirectory?: boolean
  maxSessions?: number
}

export class LocalManifestAccessError extends Error {
  constructor(
    readonly code: LocalManifestErrorCode,
    message: string,
  ) {
    super(message)
    this.name = 'LocalManifestAccessError'
  }
}

function isNodeError(error: unknown, code: string): boolean {
  return error instanceof Error && 'code' in error && (error as NodeJS.ErrnoException).code === code
}

function isPermissionError(error: unknown): boolean {
  return isNodeError(error, 'EACCES') || isNodeError(error, 'EPERM')
}

function diagnostic(
  code: LocalManifestErrorCode,
  message: string,
  sourceName?: string,
  itemId?: string,
): LocalManifestDiagnostic {
  return {
    code,
    message,
    ...(sourceName ? { sourceName } : {}),
    ...(itemId ? { itemId } : {}),
  }
}

async function readableFile(filePath: string): Promise<'yes' | 'missing' | 'denied'> {
  try {
    const details = await stat(filePath)
    if (!details.isFile()) return 'missing'
    await access(filePath, fsConstants.R_OK)
    return 'yes'
  } catch (error) {
    if (isPermissionError(error)) return 'denied'
    return 'missing'
  }
}

async function fallbackManifest(
  installLocation: string,
): Promise<{ path?: string; fileName?: string; denied: boolean }> {
  if (!installLocation.trim()) return { denied: false }
  const egstore = path.join(installLocation, '.egstore')
  try {
    const entries = await readdir(egstore, { withFileTypes: true })
    const candidates = entries
      .filter((entry) => entry.isFile() && entry.name.toLowerCase().endsWith('.manifest'))
      .sort((left, right) => left.name.localeCompare(right.name))

    for (const candidate of candidates) {
      const candidatePath = path.join(egstore, candidate.name)
      const state = await readableFile(candidatePath)
      if (state === 'yes') {
        return { path: candidatePath, fileName: candidate.name, denied: false }
      }
      if (state === 'denied') return { denied: true }
    }
  } catch (error) {
    if (isPermissionError(error)) return { denied: true }
  }
  return { denied: false }
}

async function resolveBinaryManifest(parsed: {
  manifestLocation: string
  installLocation: string
  installationGuid: string
}): Promise<{ path?: string; fileName?: string; denied: boolean }> {
  const requested = parsed.manifestLocation.trim()
  if (requested) {
    const state = await readableFile(requested)
    if (state === 'yes') {
      return { path: requested, fileName: path.basename(requested), denied: false }
    }
    if (state === 'denied') return { denied: true }
    // Legacy .item records may point to the .egstore directory rather than a file.
    if (/^[A-Za-z0-9_-]{1,128}$/.test(parsed.installationGuid)) {
      const candidate = path.join(requested, `${parsed.installationGuid}.manifest`)
      const candidateState = await readableFile(candidate)
      if (candidateState === 'yes') {
        return { path: candidate, fileName: path.basename(candidate), denied: false }
      }
      if (candidateState === 'denied') return { denied: true }
    }
  }
  if (parsed.installLocation && /^[A-Za-z0-9_-]{1,128}$/.test(parsed.installationGuid)) {
    const candidate = path.join(
      parsed.installLocation,
      '.egstore',
      `${parsed.installationGuid}.manifest`,
    )
    const state = await readableFile(candidate)
    if (state === 'yes')
      return { path: candidate, fileName: path.basename(candidate), denied: false }
    if (state === 'denied') return { denied: true }
  }
  return fallbackManifest(parsed.installLocation)
}

export class LocalManifestScanner {
  private readonly platform: LocalManifestPlatform
  private readonly environment: NodeJS.ProcessEnv
  private readonly allowCustomDirectory: boolean
  private readonly maxSessions: number
  private readonly sessions = new Map<string, Map<string, LocalManifestSource>>()

  constructor(options: LocalManifestScannerOptions) {
    this.platform = options.platform
    this.environment = options.environment ?? process.env
    this.allowCustomDirectory = options.allowCustomDirectory ?? false
    this.maxSessions = Math.max(1, options.maxSessions ?? 8)
  }

  async scan(request: unknown = {}): Promise<LocalManifestScanResult> {
    const input = localManifestScanRequestSchema.parse(request)
    if (input.manifestDirectory && !this.allowCustomDirectory) {
      throw new Error('Custom manifest directories are not enabled')
    }
    if (
      input.manifestDirectory &&
      !isAbsoluteManifestDirectory(this.platform, input.manifestDirectory)
    ) {
      throw new Error('The manifest directory must be an absolute platform path')
    }

    const directory =
      input.manifestDirectory ?? resolveDefaultManifestDirectory(this.platform, this.environment)
    const sessionId = randomUUID()
    const sources = new Map<string, LocalManifestSource>()
    const errors: LocalManifestDiagnostic[] = []

    const discovered: ManifestDiscoverySource[] = []
    const legacyAvailable = await this.readLegacyDirectory(directory, discovered, errors)
    const newDirectory =
      input.manifestDirectory ?? resolveNewLauncherDirectory(this.platform, this.environment)
    const newAvailable =
      this.platform === 'win32' && newDirectory
        ? await this.readNewLauncher(newDirectory, discovered, errors)
        : false
    const directoryAvailable = legacyAvailable || newAvailable
    if (!directoryAvailable && errors.length === 0) {
      errors.push(
        diagnostic(
          'LOCAL_MANIFEST_DIRECTORY_MISSING',
          'The Epic manifest directory was not found.',
        ),
      )
    }

    const identities = new Set<string>()
    for (const discovery of discovered) {
      const { parsed, rawItemText, itemPath, sourceName } = discovery
      // Prefer original legacy JSON for the same installation/build when both
      // indexes describe it, but retain independent add-ons and changed builds.
      const identity = JSON.stringify([
        parsed.installationGuid.toLowerCase(),
        normalizeInstallPath(this.platform, parsed.installLocation),
        parsed.catalogNamespace,
        parsed.catalogItemId,
        parsed.appName,
        parsed.appVersion,
      ])
      if (parsed.installationGuid && identities.has(identity)) continue
      identities.add(identity)
      const itemId = randomUUID()
      let binary: { path?: string; fileName?: string; denied: boolean }
      if (discovery.exactBinary) {
        const state = await readableFile(parsed.manifestLocation)
        binary =
          state === 'yes'
            ? {
                path: parsed.manifestLocation,
                fileName: path.basename(parsed.manifestLocation),
                denied: false,
              }
            : { denied: state === 'denied' }
      } else {
        binary = await resolveBinaryManifest(parsed)
      }
      const diagnosticCodes: LocalManifestErrorCode[] = []
      if (binary.denied) {
        diagnosticCodes.push('LOCAL_ITEM_PERMISSION_DENIED')
        errors.push(
          diagnostic(
            'LOCAL_ITEM_PERMISSION_DENIED',
            'The binary manifest could not be read.',
            sourceName,
            itemId,
          ),
        )
      } else if (!binary.path) {
        diagnosticCodes.push('LOCAL_BINARY_MANIFEST_MISSING')
        errors.push(
          diagnostic(
            'LOCAL_BINARY_MANIFEST_MISSING',
            'No binary manifest was found for this item.',
            sourceName,
            itemId,
          ),
        )
      }
      sources.set(itemId, {
        itemId,
        sourceName,
        rawItemText,
        itemPath,
        ...(binary.path ? { manifestPath: binary.path } : {}),
        ...(binary.fileName ? { manifestFileName: binary.fileName } : {}),
        parsed,
        diagnosticCodes,
      })
    }

    this.storeSession(sessionId, sources)
    const sourceList = [...sources.values()]
    return {
      sessionId,
      directoryAvailable,
      items: sourceList.map(toPublicManifestItem),
      groups: groupLocalManifests(sourceList, this.platform),
      errors,
    }
  }

  private async readLegacyDirectory(
    directory: string,
    discovered: ManifestDiscoverySource[],
    errors: LocalManifestDiagnostic[],
  ): Promise<boolean> {
    let entries
    try {
      entries = await readdir(directory, { withFileTypes: true })
    } catch (error) {
      const missing = isNodeError(error, 'ENOENT') || isNodeError(error, 'ENOTDIR')
      if (!missing)
        errors.push(
          diagnostic(
            'LOCAL_ITEM_PERMISSION_DENIED',
            'The Epic manifest directory could not be read.',
          ),
        )
      return false
    }

    const itemEntries = entries
      .filter((entry) => entry.isFile() && entry.name.toLowerCase().endsWith('.item'))
      .sort((left, right) => left.name.localeCompare(right.name))

    for (const entry of itemEntries) {
      const itemPath = path.join(directory, entry.name)
      let rawItemText: string
      try {
        rawItemText = await readFile(itemPath, 'utf8')
      } catch {
        errors.push(
          diagnostic(
            'LOCAL_ITEM_PERMISSION_DENIED',
            'The Epic item file could not be read.',
            entry.name,
          ),
        )
        continue
      }

      let parsed
      try {
        parsed = parseLocalItem(rawItemText)
      } catch {
        errors.push(
          diagnostic(
            'LOCAL_ITEM_INVALID_JSON',
            'The Epic item file contains malformed JSON.',
            entry.name,
          ),
        )
        continue
      }

      discovered.push({
        sourceName: entry.name,
        rawItemText,
        itemPath,
        parsed,
      })
    }
    return true
  }

  private async readNewLauncher(
    directory: string,
    discovered: ManifestDiscoverySource[],
    errors: LocalManifestDiagnostic[],
  ): Promise<boolean> {
    const indexPath = path.join(directory, 'installations.jsonl')
    let text: string
    try {
      const details = await stat(indexPath)
      if (details.size > 16 * 1024 * 1024) {
        errors.push(
          diagnostic(
            'LOCAL_ITEM_INVALID_JSON',
            'The Epic installation index is too large.',
            'installations.jsonl',
          ),
        )
        return true
      }
      text = await readFile(indexPath, 'utf8')
    } catch (error) {
      if (!isNodeError(error, 'ENOENT') && !isNodeError(error, 'ENOTDIR')) {
        errors.push(
          diagnostic(
            'LOCAL_ITEM_PERMISSION_DENIED',
            'The Epic installation index could not be read.',
            'installations.jsonl',
          ),
        )
      }
      return false
    }
    const result = parseNewLauncherIndex(text, indexPath)
    discovered.push(...result.sources)
    errors.push(...result.errors)
    return true
  }

  getSessionItemIds(sessionId: string): string[] {
    return [...this.requireSession(sessionId).keys()]
  }

  async getUploadPayload(sessionId: string, itemId: string): Promise<LocalManifestUploadPayload> {
    const source = this.requireSession(sessionId).get(itemId)
    if (!source) throw new Error('Unknown local manifest item')
    if (!source.manifestPath) {
      throw new LocalManifestAccessError(
        'LOCAL_BINARY_MANIFEST_MISSING',
        'No binary manifest is available for this item.',
      )
    }

    try {
      const manifestBytes = await readFile(source.manifestPath)
      return {
        itemId,
        rawItemText: source.rawItemText,
        manifestBytes,
        ...(source.manifestFileName ? { manifestFileName: source.manifestFileName } : {}),
        installationGuid: source.parsed.installationGuid,
      }
    } catch (error) {
      throw new LocalManifestAccessError(
        isPermissionError(error) ? 'LOCAL_ITEM_PERMISSION_DENIED' : 'LOCAL_BINARY_MANIFEST_MISSING',
        'The binary manifest is no longer available.',
      )
    }
  }

  clearSession(sessionId: string): void {
    this.sessions.delete(sessionId)
  }

  private requireSession(sessionId: string): Map<string, LocalManifestSource> {
    const session = this.sessions.get(sessionId)
    if (!session) throw new Error('Unknown or expired local manifest scan')
    return session
  }

  private storeSession(sessionId: string, sources: Map<string, LocalManifestSource>): void {
    this.sessions.set(sessionId, sources)
    while (this.sessions.size > this.maxSessions) {
      const oldest = this.sessions.keys().next().value
      if (!oldest) break
      this.sessions.delete(oldest)
    }
  }
}
