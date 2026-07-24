import { createHash, randomUUID } from 'node:crypto'
import { execFile } from 'node:child_process'
import { statSync } from 'node:fs'
import {
  access,
  copyFile,
  lstat,
  mkdir,
  readFile,
  readdir,
  rename,
  rm,
  stat,
  statfs,
  writeFile,
} from 'node:fs/promises'
import path from 'node:path'
import { promisify } from 'node:util'

import type { Manifest } from '@egdata/manifests-parser'

import type {
  LibraryGame,
  LibraryToolsSnapshot,
  MoveSnapshot,
  RecoveryCandidate,
  SafeError,
} from '../../shared'
import { scanWindowsEgstores } from './native-scanner'

const execFileAsync = promisify(execFile)
const RESOLVER_ENDPOINT = 'https://api.egdata.app/builds/resolve-launcher-records'
const GUID_PATTERN = /^[A-Fa-f0-9]{32}$/
const DAY_MS = 24 * 60 * 60 * 1000
const DRIVE_POLL_MS = 30 * 1000
const STARTUP_SCAN_DELAY_MS = 30 * 1000
const SYSTEM_DRIVE_MAX_DEPTH = 6
const SKIPPED_DIRECTORIES = new Set([
  '$recycle.bin',
  'system volume information',
  'windows',
  'recovery',
  'msocache',
])

type LauncherRecordKind = 'base-game' | 'addon' | 'digital-extra'

interface LauncherIdentity {
  artifactId: string
  catalogItemId: string
  catalogNamespace: string
}

interface ResolvedLauncherRecord extends LauncherIdentity {
  displayName: string
  kind: LauncherRecordKind
  appCategories: string[]
  mainGame: LauncherIdentity | null
  mandatoryAppFolderName: string
  canRunOffline: boolean
  requiresAuth: boolean
  ownershipToken: boolean
  ignoredProcessNames: string[]
}

export interface LauncherResolverResult {
  requestId: string
  status: 'resolved' | 'not-found' | 'ambiguous' | 'unsupported'
  record?: ResolvedLauncherRecord
}

export interface LauncherCatalogHint {
  artifactId: string
  catalogItemId: string
  catalogNamespace: string
}

export interface LauncherResolverCandidate {
  requestId: string
  buildAppName: string
  buildVersion: string
  platform: 'Windows'
  catalogHint?: LauncherCatalogHint
}

export type LocalLauncherResolver = (
  candidates: readonly LauncherResolverCandidate[],
) => Promise<readonly LauncherResolverResult[]>

interface RegisteredSource {
  itemPath: string
  rawText: string
  value: Record<string, unknown>
}

interface RegisteredGroup {
  id: string
  installLocation: string
  sources: RegisteredSource[]
  public: LibraryGame
}

interface CandidateRecord {
  requestId: string
  manifestPath: string
  egstorePath: string
  installationGuid: string
  manifestSize: number
  manifestMtimeMs: number
  manifest: Manifest
  hint?: LauncherCatalogHint
  resolution?: LauncherResolverResult
}

interface CandidateGroup {
  id: string
  installLocation: string
  records: CandidateRecord[]
  public: RecoveryCandidate
}

interface MoveOperation {
  game: RegisteredGroup
  destinationParent: string
  destinationLocation: string
  controller: AbortController
  snapshot: MoveSnapshot
}

interface LauncherInstalledEntry extends Record<string, unknown> {
  InstallLocation?: unknown
  AppName?: unknown
}

interface LauncherInstalledDocument extends Record<string, unknown> {
  InstallationList: LauncherInstalledEntry[]
}

interface ParserModule {
  parseManifestAsync(filePath: string): Promise<Manifest>
}

export interface DiscoveryScope {
  root: string
  maxDepth?: number
}

export interface LibraryToolsCatalogInterest {
  namespace: string
  catalogItemId?: string
  artifactId?: string
  appName?: string
  platform: 'Windows'
}

export interface LibraryToolsServiceOptions {
  platform: NodeJS.Platform
  environment?: NodeJS.ProcessEnv
  userData: string
  fetchImpl?: typeof fetch
  isLauncherRunning?: () => Promise<boolean>
  requestLauncherClose?: () => Promise<boolean>
  parseManifest?: (filePath: string) => Promise<Manifest>
  resolveLauncherRecords?: LocalLauncherResolver
  onChanged?: (snapshot: LibraryToolsSnapshot) => void
}

function safeError(message: string, retryable = false): SafeError {
  return { code: 'VALIDATION_FAILED', message, retryable }
}

function isNodeError(error: unknown, code: string): boolean {
  return error instanceof Error && 'code' in error && (error as NodeJS.ErrnoException).code === code
}

function isAbortError(error: unknown): boolean {
  return error instanceof Error && error.name === 'AbortError'
}

function normalizeWindowsPath(value: string): string {
  return path.win32
    .normalize(value)
    .replace(/[\\/]+$/, '')
    .toLowerCase()
}

export function discoveryScopesForRoot(
  root: string,
  environment: NodeJS.ProcessEnv,
  registeredLocations: string[],
): DiscoveryScope[] {
  const systemDrive = `${environment.SystemDrive?.trim() || 'C:'}\\`
  if (normalizeWindowsPath(root) !== normalizeWindowsPath(systemDrive)) return [{ root }]

  const candidates = [
    environment.ProgramW6432,
    environment.ProgramFiles,
    environment['ProgramFiles(x86)'],
    path.win32.join(systemDrive, 'Program Files'),
    path.win32.join(systemDrive, 'Program Files (x86)'),
    ...registeredLocations.filter(
      (location) =>
        normalizeWindowsPath(path.win32.parse(location).root) === normalizeWindowsPath(systemDrive),
    ),
  ].filter(
    (candidate): candidate is string =>
      typeof candidate === 'string' &&
      path.win32.isAbsolute(candidate) &&
      normalizeWindowsPath(candidate) !== normalizeWindowsPath(systemDrive),
  )

  const scopes: DiscoveryScope[] = []
  for (const candidate of candidates.sort((left, right) => left.length - right.length)) {
    const normalized = normalizeWindowsPath(candidate)
    if (
      scopes.some((scope) => {
        const parent = normalizeWindowsPath(scope.root)
        return normalized === parent || normalized.startsWith(`${parent}\\`)
      })
    ) {
      continue
    }
    scopes.push({ root: path.win32.normalize(candidate), maxDepth: SYSTEM_DRIVE_MAX_DEPTH })
  }
  return scopes
}

export function driveRootsFromResponse(decoded: unknown): string[] {
  const rows: readonly unknown[] = Array.isArray(decoded) ? decoded : [decoded]
  return rows
    .map((row) => {
      if (!row || typeof row !== 'object' || !('root' in row) || !('fileSystem' in row)) {
        return ''
      }
      const root = row.root
      const fileSystem = row.fileSystem
      if (typeof root !== 'string' || typeof fileSystem !== 'string') return ''
      if (!fileSystem.trim() || fileSystem.trim().toLowerCase() === 'refs') return ''
      return root
    })
    .filter((root) => path.win32.isAbsolute(root))
}

export function moveDestinationForParent(
  sourceInstallation: string,
  destinationParent: string,
): string {
  return path.win32.join(destinationParent, path.win32.basename(sourceInstallation))
}

function opaqueId(...values: string[]): string {
  return createHash('sha256').update(values.join('\0')).digest('hex').slice(0, 32)
}

function uppercaseGuid(): string {
  return randomUUID().replaceAll('-', '').toUpperCase()
}

function stringValue(value: unknown): string {
  return typeof value === 'string' ? value : ''
}

function numberValue(value: unknown): number {
  return typeof value === 'number' && Number.isFinite(value) && value >= 0 ? value : 0
}

function jsonObject(text: string): Record<string, unknown> {
  const decoded: unknown = JSON.parse(text.charCodeAt(0) === 0xfeff ? text.slice(1) : text)
  if (!decoded || typeof decoded !== 'object' || Array.isArray(decoded)) {
    throw new Error('Expected a JSON object')
  }
  return decoded as Record<string, unknown>
}

function pathPrefix(value: unknown, oldRoot: string, newRoot: string): unknown {
  if (typeof value !== 'string') return value
  const normalizedValue = value.replaceAll('/', '\\')
  const normalizedOld = oldRoot.replaceAll('/', '\\')
  const valueLower = normalizedValue.toLowerCase()
  const rootLower = normalizedOld.toLowerCase()
  if (valueLower !== rootLower && !valueLower.startsWith(`${rootLower}\\`)) return value
  return `${newRoot}${normalizedValue.slice(normalizedOld.length)}`
}

function patchItemLocation(
  value: Record<string, unknown>,
  oldRoot: string,
  newRoot: string,
): Record<string, unknown> {
  const patched = structuredClone(value)
  patched.InstallLocation = newRoot
  for (const key of [
    'ManifestLocation',
    'CompleteManifestPath',
    'PendingManifestPath',
    'StagingLocation',
  ]) {
    patched[key] = pathPrefix(patched[key], oldRoot, newRoot)
  }
  return patched
}

function launcherPaths(environment: NodeJS.ProcessEnv): {
  manifests: string
  installed: string
} {
  const programData = environment.ProgramData || environment.PROGRAMDATA || 'C:\\ProgramData'
  return {
    manifests: path.win32.join(programData, 'Epic', 'EpicGamesLauncher', 'Data', 'Manifests'),
    installed: path.win32.join(
      programData,
      'Epic',
      'UnrealEngineLauncher',
      'LauncherInstalled.dat',
    ),
  }
}

async function atomicWrite(filePath: string, contents: string | Uint8Array): Promise<void> {
  await mkdir(path.dirname(filePath), { recursive: true })
  const temporary = `${filePath}.${process.pid}.${randomUUID()}.tmp`
  try {
    await writeFile(temporary, contents)
    await rename(temporary, filePath)
  } catch (error) {
    await rm(temporary, { force: true }).catch(() => undefined)
    throw error
  }
}

async function readLauncherInstalled(filePath: string): Promise<LauncherInstalledDocument> {
  try {
    const decoded = jsonObject(await readFile(filePath, 'utf8'))
    const list = Array.isArray(decoded.InstallationList) ? decoded.InstallationList : []
    return {
      ...decoded,
      InstallationList: list
        .filter((entry): entry is Record<string, unknown> =>
          Boolean(entry && typeof entry === 'object' && !Array.isArray(entry)),
        )
        .map((entry) => ({ ...entry })),
    }
  } catch (error) {
    if (isNodeError(error, 'ENOENT')) return { InstallationList: [] }
    throw error
  }
}

async function loadParser(): Promise<ParserModule> {
  const parser = (await import('@egdata/manifests-parser')) as ParserModule
  return parser
}

async function launcherRunning(): Promise<boolean> {
  const { stdout } = await execFileAsync(
    'tasklist.exe',
    ['/FI', 'IMAGENAME eq EpicGamesLauncher.exe', '/FO', 'CSV', '/NH'],
    { timeout: 5_000, windowsHide: true, maxBuffer: 64 * 1024 },
  )
  return stdout.toLowerCase().includes('epicgameslauncher.exe')
}

async function requestLauncherClose(): Promise<boolean> {
  const command = [
    '$ErrorActionPreference="SilentlyContinue"',
    '$processes = @(Get-Process -Name "EpicGamesLauncher" -ErrorAction SilentlyContinue)',
    'foreach ($process in $processes) {',
    'if (($null -ne $process) -and ($process.MainWindowHandle -ne 0)) {',
    '[void]$process.CloseMainWindow()',
    '}',
    '}',
  ].join('; ')
  await execFileAsync('powershell.exe', ['-NoProfile', '-NonInteractive', '-Command', command], {
    timeout: 5_000,
    windowsHide: true,
    maxBuffer: 64 * 1024,
  })
  for (let attempt = 0; attempt < 40; attempt += 1) {
    if (!(await launcherRunning())) return true
    await new Promise((resolve) => setTimeout(resolve, 250))
  }
  return false
}

function assertSafeInstallDirectory(directory: string): void {
  if (!path.win32.isAbsolute(directory)) throw new Error('The installation path is invalid.')
  const normalized = path.win32.normalize(directory).replace(/[\\/]+$/, '')
  if (
    !path.win32.basename(normalized) ||
    normalized === path.win32.parse(normalized).root.replace(/[\\/]+$/, '')
  ) {
    throw new Error('A drive root cannot be moved.')
  }
}

function existingChildFile(root: string, relative: string): boolean {
  if (!relative || path.win32.isAbsolute(relative)) return false
  const resolvedRoot = path.win32.resolve(root)
  const resolvedFile = path.win32.resolve(root, relative)
  const rootPrefix = `${normalizeWindowsPath(resolvedRoot)}\\`
  if (!normalizeWindowsPath(resolvedFile).startsWith(rootPrefix)) return false
  try {
    return statSync(resolvedFile).isFile()
  } catch {
    return false
  }
}

async function listFiles(
  root: string,
  signal?: AbortSignal,
): Promise<Array<{ relative: string; size: number }>> {
  const result: Array<{ relative: string; size: number }> = []
  const pending = ['']
  while (pending.length) {
    if (signal?.aborted) throw new DOMException('Cancelled', 'AbortError')
    const relativeDirectory = pending.shift()!
    const directory = path.join(root, relativeDirectory)
    const entries = await readdir(directory, { withFileTypes: true })
    for (const entry of entries) {
      if (entry.isSymbolicLink()) throw new Error('The game folder contains a link or junction.')
      const relative = path.join(relativeDirectory, entry.name)
      if (entry.isDirectory()) pending.push(relative)
      else if (entry.isFile())
        result.push({ relative, size: (await stat(path.join(root, relative))).size })
    }
  }
  return result
}

async function copyTree(
  source: string,
  destination: string,
  files: Array<{ relative: string; size: number }>,
  operation: MoveOperation,
  emit: () => void,
): Promise<void> {
  await mkdir(destination, { recursive: true })
  let lastEmit = 0
  for (const file of files) {
    if (operation.controller.signal.aborted) throw new DOMException('Cancelled', 'AbortError')
    const target = path.join(destination, file.relative)
    await mkdir(path.dirname(target), { recursive: true })
    await copyFile(path.join(source, file.relative), target)
    operation.snapshot.copiedFiles += 1
    operation.snapshot.copiedBytes += file.size
    if (Date.now() - lastEmit > 50) {
      emit()
      lastEmit = Date.now()
    }
  }
  emit()
}

async function verifyFiles(
  destination: string,
  files: Array<{ relative: string; size: number }>,
): Promise<void> {
  for (const file of files) {
    const details = await stat(path.join(destination, file.relative))
    if (!details.isFile() || details.size !== file.size) {
      throw new Error('The copied game failed verification.')
    }
  }
}

export class LibraryToolsService {
  readonly #platform: NodeJS.Platform
  readonly #environment: NodeJS.ProcessEnv
  readonly #userData: string
  readonly #fetch: typeof fetch
  readonly #isLauncherRunning: () => Promise<boolean>
  readonly #requestLauncherClose: () => Promise<boolean>
  readonly #parseManifest: (filePath: string) => Promise<Manifest>
  readonly #resolveLauncherRecords: LocalLauncherResolver | undefined
  readonly #paths: ReturnType<typeof launcherPaths>
  readonly #onChanged: ((snapshot: LibraryToolsSnapshot) => void) | undefined
  readonly #registered = new Map<string, RegisteredGroup>()
  readonly #candidateGroups = new Map<string, CandidateGroup>()
  #snapshot: LibraryToolsSnapshot
  #scanController: AbortController | null = null
  #scanFinished: Promise<void> | null = null
  #finishScan: (() => void) | null = null
  #moveOperation: MoveOperation | null = null
  #startupTimer: NodeJS.Timeout | null = null
  #dailyTimer: NodeJS.Timeout | null = null
  #driveTimer: NodeJS.Timeout | null = null
  #knownDrives = new Set<string>()
  #registeredDiscoveryComplete = false

  constructor(options: LibraryToolsServiceOptions) {
    this.#platform = options.platform
    this.#environment = options.environment ?? process.env
    this.#userData = options.userData
    this.#fetch = options.fetchImpl ?? fetch
    this.#isLauncherRunning = options.isLauncherRunning ?? launcherRunning
    this.#requestLauncherClose = options.requestLauncherClose ?? requestLauncherClose
    this.#parseManifest =
      options.parseManifest ??
      (async (filePath) => (await loadParser()).parseManifestAsync(filePath))
    this.#resolveLauncherRecords = options.resolveLauncherRecords
    this.#paths = launcherPaths(this.#environment)
    this.#onChanged = options.onChanged
    this.#snapshot = {
      available: this.#platform === 'win32',
      state: 'idle',
      registeredGames: [],
      candidates: [],
      issues: [],
    }
  }

  get snapshot(): LibraryToolsSnapshot {
    return structuredClone(this.#snapshot)
  }

  catalogInterests(): LibraryToolsCatalogInterest[] {
    const interests = new Map<string, LibraryToolsCatalogInterest>()
    const add = (interest: LibraryToolsCatalogInterest): void => {
      const key = [
        interest.namespace,
        interest.catalogItemId,
        interest.artifactId,
        interest.appName,
      ].join('\u0000')
      interests.set(key, interest)
    }
    for (const group of this.#registered.values()) {
      for (const source of group.sources) {
        const namespace =
          stringValue(source.value.CatalogNamespace) || stringValue(source.value.NamespaceId)
        if (!namespace) continue
        const catalogItemId =
          stringValue(source.value.CatalogItemId) || stringValue(source.value.ItemId)
        const artifactId = stringValue(source.value.ArtifactId) || stringValue(source.value.AppName)
        add({
          namespace,
          ...(catalogItemId ? { catalogItemId } : {}),
          ...(artifactId ? { artifactId, appName: artifactId } : {}),
          platform: 'Windows',
        })
      }
    }
    for (const group of this.#candidateGroups.values()) {
      for (const candidate of group.records) {
        const record = candidate.resolution?.record
        const namespace = record?.catalogNamespace ?? candidate.hint?.catalogNamespace
        if (!namespace) continue
        const catalogItemId = record?.catalogItemId ?? candidate.hint?.catalogItemId
        const artifactId = record?.artifactId ?? candidate.hint?.artifactId
        const appName = candidate.manifest.meta?.appName?.trim()
        add({
          namespace,
          ...(catalogItemId ? { catalogItemId } : {}),
          ...(artifactId ? { artifactId } : {}),
          ...(appName ? { appName } : {}),
          platform: 'Windows',
        })
      }
    }
    return [...interests.values()]
  }

  get catalogInterestsReady(): boolean {
    return this.#registeredDiscoveryComplete
  }

  async isLauncherOpen(): Promise<boolean> {
    return this.#platform === 'win32' && (await this.#isLauncherRunning())
  }

  async tryCloseLauncher(): Promise<boolean> {
    if (this.#platform !== 'win32') return true
    return this.#requestLauncherClose()
  }

  async initialize(autoScan: boolean): Promise<void> {
    if (this.#platform !== 'win32') return
    await this.#refreshRegistered()
    if (autoScan) this.startScheduler()
  }

  startScheduler(): void {
    if (this.#platform !== 'win32' || this.#startupTimer) return
    this.#startupTimer = setTimeout(
      () => void this.scan().catch(() => undefined),
      STARTUP_SCAN_DELAY_MS,
    )
    this.#dailyTimer = setInterval(() => void this.scan().catch(() => undefined), DAY_MS)
    this.#driveTimer = setInterval(() => void this.#detectNewDrives(), DRIVE_POLL_MS)
    void this.#listDrives(true).then((drives) => {
      this.#knownDrives = new Set(drives.map((drive) => drive.toLowerCase()))
    })
  }

  stopScheduler(): void {
    if (this.#startupTimer) clearTimeout(this.#startupTimer)
    if (this.#dailyTimer) clearInterval(this.#dailyTimer)
    if (this.#driveTimer) clearInterval(this.#driveTimer)
    this.#startupTimer = null
    this.#dailyTimer = null
    this.#driveTimer = null
    this.#scanController?.abort()
  }

  dispose(): void {
    this.stopScheduler()
    this.#moveOperation?.controller.abort()
  }

  async scan(roots?: string[]): Promise<LibraryToolsSnapshot> {
    if (this.#platform !== 'win32') return this.snapshot
    if (this.#snapshot.state !== 'idle' || this.#moveIsActive()) {
      throw new Error('Library tools are already working.')
    }
    this.#scanFinished = new Promise((resolve) => {
      this.#finishScan = resolve
    })
    this.#scanController = new AbortController()
    this.#snapshot = { ...this.#snapshot, state: 'scanning', issues: [] }
    this.#emit()
    try {
      await this.#refreshRegistered()
      const discoveredRoots = roots ?? (await this.#listDrives())
      const registeredDriveRoots = new Set(
        [...this.#registered.values()].map((group) =>
          normalizeWindowsPath(path.win32.parse(group.installLocation).root),
        ),
      )
      const scanRoots = [...discoveredRoots].sort(
        (left, right) =>
          Number(registeredDriveRoots.has(normalizeWindowsPath(right))) -
          Number(registeredDriveRoots.has(normalizeWindowsPath(left))),
      )
      const egstores: string[] = []
      let directoriesChecked = 0
      this.#setScanProgress({
        phase: 'discovering',
        drivesCompleted: 0,
        totalDrives: scanRoots.length,
        directoriesChecked,
        manifestDirectories: 0,
        manifestsParsed: 0,
      })
      for (const [index, root] of scanRoots.entries()) {
        this.#setScanProgress({
          phase: 'discovering',
          drivesCompleted: index,
          totalDrives: scanRoots.length,
          directoriesChecked,
          manifestDirectories: egstores.length,
          manifestsParsed: 0,
          currentDrive: path.win32.parse(root).root,
        })
        const discovery = await this.#findEgstores(root, this.#scanController.signal)
        egstores.push(...discovery.egstores)
        directoriesChecked += discovery.directoriesChecked
      }
      const records: CandidateRecord[] = []
      for (const [index, egstore] of egstores.entries()) {
        this.#setScanProgress({
          phase: 'parsing',
          drivesCompleted: scanRoots.length,
          totalDrives: scanRoots.length,
          directoriesChecked,
          manifestDirectories: egstores.length,
          manifestsParsed: index,
        })
        records.push(...(await this.#parseEgstore(egstore, this.#scanController.signal)))
      }
      this.#setScanProgress({
        phase: 'resolving',
        drivesCompleted: scanRoots.length,
        totalDrives: scanRoots.length,
        directoriesChecked,
        manifestDirectories: egstores.length,
        manifestsParsed: records.length,
      })
      await this.#resolveRecords(records, this.#scanController.signal)
      this.#buildCandidateGroups(records)
      const snapshotWithoutProgress = structuredClone(this.#snapshot)
      delete snapshotWithoutProgress.scanProgress
      this.#snapshot = {
        ...snapshotWithoutProgress,
        state: 'idle',
        scannedAt: new Date().toISOString(),
        candidates: [...this.#candidateGroups.values()].map((group) => group.public),
      }
    } catch (error) {
      if (!isAbortError(error)) {
        this.#snapshot.issues = ['The Windows drive scan could not be completed.']
      }
      const snapshotWithoutProgress = structuredClone(this.#snapshot)
      delete snapshotWithoutProgress.scanProgress
      this.#snapshot = { ...snapshotWithoutProgress, state: 'idle' }
    } finally {
      this.#scanController = null
      this.#emit()
      this.#finishScan?.()
      this.#finishScan = null
      this.#scanFinished = null
    }
    return this.snapshot
  }

  async cancelScan(): Promise<LibraryToolsSnapshot> {
    const finished = this.#scanFinished
    this.#scanController?.abort()
    if (finished) await finished
    return this.snapshot
  }

  async recover(candidateIds: string[]): Promise<LibraryToolsSnapshot> {
    if (this.#platform !== 'win32') return this.snapshot
    if (this.#snapshot.state !== 'idle' || this.#moveIsActive()) {
      throw new Error('Library tools are already working.')
    }
    if (await this.#isLauncherRunning()) {
      throw new Error('Close Epic Games Launcher before recovery.')
    }
    const groups = candidateIds.map((id) => this.#candidateGroups.get(id))
    if (groups.some((group) => !group?.public.recoverable)) {
      throw new Error('A selected recovery candidate is no longer available.')
    }
    this.#snapshot.state = 'recovering'
    this.#emit()
    const targets: Array<{ path: string; contents: string }> = []
    try {
      const installed = await readLauncherInstalled(this.#paths.installed)
      for (const group of groups as CandidateGroup[]) {
        for (const record of group.records) {
          if (record.resolution?.status !== 'resolved' || !record.resolution.record) continue
          const details = await stat(record.manifestPath)
          if (details.size !== record.manifestSize || details.mtimeMs !== record.manifestMtimeMs) {
            throw new Error('A discovered manifest changed. Scan the drives again.')
          }
          const reparsed = await this.#parseManifest(record.manifestPath)
          if (
            reparsed.header.sha1Hash !== record.manifest.header.sha1Hash ||
            reparsed.meta?.appName !== record.manifest.meta?.appName ||
            reparsed.meta?.buildVersion !== record.manifest.meta?.buildVersion
          ) {
            throw new Error('A discovered manifest changed. Scan the drives again.')
          }
          record.manifest = reparsed
          const item = this.#createItem(group.installLocation, record)
          targets.push({
            path: path.join(this.#paths.manifests, `${record.installationGuid}.item`),
            contents: `${JSON.stringify(item, null, 2)}\n`,
          })
          const metadata = record.resolution.record
          installed.InstallationList = installed.InstallationList.filter(
            (entry) => stringValue(entry.AppName) !== metadata.artifactId,
          )
          installed.InstallationList.push({
            InstallLocation: group.installLocation,
            NamespaceId: metadata.catalogNamespace,
            ItemId: metadata.catalogItemId,
            ArtifactId: metadata.artifactId,
            AppVersion: record.manifest.meta?.buildVersion ?? '',
            AppName: metadata.artifactId,
          })
        }
      }
      targets.push({
        path: this.#paths.installed,
        contents: `${JSON.stringify(installed, null, 2)}\n`,
      })
      if (await this.#isLauncherRunning()) {
        throw new Error('Close Epic Games Launcher before recovery.')
      }
      await this.#transactionalWrite(targets)
      await this.#refreshRegistered()
      for (const id of candidateIds) this.#candidateGroups.delete(id)
      this.#snapshot.candidates = [...this.#candidateGroups.values()].map((group) => group.public)
    } finally {
      this.#snapshot.state = 'idle'
      this.#emit()
    }
    return this.snapshot
  }

  async prepareMove(gameId: string, destinationParent: string): Promise<MoveSnapshot> {
    if (this.#platform !== 'win32') throw new Error('Game moving is available on Windows only.')
    if (
      this.#moveOperation &&
      !['complete', 'cancelled', 'failed'].includes(this.#moveOperation.snapshot.state)
    ) {
      throw new Error('A game move is already active.')
    }
    if (await this.#isLauncherRunning()) {
      throw new Error('Close Epic Games Launcher before moving a game.')
    }
    const game = this.#registered.get(gameId)
    if (!game?.public.movable) throw new Error('This game cannot be moved.')
    assertSafeInstallDirectory(game.installLocation)
    const destinationDetails = await lstat(destinationParent)
    if (!destinationDetails.isDirectory() || destinationDetails.isSymbolicLink()) {
      throw new Error('Choose a regular destination folder.')
    }
    const destinationLocation = moveDestinationForParent(game.installLocation, destinationParent)
    assertSafeInstallDirectory(destinationLocation)
    if (normalizeWindowsPath(destinationLocation) === normalizeWindowsPath(game.installLocation)) {
      throw new Error('The destination is the current game location.')
    }
    if (
      normalizeWindowsPath(destinationLocation).startsWith(
        `${normalizeWindowsPath(game.installLocation)}\\`,
      )
    ) {
      throw new Error('The destination cannot be inside the game folder.')
    }
    try {
      await access(destinationLocation)
      throw new Error('A folder with this game name already exists at the destination.')
    } catch (error) {
      if (!isNodeError(error, 'ENOENT')) throw error
    }
    const files = await listFiles(game.installLocation)
    if (!files.some((file) => file.relative.toLowerCase().startsWith(`.egstore${path.sep}`))) {
      throw new Error('The installation is missing its .egstore data.')
    }
    const totalBytes = files.reduce((sum, file) => sum + file.size, 0)
    const sameVolume =
      path.parse(game.installLocation).root.toLowerCase() ===
      path.parse(destinationLocation).root.toLowerCase()
    if (!sameVolume) {
      const available = await statfs(destinationParent)
      if (available.bavail * available.bsize < Math.ceil(totalBytes * 1.05)) {
        throw new Error('The destination does not have enough free space.')
      }
    }
    const operationId = randomUUID()
    const snapshot: MoveSnapshot = {
      operationId,
      gameId,
      displayName: game.public.displayName,
      state: 'prepared',
      sourceLocation: game.installLocation,
      destinationLocation,
      copiedBytes: 0,
      totalBytes,
      copiedFiles: 0,
      totalFiles: files.length,
      restartLauncher: false,
    }
    this.#moveOperation = {
      game,
      destinationParent,
      destinationLocation,
      controller: new AbortController(),
      snapshot,
    }
    this.#snapshot.move = snapshot
    this.#emit()
    return structuredClone(snapshot)
  }

  async startMove(operationId: string): Promise<LibraryToolsSnapshot> {
    const operation = this.#moveOperation
    if (
      !operation ||
      operation.snapshot.operationId !== operationId ||
      operation.snapshot.state !== 'prepared'
    ) {
      throw new Error('The prepared move has expired.')
    }
    if (await this.#isLauncherRunning()) {
      throw new Error('Close Epic Games Launcher before moving a game.')
    }
    const source = operation.game.installLocation
    const destination = operation.destinationLocation
    const sameVolume =
      path.parse(source).root.toLowerCase() === path.parse(destination).root.toLowerCase()
    const files = await listFiles(source, operation.controller.signal)
    const staging = path.join(operation.destinationParent, `.egdata-moving-${operationId}`)
    let folderMoved = false
    try {
      operation.snapshot.state = 'copying'
      this.#emitMove()
      if (sameVolume) {
        await rename(source, destination)
        folderMoved = true
        operation.snapshot.copiedBytes = operation.snapshot.totalBytes
        operation.snapshot.copiedFiles = operation.snapshot.totalFiles
      } else {
        await copyTree(source, staging, files, operation, () => this.#emitMove())
        await verifyFiles(staging, files)
        await rename(staging, destination)
        folderMoved = true
      }
      operation.snapshot.state = 'updating-launcher'
      this.#emitMove()
      if (await this.#isLauncherRunning()) {
        throw new Error('Epic Games Launcher was opened during the move.')
      }
      await this.#commitMoveMetadata(operation.game, destination)
      if (!sameVolume) {
        operation.snapshot.state = 'deleting-source'
        this.#emitMove()
        try {
          assertSafeInstallDirectory(source)
          await rm(source, { recursive: true })
        } catch {
          operation.snapshot.warning =
            'The game was moved, but the old copy could not be fully removed.'
        }
      }
      operation.snapshot.state = 'complete'
      operation.snapshot.restartLauncher = true
      await this.#refreshRegistered()
    } catch (error) {
      const cancelled = error instanceof DOMException && error.name === 'AbortError'
      if (!folderMoved) await rm(staging, { recursive: true, force: true }).catch(() => undefined)
      if (folderMoved && sameVolume) {
        await rename(destination, source).catch(() => undefined)
      } else if (folderMoved) {
        await rm(destination, { recursive: true, force: true }).catch(() => undefined)
      }
      operation.snapshot.state = cancelled ? 'cancelled' : 'failed'
      if (!cancelled)
        operation.snapshot.error = safeError('The game move failed and was rolled back.', true)
    }
    this.#emitMove()
    return this.snapshot
  }

  cancelMove(operationId: string): LibraryToolsSnapshot {
    if (this.#moveOperation?.snapshot.operationId === operationId) {
      if (this.#moveOperation.snapshot.state === 'prepared') {
        this.#moveOperation.snapshot.state = 'cancelled'
        this.#emitMove()
      } else {
        this.#moveOperation.controller.abort()
      }
    }
    return this.snapshot
  }

  #moveIsActive(): boolean {
    return Boolean(
      this.#moveOperation &&
      !['complete', 'cancelled', 'failed'].includes(this.#moveOperation.snapshot.state),
    )
  }

  async #refreshRegistered(): Promise<void> {
    this.#registered.clear()
    let entries
    try {
      entries = await readdir(this.#paths.manifests, { withFileTypes: true })
      this.#registeredDiscoveryComplete = true
    } catch (error) {
      this.#registeredDiscoveryComplete = isNodeError(error, 'ENOENT')
      this.#snapshot.registeredGames = []
      return
    }
    const groups = new Map<string, RegisteredSource[]>()
    for (const entry of entries) {
      if (!entry.isFile() || !entry.name.toLowerCase().endsWith('.item')) continue
      try {
        const itemPath = path.join(this.#paths.manifests, entry.name)
        const rawText = await readFile(itemPath, 'utf8')
        const value = jsonObject(rawText)
        const installLocation = stringValue(value.InstallLocation)
        if (!installLocation) continue
        const key = normalizeWindowsPath(installLocation)
        const sources = groups.get(key) ?? []
        sources.push({ itemPath, rawText, value })
        groups.set(key, sources)
      } catch {
        // Existing malformed launcher records remain untouched and non-movable.
      }
    }
    for (const [key, sources] of groups) {
      const base =
        sources.find((source) => {
          const categories = source.value.AppCategories
          return Array.isArray(categories) && categories.includes('games')
        }) ?? sources[0]!
      const installLocation = stringValue(base.value.InstallLocation)
      const id = opaqueId('registered', key)
      const exists = await stat(installLocation)
        .then((details) => details.isDirectory())
        .catch(() => false)
      const publicGame: LibraryGame = {
        id,
        displayName:
          stringValue(base.value.DisplayName) || stringValue(base.value.AppName) || 'Epic game',
        appName: stringValue(base.value.AppName),
        installLocation,
        installSize: Math.max(...sources.map((source) => numberValue(source.value.InstallSize)), 0),
        recordCount: sources.length,
        movable: exists,
        ...(!exists ? { issue: 'The installation folder is missing.' } : {}),
      }
      this.#registered.set(id, { id, installLocation, sources, public: publicGame })
    }
    this.#snapshot.registeredGames = [...this.#registered.values()].map((group) => group.public)
  }

  async #listDrives(lightweight = false): Promise<string[]> {
    const command = lightweight
      ? [
          '$ErrorActionPreference="Stop"',
          '[System.IO.DriveInfo]::GetDrives()',
          '| Where-Object { $_.IsReady -and $_.DriveType -in @([System.IO.DriveType]::Fixed,[System.IO.DriveType]::Removable) -and $_.DriveFormat -and $_.DriveFormat -ine "ReFS" }',
          '| ForEach-Object { [pscustomobject]@{ root = $_.RootDirectory.FullName; fileSystem = $_.DriveFormat } }',
          '| ConvertTo-Json -Compress',
        ].join(' ')
      : [
          '$ErrorActionPreference="Stop"',
          'Get-CimInstance Win32_Volume',
          '| Where-Object { $_.DriveType -in @(2,3) -and $_.DriveLetter -and $_.FileSystem -and $_.FileSystem -ine "ReFS" -and ($null -eq $_.Status -or $_.Status -eq "OK") }',
          '| ForEach-Object { [pscustomobject]@{ root = ($_.DriveLetter + "\\"); fileSystem = $_.FileSystem } }',
          '| ConvertTo-Json -Compress',
        ].join(' ')
    try {
      const { stdout } = await execFileAsync(
        'powershell.exe',
        ['-NoProfile', '-NonInteractive', '-Command', command],
        { timeout: 10_000, windowsHide: true, maxBuffer: 256 * 1024 },
      )
      if (!stdout.trim()) return []
      const decoded: unknown = JSON.parse(stdout)
      return driveRootsFromResponse(decoded)
    } catch {
      return lightweight ? [] : this.#listDrives(true)
    }
  }

  async #detectNewDrives(): Promise<void> {
    if (this.#snapshot.state !== 'idle') return
    const drives = await this.#listDrives(true)
    const added = drives.filter((drive) => !this.#knownDrives.has(drive.toLowerCase()))
    this.#knownDrives = new Set(drives.map((drive) => drive.toLowerCase()))
    if (added.length) await this.scan(added)
  }

  async #findEgstores(
    root: string,
    signal: AbortSignal,
  ): Promise<{ egstores: string[]; directoriesChecked: number }> {
    const scopes = discoveryScopesForRoot(
      root,
      this.#environment,
      [...this.#registered.values()].map((group) => group.installLocation),
    )
    const egstores = new Set<string>()
    let directoriesChecked = 0
    for (const scope of scopes) {
      if (signal.aborted) throw new DOMException('Cancelled', 'AbortError')
      const exists = await stat(scope.root)
        .then((details) => details.isDirectory())
        .catch(() => false)
      if (!exists) continue
      const result = await this.#findEgstoresInScope(scope, signal)
      result.egstores.forEach((directory) => egstores.add(directory))
      directoriesChecked += result.directoriesChecked
    }
    return { egstores: [...egstores], directoriesChecked }
  }

  async #findEgstoresInScope(
    scope: DiscoveryScope,
    signal: AbortSignal,
  ): Promise<{ egstores: string[]; directoriesChecked: number }> {
    const { root, maxDepth } = scope
    try {
      const nativeResult = await scanWindowsEgstores(root, signal, maxDepth)
      if (nativeResult) {
        const normalizedRoot = `${normalizeWindowsPath(root)}\\`
        return {
          egstores: nativeResult.egstores.filter(
            (directory) =>
              path.win32.isAbsolute(directory) &&
              normalizeWindowsPath(directory).startsWith(normalizedRoot) &&
              path.win32.basename(directory).toLowerCase() === '.egstore',
          ),
          directoriesChecked: nativeResult.directoriesChecked,
        }
      }
    } catch (error) {
      if (isAbortError(error)) throw error
      // An unavailable or incompatible binding falls back to managed traversal.
    }

    const command = [
      '$ErrorActionPreference="Stop"',
      '$root = $env:EGDATA_LIBRARY_SCAN_ROOT',
      '$maxDepth = [int]$env:EGDATA_LIBRARY_SCAN_MAX_DEPTH',
      '$stack = [System.Collections.Generic.Stack[object]]::new()',
      '$found = [System.Collections.Generic.List[string]]::new()',
      '$skip = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)',
      "[void]$skip.Add('$Recycle.Bin')",
      "[void]$skip.Add('System Volume Information')",
      "[void]$skip.Add('Windows')",
      "[void]$skip.Add('Recovery')",
      "[void]$skip.Add('MSOCache')",
      '$checked = 0',
      '$stack.Push([pscustomobject]@{ path = $root; depth = 0 })',
      'while ($stack.Count -gt 0) {',
      '$entry = $stack.Pop()',
      '$directory = [string]$entry.path',
      '$depth = [int]$entry.depth',
      '$checked += 1',
      'try { $children = @([System.IO.Directory]::EnumerateDirectories($directory)) } catch { continue }',
      'foreach ($child in $children) {',
      'try {',
      '$info = [System.IO.DirectoryInfo]::new($child)',
      'if (($info.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { continue }',
      '$name = $info.Name',
      'if ($skip.Contains($name)) { continue }',
      "if ($name -ieq '.egstore') {",
      "try { foreach ($manifest in [System.IO.Directory]::EnumerateFiles($child, '*.manifest', [System.IO.SearchOption]::TopDirectoryOnly)) { [void]$found.Add($manifest) } } catch { }",
      '} elseif ($maxDepth -lt 0 -or $depth -lt $maxDepth) { $stack.Push([pscustomobject]@{ path = $child; depth = ($depth + 1) }) }',
      '} catch { continue }',
      '}',
      '}',
      '$result = [pscustomobject]@{ directoriesChecked = $checked; manifests = @($found) }',
      '$result | ConvertTo-Json -Depth 3 -Compress',
    ].join('; ')
    try {
      const { stdout } = await execFileAsync(
        'powershell.exe',
        ['-NoProfile', '-NonInteractive', '-Command', command],
        {
          timeout: 30 * 60 * 1_000,
          windowsHide: true,
          maxBuffer: 32 * 1024 * 1024,
          signal,
          env: {
            ...this.#environment,
            EGDATA_LIBRARY_SCAN_ROOT: root,
            EGDATA_LIBRARY_SCAN_MAX_DEPTH: maxDepth?.toString() ?? '-1',
          },
        },
      )
      const decoded: unknown = JSON.parse(stdout)
      if (!decoded || typeof decoded !== 'object' || Array.isArray(decoded)) {
        throw new Error('Invalid drive scan response')
      }
      const response = decoded as { directoriesChecked?: unknown; manifests?: unknown }
      const manifests = Array.isArray(response.manifests) ? response.manifests : []
      const normalizedRoot = `${normalizeWindowsPath(root)}\\`
      const egstores = new Set<string>()
      for (const manifest of manifests) {
        if (typeof manifest !== 'string' || !path.win32.isAbsolute(manifest)) continue
        if (!normalizeWindowsPath(manifest).startsWith(normalizedRoot)) continue
        const directory = path.win32.dirname(manifest)
        if (path.win32.basename(directory).toLowerCase() === '.egstore') egstores.add(directory)
      }
      return {
        egstores: [...egstores],
        directoriesChecked:
          typeof response.directoriesChecked === 'number' &&
          Number.isSafeInteger(response.directoriesChecked) &&
          response.directoriesChecked >= 0
            ? response.directoriesChecked
            : 0,
      }
    } catch (error) {
      if (isAbortError(error)) throw error
      return this.#findEgstoresWithNode(root, signal, maxDepth)
    }
  }

  async #findEgstoresWithNode(
    root: string,
    signal: AbortSignal,
    maxDepth?: number,
  ): Promise<{ egstores: string[]; directoriesChecked: number }> {
    const result: string[] = []
    const pending = [{ directory: root, depth: 0 }]
    let directoriesChecked = 0
    while (pending.length) {
      if (signal.aborted) throw new DOMException('Cancelled', 'AbortError')
      const { directory, depth } = pending.shift()!
      directoriesChecked += 1
      let entries
      try {
        entries = await readdir(directory, { withFileTypes: true })
      } catch {
        continue
      }
      for (const entry of entries) {
        if (!entry.isDirectory() || entry.isSymbolicLink()) continue
        const lower = entry.name.toLowerCase()
        if (lower === '.egstore') {
          result.push(path.join(directory, entry.name))
          continue
        }
        if (SKIPPED_DIRECTORIES.has(lower)) continue
        if (maxDepth === undefined || depth < maxDepth) {
          pending.push({ directory: path.join(directory, entry.name), depth: depth + 1 })
        }
      }
    }
    return { egstores: result, directoriesChecked }
  }

  async #parseEgstore(egstorePath: string, signal: AbortSignal): Promise<CandidateRecord[]> {
    const entries = await readdir(egstorePath, { withFileTypes: true }).catch(() => [])
    const records: CandidateRecord[] = []
    for (const entry of entries) {
      if (signal.aborted) throw new DOMException('Cancelled', 'AbortError')
      if (!entry.isFile() || !entry.name.toLowerCase().endsWith('.manifest')) continue
      const guid = path.parse(entry.name).name
      if (!GUID_PATTERN.test(guid)) {
        this.#addIssue('A manifest with an invalid filename was skipped.')
        continue
      }
      const manifestPath = path.join(egstorePath, entry.name)
      try {
        const details = await stat(manifestPath)
        const manifest = await this.#parseManifest(manifestPath)
        if (signal.aborted) throw new DOMException('Cancelled', 'AbortError')
        const buildAppName = manifest.meta?.appName?.trim() ?? ''
        if (!buildAppName) continue
        const hint = await this.#readHint(egstorePath, guid)
        records.push({
          requestId: randomUUID(),
          manifestPath,
          egstorePath,
          installationGuid: guid.toUpperCase(),
          manifestSize: details.size,
          manifestMtimeMs: details.mtimeMs,
          manifest,
          ...(hint ? { hint } : {}),
        })
      } catch (error) {
        if (error instanceof DOMException && error.name === 'AbortError') throw error
        this.#addIssue('A malformed binary manifest was skipped.')
      }
    }
    return records
  }

  async #readHint(egstore: string, guid: string): Promise<LauncherCatalogHint | null> {
    try {
      const value = jsonObject(await readFile(path.join(egstore, `${guid}.mancpn`), 'utf8'))
      const hint = {
        artifactId: stringValue(value.AppName),
        catalogItemId: stringValue(value.CatalogItemId),
        catalogNamespace: stringValue(value.CatalogNamespace),
      }
      return Object.values(hint).every(Boolean) ? hint : null
    } catch {
      return null
    }
  }

  async #resolveRecords(records: CandidateRecord[], signal: AbortSignal): Promise<void> {
    for (let offset = 0; offset < records.length; offset += 100) {
      if (signal.aborted) throw new DOMException('Cancelled', 'AbortError')
      const batch = records.slice(offset, offset + 100)
      const candidates = batch.map(
        (record): LauncherResolverCandidate => ({
          requestId: record.requestId,
          buildAppName: record.manifest.meta?.appName ?? '',
          buildVersion: record.manifest.meta?.buildVersion ?? '',
          platform: 'Windows',
          ...(record.hint ? { catalogHint: record.hint } : {}),
        }),
      )
      let localResults: readonly LauncherResolverResult[] = []
      if (this.#resolveLauncherRecords) {
        try {
          localResults = await this.#resolveLauncherRecords(candidates)
        } catch {
          // A local catalog failure must not prevent the live resolver fallback.
        }
      }
      if (signal.aborted) throw new DOMException('Cancelled', 'AbortError')
      const localById = new Map(localResults.map((result) => [result.requestId, result]))
      for (const record of batch) {
        const local = localById.get(record.requestId)
        if (local?.status === 'resolved' && local.record) record.resolution = local
      }
      const unresolvedBatch = batch.filter((record) => record.resolution?.status !== 'resolved')
      if (unresolvedBatch.length === 0) continue
      const controller = new AbortController()
      const timeout = setTimeout(() => controller.abort(), 20_000)
      try {
        const response = await this.#fetch(RESOLVER_ENDPOINT, {
          method: 'POST',
          headers: { 'content-type': 'application/json' },
          body: JSON.stringify({
            candidates: unresolvedBatch.map((record) => ({
              requestId: record.requestId,
              buildAppName: record.manifest.meta?.appName ?? '',
              buildVersion: record.manifest.meta?.buildVersion ?? '',
              platform: 'Windows',
              ...(record.hint ? { catalogHint: record.hint } : {}),
            })),
          }),
          signal: AbortSignal.any([controller.signal, signal]),
        })
        if (!response.ok) throw new Error('Resolver unavailable')
        const decoded: unknown = await response.json()
        const results =
          decoded &&
          typeof decoded === 'object' &&
          'results' in decoded &&
          Array.isArray(decoded.results)
            ? (decoded.results as LauncherResolverResult[])
            : []
        const byId = new Map(results.map((result) => [result.requestId, result]))
        for (const record of unresolvedBatch) {
          record.resolution = byId.get(record.requestId) ??
            localById.get(record.requestId) ?? {
              requestId: record.requestId,
              status: 'not-found',
            }
        }
      } catch {
        for (const record of unresolvedBatch) {
          record.resolution = localById.get(record.requestId) ?? {
            requestId: record.requestId,
            status: 'not-found',
          }
        }
      } finally {
        clearTimeout(timeout)
      }
    }
  }

  #buildCandidateGroups(records: CandidateRecord[]): void {
    this.#candidateGroups.clear()
    const registeredByArtifact = new Map<string, string>()
    const registeredAtRoot = new Map<string, Set<string>>()
    for (const group of this.#registered.values()) {
      for (const source of group.sources) {
        const artifact = stringValue(source.value.AppName)
        if (!artifact) continue
        registeredByArtifact.set(artifact, group.installLocation)
        const key = normalizeWindowsPath(group.installLocation)
        const artifacts = registeredAtRoot.get(key) ?? new Set<string>()
        artifacts.add(artifact)
        registeredAtRoot.set(key, artifacts)
      }
    }
    const byRoot = new Map<string, CandidateRecord[]>()
    for (const record of records) {
      const installLocation = path.dirname(record.egstorePath)
      const key = normalizeWindowsPath(installLocation)
      const group = byRoot.get(key) ?? []
      group.push(record)
      byRoot.set(key, group)
    }
    for (const [key, groupRecords] of byRoot) {
      const installLocation = path.dirname(groupRecords[0]!.egstorePath)
      const allResolved = groupRecords.filter(
        (record) => record.resolution?.status === 'resolved' && record.resolution.record,
      )
      const resolved = allResolved.filter((record) => {
        const current = registeredByArtifact.get(record.resolution!.record!.artifactId)
        return !current || normalizeWindowsPath(current) !== key
      })
      if (!resolved.length && allResolved.length === groupRecords.length) continue
      const representative = resolved[0] ?? allResolved[0] ?? groupRecords[0]!
      const unresolved = groupRecords.filter((record) => record.resolution?.status !== 'resolved')
      const duplicateArtifacts = new Set<string>()
      const artifactCounts = new Map<string, number>()
      for (const record of resolved) {
        const artifact = record.resolution!.record!.artifactId
        artifactCounts.set(artifact, (artifactCounts.get(artifact) ?? 0) + 1)
      }
      for (const [artifact, count] of artifactCounts)
        if (count > 1) duplicateArtifacts.add(artifact)
      const conflicts = resolved.filter((record) => {
        const current = registeredByArtifact.get(record.resolution!.record!.artifactId)
        return current && normalizeWindowsPath(current) !== key
      })
      const bases = resolved.filter((record) => record.resolution!.record!.kind === 'base-game')
      const base = bases[0]
      const executable = base?.manifest.meta?.launchExe ?? ''
      const executablePresent = existingChildFile(installLocation, executable)
      const installedArtifacts = registeredAtRoot.get(key) ?? new Set<string>()
      const linked = resolved.every((record) => {
        const metadata = record.resolution!.record!
        if (metadata.kind === 'base-game') return true
        const parent = metadata.mainGame?.artifactId
        return Boolean(
          parent &&
          ((base && parent === base.resolution!.record!.artifactId) ||
            installedArtifacts.has(parent)),
        )
      })
      let status: RecoveryCandidate['status'] = 'resolved'
      let issue: string | undefined
      if (unresolved.length) {
        const statuses = unresolved.map((record) => record.resolution?.status ?? 'not-found')
        status = statuses.includes('ambiguous')
          ? 'ambiguous'
          : statuses.includes('unsupported')
            ? 'unsupported'
            : 'not-found'
        issue = `${unresolved.length} manifest${unresolved.length === 1 ? '' : 's'} could not be resolved safely.`
      } else if (conflicts.length) {
        status = 'conflict'
        issue = 'A launcher record already points to another installation.'
      } else if (duplicateArtifacts.size) {
        status = 'ambiguous'
        issue = 'Multiple manifests resolve to the same launcher record.'
      } else if (bases.length > 1) {
        status = 'ambiguous'
        issue = 'Multiple base games were found in the same installation folder.'
      } else if (base && !executablePresent) {
        status = 'unsupported'
        issue = 'The base game executable could not be validated.'
      } else if (!linked) {
        status = 'ambiguous'
        issue = 'An add-on could not be linked to this base game.'
      }
      const id = opaqueId(
        'candidate',
        key,
        ...groupRecords.map((record) => record.installationGuid).sort(),
      )
      const metadata = representative.resolution?.record
      const publicCandidate: RecoveryCandidate = {
        id,
        displayName:
          base?.resolution?.record?.displayName ??
          metadata?.displayName ??
          representative.manifest.meta?.appName ??
          'Unknown Epic installation',
        installLocation,
        version:
          base?.manifest.meta?.buildVersion ?? representative.manifest.meta?.buildVersion ?? '',
        recordCount: groupRecords.length,
        kinds: [...new Set(resolved.map((record) => record.resolution!.record!.kind))],
        status,
        recoverable: status === 'resolved' && resolved.length > 0,
        ...(issue ? { issue } : {}),
      }
      this.#candidateGroups.set(id, {
        id,
        installLocation,
        records: resolved,
        public: publicCandidate,
      })
    }
  }

  #createItem(installLocation: string, record: CandidateRecord): Record<string, unknown> {
    const metadata = record.resolution!.record!
    const files = record.manifest.fileList?.fileManifestList ?? []
    const installTags = [...new Set(files.flatMap((file) => file.installTags))]
    const installSize = files.reduce((sum, file) => sum + Math.max(0, file.fileSize), 0)
    const main = metadata.mainGame
    return {
      FormatVersion: 0,
      bIsIncompleteInstall: false,
      LaunchCommand: record.manifest.meta?.launchCommand ?? '',
      LaunchExecutable: record.manifest.meta?.launchExe ?? '',
      ManifestLocation: record.egstorePath,
      CompleteManifestPath: record.manifestPath,
      PendingManifestPath: path.join(
        record.egstorePath,
        'Pending',
        `${record.installationGuid}.manifest`,
      ),
      ManifestHash: record.manifest.header.sha1Hash,
      bIsApplication: true,
      bIsExecutable: metadata.kind === 'base-game',
      bIsManaged: false,
      bNeedsValidation: false,
      bRequiresAuth: metadata.requiresAuth,
      bCanRunOffline: metadata.canRunOffline,
      BaseURLs: [],
      BuildLabel: '',
      AppCategories: metadata.appCategories,
      ChunkDbs: [],
      CompatibleApps: [],
      DisplayName: metadata.displayName,
      InstallationGuid: record.installationGuid,
      InstallLocation: installLocation,
      InstallSessionId: uppercaseGuid(),
      InstallTags: installTags,
      InstallComponents: [],
      HostInstallationGuid: '',
      StagingLocation: path.join(record.egstorePath, 'bps'),
      TechnicalType: metadata.appCategories.join(','),
      InstallSize: installSize,
      ProcessNames: [],
      IgnoredProcessNames: metadata.ignoredProcessNames,
      MandatoryAppFolderName: metadata.mandatoryAppFolderName,
      OwnershipToken: String(metadata.ownershipToken),
      CatalogNamespace: metadata.catalogNamespace,
      CatalogItemId: metadata.catalogItemId,
      AppName: metadata.artifactId,
      AppVersionString: record.manifest.meta?.buildVersion ?? '',
      MainGameCatalogNamespace: main?.catalogNamespace ?? '',
      MainGameCatalogItemId: main?.catalogItemId ?? '',
      MainGameAppName: main?.artifactId ?? '',
      PrereqIds: record.manifest.meta?.prereqIds ?? [],
    }
  }

  async #commitMoveMetadata(game: RegisteredGroup, destination: string): Promise<void> {
    const installed = await readLauncherInstalled(this.#paths.installed)
    for (const entry of installed.InstallationList) {
      if (
        normalizeWindowsPath(stringValue(entry.InstallLocation)) ===
        normalizeWindowsPath(game.installLocation)
      ) {
        entry.InstallLocation = destination
      }
    }
    const targets = game.sources.map((source) => ({
      path: source.itemPath,
      contents: `${JSON.stringify(patchItemLocation(source.value, game.installLocation, destination), null, 2)}\n`,
    }))
    targets.push({
      path: this.#paths.installed,
      contents: `${JSON.stringify(installed, null, 2)}\n`,
    })
    await this.#transactionalWrite(targets)
  }

  async #transactionalWrite(targets: Array<{ path: string; contents: string }>): Promise<void> {
    const targetKeys = targets.map((target) => normalizeWindowsPath(path.resolve(target.path)))
    if (new Set(targetKeys).size !== targets.length) {
      throw new Error('The launcher update contains duplicate records.')
    }
    const backupRoot = path.join(this.#userData, 'launcher-backups')
    const backupDirectory = path.join(
      backupRoot,
      `${new Date().toISOString().replaceAll(':', '-')}-${randomUUID()}`,
    )
    await mkdir(backupDirectory, { recursive: true })
    const backups: Array<{ target: string; backup?: string }> = []
    try {
      for (const [index, target] of targets.entries()) {
        const backup = path.join(backupDirectory, `${index}-${path.basename(target.path)}`)
        try {
          await copyFile(target.path, backup)
          backups.push({ target: target.path, backup })
        } catch (error) {
          if (!isNodeError(error, 'ENOENT')) throw error
          backups.push({ target: target.path })
        }
      }
      for (const target of targets) await atomicWrite(target.path, target.contents)
      for (const target of targets) {
        const actual = jsonObject(await readFile(target.path, 'utf8'))
        const expected = jsonObject(target.contents)
        if (JSON.stringify(actual) !== JSON.stringify(expected)) {
          throw new Error('A launcher record failed verification.')
        }
      }
    } catch (error) {
      for (const backup of backups.reverse()) {
        if (backup.backup) await copyFile(backup.backup, backup.target).catch(() => undefined)
        else await rm(backup.target, { force: true }).catch(() => undefined)
      }
      throw error
    } finally {
      await this.#pruneBackups(backupRoot)
    }
  }

  async #pruneBackups(root: string): Promise<void> {
    const entries = await readdir(root, { withFileTypes: true }).catch(() => [])
    const directories = entries
      .filter((entry) => entry.isDirectory())
      .sort((a, b) => b.name.localeCompare(a.name))
    for (const directory of directories.slice(20)) {
      const target = path.resolve(root, directory.name)
      if (path.dirname(target) === path.resolve(root)) {
        await rm(target, { recursive: true, force: true })
      }
    }
  }

  #emitMove(): void {
    if (this.#moveOperation) this.#snapshot.move = structuredClone(this.#moveOperation.snapshot)
    this.#emit()
  }

  #setScanProgress(progress: NonNullable<LibraryToolsSnapshot['scanProgress']>): void {
    this.#snapshot = { ...this.#snapshot, scanProgress: progress }
    this.#emit()
  }

  #addIssue(issue: string): void {
    if (this.#snapshot.issues.length < 1_000) this.#snapshot.issues.push(issue)
  }

  #emit(): void {
    this.#onChanged?.(this.snapshot)
  }
}
