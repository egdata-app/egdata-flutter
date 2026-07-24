import { createHash, randomUUID } from 'node:crypto'
import { copyFile, mkdir, readdir, stat } from 'node:fs/promises'
import { dirname, join } from 'node:path'
import { pathToFileURL } from 'node:url'

import {
  app,
  BrowserWindow,
  dialog,
  ipcMain,
  powerMonitor,
  safeStorage,
  shell,
  type IpcMainInvokeEvent,
  type WebContents,
} from 'electron'
import type { z } from 'zod'

import {
  AboutInfoSchema,
  AuthStatusSchema,
  CloudQueueSnapshotSchema,
  CloudQueueStartSchema,
  DiagnosticExportRequestSchema,
  GameSelectionSchema,
  LibrarySelectionSchema,
  LibraryDetailsRequestSchema,
  LibraryDetailsSchema,
  LibraryPageSchema,
  LibraryQueryRequestSchema,
  LibraryRefreshResultSchema,
  LibraryStatusSchema,
  LauncherStatusSchema,
  LibraryToolsSnapshotSchema,
  LocalScanRequestSchema,
  LocalUploadRequestSchema,
  MovePreparationSchema,
  OperationIdSchema,
  PublicSettingsSchema,
  QueueSelectionSchema,
  SettingsUpdateSchema,
  UpdateInstallRequestSchema,
  UpdateInstallResultSchema,
  type AuthStatus,
  type CloudQueueItem,
  type CloudQueueSnapshot,
  type LocalScanSnapshot,
  type LocalUploadSnapshot,
  type LibraryRefreshResult,
  type SafeError,
  type UpdateStatus,
} from '../shared/contracts'
import { IPC_CHANNELS } from '../shared/ipc'
import { EpicAuthService, SafeStorageTokenCipher } from './auth'
import { CatalogService } from './catalog'
import { EpicLibraryService, EpicManifestService, createCloudUploadPayload } from './cloud'
import type { EpicLibraryItem, EpicPlatform } from './cloud'
import type { DiagnosticLogger } from './diagnostics'
import type { LaunchAtStartupController } from './launch-at-startup'
import { LibraryService } from './library'
import { LibraryToolsService } from './library-tools'
import { LocalManifestScanner } from './manifests'
import { InMemoryQueue } from './queue'
import type { QueueSnapshot } from './queue'
import { ScheduledUploadService } from './scheduled-uploads'
import type { SettingsStorage } from './storage'
import { ManifestCache, ScheduledUploadStateStorage, TokenStorage } from './storage'
import { uploadManifestWithCache } from './uploads'
import { LocalManifestUploadService } from './uploads'
import { UpdateService } from './updates'

const WEBSITE_URL = 'https://egdata.app'
const PRIVACY_URL = 'https://egdata.app/privacy'
const LICENSES_URL = 'https://github.com/egdata-app/egdata-flutter/blob/main/LICENSE'

type Schema<T> = z.ZodType<T>

export interface RegisterIpcOptions {
  getWindow: () => BrowserWindow | null
  settings: SettingsStorage
  logger: DiagnosticLogger
  launchAtStartup: LaunchAtStartupController
  userData: string
  isDevelopment: boolean
}

export async function registerIpcHandlers(options: RegisterIpcOptions): Promise<() => void> {
  const services = new DesktopIpcServices(options)
  await services.initialize()
  return services.register()
}

class DesktopIpcServices {
  readonly #getWindow: () => BrowserWindow | null
  readonly #settings: SettingsStorage
  readonly #logger: DiagnosticLogger
  readonly #launchAtStartup: LaunchAtStartupController
  readonly #userData: string
  readonly #isDevelopment: boolean
  readonly #platform: EpicPlatform
  readonly #scanner: LocalManifestScanner
  readonly #catalog: CatalogService
  readonly #manifestCache: ManifestCache
  readonly #localUploader: LocalManifestUploadService
  readonly #auth: EpicAuthService
  readonly #library: EpicLibraryService
  readonly #gameLibrary: LibraryService
  readonly #libraryTools: LibraryToolsService
  readonly #cloudManifests: EpicManifestService
  readonly #queue: InMemoryQueue<EpicLibraryItem>
  #scheduledUploads: ScheduledUploadService | null = null
  #scheduledUploadSource: 'local' | 'cloud' | null = null
  #cloudRefreshActive = false
  #localSessionId: string | null = null
  #localSnapshot: LocalScanSnapshot = emptyLocalSnapshot()
  #selectedDirectory: string | null = null
  #localUpload: LocalUploadSnapshot | null = null
  #localUploadController: AbortController | null = null
  #updateStatus: UpdateStatus
  #updates: UpdateService | null = null
  #automaticUpdateCheckTimer: ReturnType<typeof setTimeout> | null = null
  #updateInstallBarrier = false
  #cloudRefreshController: AbortController | null = null
  #disposeQueue: (() => void) | null = null
  #cloudPersistenceWarningLogged = false
  #libraryToolsCatalogScanAt: string | null = null
  readonly #persistedCloudItems = new Map<string, string>()
  #suppressLibraryEvents = false
  readonly #powerResumeListener = () => void this.#scheduledUploads?.refresh()

  constructor(options: RegisterIpcOptions) {
    this.#getWindow = options.getWindow
    this.#settings = options.settings
    this.#logger = options.logger
    this.#launchAtStartup = options.launchAtStartup
    this.#userData = options.userData
    this.#isDevelopment = options.isDevelopment
    const nodePlatform = process.platform === 'darwin' ? 'darwin' : 'win32'
    this.#platform = nodePlatform === 'darwin' ? 'Mac' : 'Windows'
    this.#scanner = new LocalManifestScanner({
      platform: nodePlatform,
      allowCustomDirectory: true,
    })
    this.#catalog = new CatalogService({
      filePath: join(options.userData, 'catalog.v2.sqlite'),
      baseUrl: process.env.EGDATA_API_BASE_URL?.trim() || 'https://api.egdata.app',
      onUpdated: () => this.#onCatalogUpdated(),
    })
    this.#gameLibrary = new LibraryService({
      resolveMetadata: (input) => this.#catalog.getLibraryMetadata(input),
      getTaxonomy: () => this.#catalog.getTaxonomy(),
    })
    this.#manifestCache = new ManifestCache(join(options.userData, 'manifest-cache.v1.sqlite'))
    this.#localUploader = new LocalManifestUploadService(
      this.#scanner,
      {
        platform: nodePlatform,
      },
      this.#manifestCache,
    )
    const tokenStorage = new TokenStorage(join(options.userData, 'epic-session.v1'))
    this.#auth = new EpicAuthService({
      persistence: tokenStorage,
      cipher: new SafeStorageTokenCipher(safeStorage),
    })
    this.#library = new EpicLibraryService({ auth: this.#auth, platform: this.#platform })
    this.#libraryTools = new LibraryToolsService({
      platform: process.platform,
      userData: options.userData,
      resolveLauncherRecords: (candidates) => {
        const resolve = () =>
          candidates.map((candidate) => {
            const record = this.#catalog.resolveLauncherCandidate({
              buildAppName: candidate.buildAppName,
              platform: candidate.platform,
              ...(candidate.catalogHint ? { catalogHint: candidate.catalogHint } : {}),
            })
            return record
              ? { requestId: candidate.requestId, status: 'resolved' as const, record }
              : { requestId: candidate.requestId, status: 'not-found' as const }
          })
        return Promise.resolve(resolve())
      },
      onChanged: (snapshot) => {
        this.#send(IPC_CHANNELS.libraryTools.event, { snapshot })
        if (
          snapshot.state === 'idle' &&
          snapshot.scannedAt &&
          snapshot.scannedAt !== this.#libraryToolsCatalogScanAt &&
          snapshot.issues.length === 0
        ) {
          this.#libraryToolsCatalogScanAt = snapshot.scannedAt
          this.#reconcileLibraryToolsCatalog()
        }
        if (snapshot.state === 'idle') void this.#scheduledUploads?.refresh()
      },
    })
    this.#cloudManifests = new EpicManifestService({ auth: this.#auth, platform: this.#platform })
    this.#queue = new InMemoryQueue<EpicLibraryItem>({
      concurrency: 5,
      process: async (item, context) => {
        const startedAt = Date.now()
        let uploadContext: Record<string, unknown> | undefined
        await this.#logger.info('cloud', 'Cloud manifest sync started', {
          attempt: context.attempt,
        })
        try {
          const manifest = await this.#cloudManifests.getManifest(item, { signal: context.signal })
          if (!manifest) {
            await this.#logger.warn('cloud', 'No cloud manifest is available', {
              attempt: context.attempt,
              elapsedMs: Date.now() - startedAt,
            })
            return { state: 'skipped', message: 'No cloud manifest is available.' }
          }
          await this.#logger.debug('cloud', 'Cloud manifest downloaded', {
            attempt: context.attempt,
            manifestBytes: manifest.bytes.byteLength,
            elapsedMs: Date.now() - startedAt,
          })
          const accountId = this.#auth.getState().accountId
          if (accountId && manifest.buildVersion && this.#manifestCache.isReady) {
            try {
              this.#manifestCache.updateCloudBuildVersion(
                accountId,
                this.#platform,
                context.id,
                manifest.buildVersion,
              )
            } catch (error) {
              void this.#logger.warn('storage', 'Cloud build version could not be persisted', {
                error,
              })
            }
          }
          const uploadItem = {
            ...item,
            buildVersion: manifest.buildVersion ?? item.buildVersion,
          }
          const payload = createCloudUploadPayload(uploadItem, manifest.bytes, this.#platform)
          const result = await uploadManifestWithCache(
            {
              itemId: context.id,
              rawItemText: payload.itemJson,
              manifestBytes: payload.manifest,
              manifestFileName: payload.manifestFilename,
              installationGuid: item.assetId,
            },
            {
              platform: this.#platform === 'Mac' ? 'darwin' : 'win32',
              signal: context.signal,
            },
            this.#manifestCache,
          )
          uploadContext = {
            attempt: context.attempt,
            manifestBytes: payload.manifest.byteLength,
            elapsedMs: Date.now() - startedAt,
            ...(result.contentHash ? { contentHash: result.contentHash } : {}),
            ...(result.manifestHash ? { serverManifestHash: result.manifestHash } : {}),
            ...(result.statusCode ? { statusCode: result.statusCode } : {}),
            ...(result.errorCode ? { errorCode: result.errorCode } : {}),
          }
          if (result.state === 'uploaded') {
            await this.#logger.info('uploads', 'Cloud manifest uploaded', uploadContext)
            return { state: 'uploaded', message: result.message }
          }
          if (result.state === 'already-uploaded') {
            await this.#logger.info('uploads', 'Cloud manifest already confirmed', uploadContext)
            return { state: 'alreadyUploaded', message: result.message }
          }
          if (result.state === 'cancelled') {
            throw new Error('SYNC_CANCELLED')
          }
          throw new Error(result.errorCode ?? result.message)
        } catch (error) {
          if (context.signal.aborted) {
            await this.#logger.info('cloud', 'Cloud manifest sync cancelled', {
              attempt: context.attempt,
              elapsedMs: Date.now() - startedAt,
              ...(uploadContext ?? {}),
            })
          } else {
            await this.#logger.error('cloud', 'Cloud manifest sync failed', {
              attempt: context.attempt,
              elapsedMs: Date.now() - startedAt,
              ...(uploadContext ?? {}),
              error,
            })
          }
          throw error
        }
      },
    })
    const scheduledUploadState = new ScheduledUploadStateStorage(
      join(options.userData, 'scheduled-uploads.v1.json'),
    )
    this.#scheduledUploads = new ScheduledUploadService({
      stateStorage: scheduledUploadState,
      getSettings: () => this.#settings.getPreferences(),
      canRun: (source) => this.#canRunScheduledUpload(source),
      run: (source, signal) => this.#runScheduledUpload(source, signal),
      onError: (message, error) => this.#logger.warn('uploads', message, { error }),
    })
    this.#updateStatus = {
      state: 'idle',
      currentVersion: app.getVersion(),
      channel: 'stable',
      delivery: process.windowsStore
        ? 'store'
        : process.platform === 'win32' && app.isPackaged
          ? 'managed'
          : 'manual',
    }
  }

  async initialize(): Promise<void> {
    try {
      await this.#catalog.initialize()
    } catch (error) {
      await this.#logger.warn('catalog', 'Local catalog could not be initialized', { error })
    }
    try {
      await this.#manifestCache.initialize()
    } catch (error) {
      await this.#logger.warn('storage', 'Manifest cache could not be initialized', { error })
    }
    await this.#auth.initialize()
    await this.#restoreCloudLibrary()
    this.#updateGameLibrarySources()
    const settings = await this.#settings.getPreferences()
    this.#updates = new UpdateService({
      currentVersion: app.getVersion(),
      channel: settings.updateChannel,
      platform: process.platform,
      windowsStore: Boolean(process.windowsStore),
      isPackaged: app.isPackaged,
      userData: this.#userData,
      logger: this.#logger,
      onStatus: (status) => {
        this.#updateStatus = status
        this.#send(IPC_CHANNELS.updates.statusEvent, status)
      },
      openPath: (filePath) => shell.openPath(filePath),
      quit: () => app.quit(),
      manifestWorkIsBusy: () => this.#manifestWorkIsBusy(),
      cancelManifestWork: () => this.#cancelManifestWorkForUpdate(),
      setInstallBarrier: (active) => {
        this.#updateInstallBarrier = active
        if (!active) void this.#scheduledUploads?.refresh()
      },
    })
    this.#updateStatus = this.#updates.status
    await this.#libraryTools.initialize(settings.automaticallyScanWindowsDrives)
    if (this.#libraryTools.catalogInterestsReady) this.#reconcileLibraryToolsCatalog()
    this.#disposeQueue = this.#queue.subscribe((snapshot) => {
      this.#persistCloudQueue(snapshot)
      this.#send(IPC_CHANNELS.cloud.event, {
        type: 'snapshot',
        snapshot: this.#mapQueueSnapshot(snapshot),
      })
      if (snapshot.state === 'completed' || snapshot.state === 'cancelled') {
        void this.#scheduledUploads?.refresh()
      }
    })
    this.#catalog.start()
    void this.#scanLocal('default').catch((error: unknown) => {
      void this.#logger.warn('catalog', 'Initial Epic manifest discovery could not be completed', {
        error,
      })
    })
    powerMonitor.on('resume', this.#powerResumeListener)
    await this.#scheduledUploads?.start()
    if (app.isPackaged && settings.automaticallyCheckForUpdates) {
      this.#automaticUpdateCheckTimer = setTimeout(() => {
        this.#automaticUpdateCheckTimer = null
        void this.#updates?.check()
      }, 5_000)
    }
  }

  register(): () => void {
    const channels: string[] = []
    const handle = <I, O>(
      channel: string,
      handler: (input: I, event: IpcMainInvokeEvent) => O | Promise<O>,
      input?: Schema<I>,
      output?: Schema<O>,
    ) => {
      channels.push(channel)
      ipcMain.handle(channel, async (event, raw: unknown) => {
        this.#assertTrustedSender(event)
        try {
          const value = input ? input.parse(raw) : (undefined as I)
          const result = await handler(value, event)
          return output ? output.parse(result) : result
        } catch (error) {
          await this.#logger.warn('ipc', 'IPC request failed', {
            channel,
            error,
          })
          const message = channel.startsWith('library-tools:')
            ? libraryToolsPublicErrorMessage(error)
            : channel.startsWith('catalog:')
              ? catalogPublicErrorMessage(error)
              : publicErrorMessage(error)
          throw new Error(message, { cause: error })
        }
      })
    }

    handle(IPC_CHANNELS.local.selectDirectory, () => this.#selectDirectory())
    handle(
      IPC_CHANNELS.local.scan,
      (request) => {
        this.#assertNoScheduledUpload()
        return this.#scanLocal(request.source)
      },
      LocalScanRequestSchema,
    )
    handle(IPC_CHANNELS.local.getScanSnapshot, () => this.#localSnapshot)
    handle(
      IPC_CHANNELS.local.upload,
      (request) => {
        this.#assertNoScheduledUpload()
        return this.#uploadLocal(request.manifestIds)
      },
      LocalUploadRequestSchema,
    )
    handle(
      IPC_CHANNELS.local.cancelUpload,
      ({ operationId }) => this.#cancelLocalUpload(operationId),
      OperationIdSchema,
    )

    handle(
      IPC_CHANNELS.libraryTools.getSnapshot,
      () => this.#libraryTools.snapshot,
      undefined,
      LibraryToolsSnapshotSchema,
    )
    handle(
      IPC_CHANNELS.libraryTools.getLauncherStatus,
      async () => ({ running: await this.#libraryTools.isLauncherOpen() }),
      undefined,
      LauncherStatusSchema,
    )
    handle(
      IPC_CHANNELS.libraryTools.tryCloseLauncher,
      async () => ({ running: !(await this.#libraryTools.tryCloseLauncher()) }),
      undefined,
      LauncherStatusSchema,
    )
    handle(
      IPC_CHANNELS.libraryTools.scan,
      () => {
        this.#assertNoScheduledUpload()
        return this.#libraryTools.scan()
      },
      undefined,
      LibraryToolsSnapshotSchema,
    )
    handle(
      IPC_CHANNELS.libraryTools.cancelScan,
      () => this.#libraryTools.cancelScan(),
      undefined,
      LibraryToolsSnapshotSchema,
    )
    handle(
      IPC_CHANNELS.libraryTools.recover,
      ({ candidateIds }) => {
        this.#assertNoScheduledUpload()
        return this.#libraryTools.recover(candidateIds)
      },
      LibrarySelectionSchema,
      LibraryToolsSnapshotSchema,
    )
    handle(
      IPC_CHANNELS.libraryTools.prepareMove,
      ({ gameId }) => this.#prepareLibraryMove(gameId),
      GameSelectionSchema,
      MovePreparationSchema,
    )
    handle(
      IPC_CHANNELS.libraryTools.startMove,
      ({ operationId }) => {
        this.#assertNoScheduledUpload()
        return this.#libraryTools.startMove(operationId)
      },
      OperationIdSchema,
      LibraryToolsSnapshotSchema,
    )
    handle(
      IPC_CHANNELS.libraryTools.cancelMove,
      ({ operationId }) => this.#libraryTools.cancelMove(operationId),
      OperationIdSchema,
      LibraryToolsSnapshotSchema,
    )

    handle(IPC_CHANNELS.auth.getStatus, () => this.#authStatus(), undefined, AuthStatusSchema)
    handle(IPC_CHANNELS.auth.login, () => this.#login(), undefined, AuthStatusSchema)
    handle(IPC_CHANNELS.auth.logout, () => this.#logout(), undefined, AuthStatusSchema)

    handle(
      IPC_CHANNELS.cloud.getSnapshot,
      () => this.#getCloudSnapshot(),
      undefined,
      CloudQueueSnapshotSchema,
    )
    handle(
      IPC_CHANNELS.cloud.refresh,
      () => {
        this.#assertNoScheduledUpload()
        return this.#refreshCloudLibrary()
      },
      undefined,
      CloudQueueSnapshotSchema,
    )
    handle(
      IPC_CHANNELS.cloud.start,
      (request) => {
        this.#assertNoScheduledUpload()
        return this.#startCloudQueue(request.itemIds)
      },
      CloudQueueStartSchema,
      CloudQueueSnapshotSchema,
    )
    handle(IPC_CHANNELS.cloud.pause, () => this.#mapQueueSnapshot(this.#queue.pause()))
    handle(IPC_CHANNELS.cloud.resume, () => this.#resumeCloudQueue())
    handle(IPC_CHANNELS.cloud.cancel, () => this.#cancelCloudQueue())
    handle(
      IPC_CHANNELS.cloud.retry,
      (request) => this.#retryCloudQueue(request.itemIds),
      QueueSelectionSchema,
    )
    handle(
      IPC_CHANNELS.cloud.remove,
      (request) => this.#mapQueueSnapshot(this.#queue.remove(new Set(request.itemIds))),
      QueueSelectionSchema,
    )
    handle(IPC_CHANNELS.cloud.clearCompleted, () =>
      this.#mapQueueSnapshot(this.#queue.clearCompleted()),
    )

    handle(
      IPC_CHANNELS.library.getStatus,
      () => this.#gameLibrary.getStatus(),
      undefined,
      LibraryStatusSchema,
    )
    handle(
      IPC_CHANNELS.library.query,
      (request) => this.#gameLibrary.query(request),
      LibraryQueryRequestSchema,
      LibraryPageSchema,
    )
    handle(
      IPC_CHANNELS.library.getDetails,
      ({ id }) => {
        const details = this.#gameLibrary.getDetails(id)
        if (!details) throw new Error('This Library entry is no longer available.')
        return details
      },
      LibraryDetailsRequestSchema,
      LibraryDetailsSchema,
    )
    handle(
      IPC_CHANNELS.library.refresh,
      () => {
        this.#assertNoScheduledUpload()
        return this.#refreshGameLibrary()
      },
      undefined,
      LibraryRefreshResultSchema,
    )

    handle(IPC_CHANNELS.settings.get, () => this.#getPublicSettings())
    handle(
      IPC_CHANNELS.settings.update,
      async (update) => {
        const previousSettings = await this.#settings.getPreferences()
        if (update.launchAtStartup !== undefined) {
          this.#launchAtStartup.setEnabled(update.launchAtStartup)
        }
        const settings = await this.#settings.updatePreferences(update)
        if (settings.automaticallyScanWindowsDrives) this.#libraryTools.startScheduler()
        else this.#libraryTools.stopScheduler()
        if (!settings.automaticUploadsEnabled || !settings.contributionConsent) {
          this.#scheduledUploads?.cancelActive()
        }
        void this.#scheduledUploads?.refresh()
        const publicSettings = this.#mapPublicSettings(settings)
        this.#send(IPC_CHANNELS.settings.changedEvent, publicSettings)
        if (settings.updateChannel !== previousSettings.updateChannel) {
          void this.#updates?.setChannel(settings.updateChannel).then(() => this.#updates?.check())
        }
        return publicSettings
      },
      SettingsUpdateSchema,
    )

    handle(IPC_CHANNELS.diagnostics.getSnapshot, () => this.#diagnosticsSnapshot())
    handle(
      IPC_CHANNELS.diagnostics.export,
      (request) => this.#exportDiagnostics(request.includePaths),
      DiagnosticExportRequestSchema,
    )
    handle(IPC_CHANNELS.diagnostics.revealLogs, () => this.#revealLogs())

    handle(IPC_CHANNELS.updates.getStatus, () => this.#updates?.status ?? this.#updateStatus)
    handle(IPC_CHANNELS.updates.check, () => this.#requireUpdates().check())
    handle(IPC_CHANNELS.updates.download, () => this.#requireUpdates().download())
    handle(
      IPC_CHANNELS.updates.install,
      (request) => this.#requireUpdates().install(request.cancelActiveWork),
      UpdateInstallRequestSchema,
      UpdateInstallResultSchema,
    )
    handle(IPC_CHANNELS.about.getInfo, () =>
      AboutInfoSchema.parse({
        productName: 'egdata.app',
        version: app.getVersion(),
        platform: this.#platform === 'Mac' ? 'macos' : 'windows',
        architecture: process.arch,
        electronVersion: process.versions.electron,
        licensesUrl: LICENSES_URL,
        privacyUrl: PRIVACY_URL,
        websiteUrl: WEBSITE_URL,
      }),
    )

    return () => {
      if (this.#automaticUpdateCheckTimer) clearTimeout(this.#automaticUpdateCheckTimer)
      this.#automaticUpdateCheckTimer = null
      this.#updates?.dispose()
      this.#updates = null
      powerMonitor.removeListener('resume', this.#powerResumeListener)
      this.#scheduledUploads?.dispose()
      this.#scheduledUploads = null
      this.#catalog.stop()
      this.#catalog.close()
      this.#disposeQueue?.()
      this.#disposeQueue = null
      this.#manifestCache.close()
      this.#libraryTools.dispose()
      for (const channel of channels) ipcMain.removeHandler(channel)
    }
  }

  async #prepareLibraryMove(gameId: string) {
    this.#assertNoScheduledUpload()
    const result = await dialog.showOpenDialog(this.#requireWindow(), {
      title: 'Choose destination parent folder',
      properties: ['openDirectory', 'createDirectory'],
    })
    const destinationParent = result.filePaths[0]
    if (result.canceled || !destinationParent) return { cancelled: true }
    const move = await this.#libraryTools.prepareMove(gameId, destinationParent)
    return { cancelled: false, move }
  }

  async #selectDirectory(): Promise<{ cancelled: boolean; displayPath?: string }> {
    const result = await dialog.showOpenDialog(this.#requireWindow(), {
      title: 'Choose Epic manifest directory',
      properties: ['openDirectory'],
    })
    const selected = result.filePaths[0]
    if (result.canceled || !selected) return { cancelled: true }
    this.#selectedDirectory = selected
    return { cancelled: false, displayPath: selected }
  }

  async #scanLocal(
    source: 'default' | 'selected',
    waitForCatalog = false,
  ): Promise<LocalScanSnapshot> {
    this.#localSnapshot = { state: 'scanning', manifests: [], issues: [] }
    this.#send(IPC_CHANNELS.local.scanEvent, { type: 'started' })
    if (source === 'selected' && !this.#selectedDirectory) {
      throw new Error('Choose a manifest directory before scanning it.')
    }
    const startedAt = Date.now()
    await this.#logger.info('local', 'Local manifest scan started', { source })
    const result = await this.#scanner.scan(
      source === 'selected'
        ? { source, manifestDirectory: this.#selectedDirectory ?? undefined }
        : { source },
    )
    this.#localSessionId = result.sessionId
    const groupIds = new Map<string, string>()
    for (const group of result.groups) {
      for (const id of group.sourceItemIds) groupIds.set(id, group.groupId)
    }
    const scannedAt = new Date().toISOString()
    this.#localSnapshot = {
      state: result.directoryAvailable ? 'complete' : 'failed',
      scannedAt,
      manifests: result.items.map((item) => ({
        id: item.itemId,
        appName: item.appName,
        displayName: this.#resolveCatalogDisplayName(
          {
            namespace: item.catalogNamespace,
            catalogItemId: item.catalogItemId,
            artifactId: item.appName,
            appName: item.appName,
            platform: this.#platform,
          },
          item.displayName,
        ),
        catalogItemId: item.catalogItemId,
        namespace: item.catalogNamespace,
        sourceFilename: item.sourceName,
        platform: this.#platform === 'Mac' ? 'macos' : 'windows',
        kind: item.isAddon ? 'addon' : 'base-game',
        binaryManifestAvailable: item.uploadable,
        groupId: groupIds.get(item.itemId) ?? item.itemId,
      })),
      issues: result.errors.map((issue, index) => ({
        id: issue.itemId ?? `discovery-${index + 1}`,
        sourceFilename: issue.sourceName ?? 'Epic manifest directory',
        error: {
          code: issue.code,
          message: issue.message,
          retryable: true,
        },
      })),
      ...(!result.directoryAvailable
        ? {
            error: {
              code: 'LOCAL_MANIFEST_DIRECTORY_MISSING' as const,
              message: 'The Epic manifest directory could not be read.',
              retryable: true,
            },
          }
        : {}),
    }
    const scanContext = {
      source,
      manifests: result.items.length,
      issues: result.errors.length,
      elapsedMs: Date.now() - startedAt,
      ...(result.errors.length
        ? { issueCodes: [...new Set(result.errors.map((issue) => issue.code))] }
        : {}),
    }
    if (result.directoryAvailable && result.errors.length === 0) {
      await this.#logger.info('local', 'Local manifest scan completed', scanContext)
    } else {
      await this.#logger.warn('local', 'Local manifest scan completed with issues', scanContext)
    }
    this.#send(IPC_CHANNELS.local.scanEvent, {
      type: 'finished',
      snapshot: this.#localSnapshot,
    })
    if (result.directoryAvailable && result.errors.length === 0) {
      const reconciliation = this.#catalog.reconcileNames(
        source === 'default' ? 'local:default' : 'local:selected',
        source === 'default' ? 'local-default' : 'local-selected',
        result.items.map((item) => ({
          namespace: item.catalogNamespace,
          catalogItemId: item.catalogItemId,
          artifactId: item.appName,
          appName: item.appName,
          platform: this.#platform,
        })),
      )
      const reportFailure = (error: unknown) =>
        this.#logger.warn('catalog', 'Local catalog interests could not be reconciled', { error })
      if (waitForCatalog) await reconciliation.catch(reportFailure)
      else void reconciliation.catch(reportFailure)
    }
    this.#updateGameLibrarySources()
    this.#emitLibraryChanged()
    void this.#scheduledUploads?.refresh()
    return this.#localSnapshot
  }

  async #uploadLocal(
    manifestIds: string[],
    options: { concurrency?: number; signal?: AbortSignal } = {},
  ): Promise<LocalUploadSnapshot> {
    const preferences = await this.#settings.getPreferences()
    if (!preferences.contributionConsent) throw new Error('Contribution consent is required.')
    if (!this.#localSessionId) throw new Error('Scan local manifests before uploading.')
    if (this.#localUpload?.state === 'running')
      throw new Error('A local upload is already running.')
    const knownIds = new Set(this.#scanner.getSessionItemIds(this.#localSessionId))
    if (manifestIds.some((id) => !knownIds.has(id))) throw new Error('Unknown local manifest.')

    const operationId = randomUUID()
    const controller = new AbortController()
    const abortFromParent = () => controller.abort()
    if (options.signal?.aborted) controller.abort()
    else options.signal?.addEventListener('abort', abortFromParent, { once: true })
    this.#localUploadController = controller
    const items: LocalUploadSnapshot['items'] = manifestIds.map((manifestId) => ({
      manifestId,
      state: 'pending',
    }))
    this.#localUpload = {
      operationId,
      state: 'running',
      completed: 0,
      total: items.length,
      items,
    }
    this.#send(IPC_CHANNELS.local.uploadEvent, this.#localUpload)
    const startedAt = Date.now()
    await this.#logger.info('uploads', 'Local manifest upload started', { total: items.length })
    let cursor = 0
    const worker = async () => {
      while (!controller.signal.aborted) {
        const index = cursor++
        const item = items[index]
        if (!item) return
        item.state = 'uploading'
        this.#send(IPC_CHANNELS.local.uploadEvent, this.#localUpload)
        const itemStartedAt = Date.now()
        const result = await this.#localUploader.uploadOne(
          this.#localSessionId!,
          item.manifestId,
          controller.signal,
        )
        item.state = result.state
        if (result.errorCode) {
          item.error = uploadSafeError(result.errorCode, result.message)
        }
        const uploadContext = {
          elapsedMs: Date.now() - itemStartedAt,
          ...(result.contentHash ? { contentHash: result.contentHash } : {}),
          ...(result.manifestHash ? { serverManifestHash: result.manifestHash } : {}),
          ...(result.statusCode ? { statusCode: result.statusCode } : {}),
          ...(result.errorCode ? { errorCode: result.errorCode } : {}),
        }
        if (result.state === 'uploaded') {
          await this.#logger.info('uploads', 'Local manifest uploaded', uploadContext)
        } else if (result.state === 'already-uploaded') {
          await this.#logger.info('uploads', 'Local manifest already confirmed', uploadContext)
        } else if (result.state === 'cancelled') {
          await this.#logger.info('uploads', 'Local manifest upload cancelled', uploadContext)
        } else {
          await this.#logger.warn('uploads', 'Local manifest upload failed', uploadContext)
        }
        this.#localUpload!.completed += 1
        this.#send(IPC_CHANNELS.local.uploadEvent, this.#localUpload)
      }
    }
    const concurrency = Math.max(1, Math.min(options.concurrency ?? 5, items.length))
    await Promise.all(Array.from({ length: concurrency }, worker))
    if (controller.signal.aborted) {
      for (const item of items) {
        if (item.state === 'pending' || item.state === 'uploading') item.state = 'cancelled'
      }
      this.#localUpload.state = 'cancelled'
      this.#localUpload.completed = items.length
    } else {
      this.#localUpload.state = 'complete'
    }
    this.#localUploadController = null
    options.signal?.removeEventListener('abort', abortFromParent)
    const completionContext = {
      total: items.length,
      uploaded: items.filter((item) => item.state === 'uploaded').length,
      alreadyUploaded: items.filter((item) => item.state === 'already-uploaded').length,
      failed: items.filter((item) => item.state === 'failed').length,
      cancelled: items.filter((item) => item.state === 'cancelled').length,
      elapsedMs: Date.now() - startedAt,
    }
    if (completionContext.failed > 0) {
      await this.#logger.warn(
        'uploads',
        'Local manifest upload completed with failures',
        completionContext,
      )
    } else {
      await this.#logger.info('uploads', 'Local manifest upload completed', completionContext)
    }
    this.#send(IPC_CHANNELS.local.uploadEvent, this.#localUpload)
    void this.#scheduledUploads?.refresh()
    return this.#localUpload
  }

  #cancelLocalUpload(operationId: string): { ok: true } {
    if (this.#localUpload?.operationId === operationId) this.#localUploadController?.abort()
    return { ok: true }
  }

  #authStatus(state?: AuthStatus['state']): AuthStatus {
    const auth = this.#auth.getState()
    const expired = auth.expiresAt !== null && Date.parse(auth.expiresAt) <= Date.now()
    return {
      state: state ?? (auth.authenticated ? (expired ? 'expired' : 'signed-in') : 'signed-out'),
      ...(auth.accountId ? { accountId: auth.accountId } : {}),
      ...(auth.expiresAt ? { expiresAt: auth.expiresAt } : {}),
    }
  }

  async #login(): Promise<AuthStatus> {
    this.#send(IPC_CHANNELS.auth.statusEvent, this.#authStatus('signing-in'))
    await this.#auth.login()
    const status = this.#authStatus()
    this.#send(IPC_CHANNELS.auth.statusEvent, status)
    if (!(await this.#restoreCloudLibrary())) await this.#refreshCloudLibrary()
    this.#updateGameLibrarySources()
    this.#emitLibraryChanged()
    void this.#scheduledUploads?.refresh()
    return status
  }

  async #logout(): Promise<AuthStatus> {
    this.#scheduledUploads?.cancelActive('cloud')
    await this.#queue.cancel()
    this.#queue.replace([])
    const accountId = this.#auth.getState().accountId
    if (accountId) this.#catalog.removeScope(this.#cloudCatalogScope(accountId))
    await this.#auth.logout()
    this.#updateGameLibrarySources()
    this.#emitLibraryChanged()
    const status = this.#authStatus()
    this.#send(IPC_CHANNELS.auth.statusEvent, status)
    void this.#scheduledUploads?.refresh()
    return status
  }

  async #getCloudSnapshot(): Promise<CloudQueueSnapshot> {
    if (this.#updateInstallBarrier) return this.#mapQueueSnapshot(this.#queue.snapshot)
    if (this.#auth.getState().authenticated && this.#queue.snapshot.items.length === 0) {
      if (!(await this.#restoreCloudLibrary())) return this.#refreshCloudLibrary()
    }
    return this.#mapQueueSnapshot(this.#queue.snapshot)
  }

  async #refreshCloudLibrary(): Promise<CloudQueueSnapshot> {
    if (this.#cloudRefreshActive) throw new Error('A cloud library refresh is already running.')
    this.#cloudRefreshActive = true
    const controller = new AbortController()
    this.#cloudRefreshController = controller
    try {
      return await this.#performCloudLibraryRefresh(controller.signal)
    } finally {
      if (this.#cloudRefreshController === controller) this.#cloudRefreshController = null
      this.#cloudRefreshActive = false
      void this.#scheduledUploads?.refresh()
    }
  }

  async #performCloudLibraryRefresh(signal?: AbortSignal): Promise<CloudQueueSnapshot> {
    if (!this.#auth.getState().authenticated) throw new Error('Connect Epic Games first.')
    if (['running', 'pausing', 'paused'].includes(this.#queue.snapshot.state)) {
      throw new Error('Finish or cancel the current queue before refreshing the library.')
    }
    const startedAt = Date.now()
    await this.#logger.info('cloud', 'Epic library refresh started')
    let library: EpicLibraryItem[]
    try {
      library = await this.#library.getLibrary(signal ? { signal } : {})
    } catch (error) {
      await this.#logger.error('cloud', 'Epic library refresh failed', {
        elapsedMs: Date.now() - startedAt,
        error,
      })
      throw error
    }
    const accountId = this.#auth.getState().accountId
    if (!accountId) throw new Error('Connect Epic Games first.')
    if (signal?.aborted) throw new Error('SYNC_CANCELLED')
    const inputs = library.map((item) => ({
      id: cloudItemId(item),
      value: item,
      title: item.title || item.appName,
    }))
    if (!this.#manifestCache.isReady) {
      this.#queue.replace(inputs)
    } else {
      try {
        this.#queue.restore(
          this.#manifestCache.reconcileCloudLibrary(accountId, this.#platform, inputs),
        )
      } catch (error) {
        await this.#logger.warn('storage', 'Cloud library could not be reconciled', { error })
        this.#queue.replace(inputs)
      }
    }
    await this.#logger.info('cloud', 'Epic library loaded', {
      items: library.length,
      elapsedMs: Date.now() - startedAt,
    })
    try {
      await this.#catalog.reconcileNames(
        this.#cloudCatalogScope(accountId),
        'cloud-account',
        library.map((item) => ({
          namespace: item.namespace,
          catalogItemId: item.catalogItemId,
          artifactId: item.assetId || item.appName,
          appName: item.appName,
          platform: this.#platform,
        })),
      )
    } catch (error) {
      await this.#logger.warn('catalog', 'Cloud catalog interests could not be reconciled', {
        error,
      })
    }
    this.#updateGameLibrarySources()
    this.#emitLibraryChanged()
    return this.#mapQueueSnapshot(this.#queue.snapshot)
  }

  async #restoreCloudLibrary(): Promise<boolean> {
    const accountId = this.#auth.getState().accountId
    if (!accountId || !this.#manifestCache.isReady) return false
    try {
      if (!this.#manifestCache.hasCloudLibrarySnapshot(accountId, this.#platform)) return false
      const cached = this.#manifestCache.loadCloudQueue(accountId, this.#platform)
      this.#queue.restore(cached)
      void this.#catalog
        .reconcileNames(
          this.#cloudCatalogScope(accountId),
          'cloud-account',
          cached.map((entry) => ({
            namespace: entry.value.namespace,
            catalogItemId: entry.value.catalogItemId,
            artifactId: entry.value.assetId || entry.value.appName,
            appName: entry.value.appName,
            platform: this.#platform,
          })),
        )
        .catch((error: unknown) => {
          void this.#logger.warn('catalog', 'Cached catalog interests could not be reconciled', {
            error,
          })
        })
      await this.#logger.info('cloud', 'Cached Epic library loaded', { items: cached.length })
      this.#updateGameLibrarySources()
      return true
    } catch (error) {
      await this.#logger.warn('storage', 'Cached Epic library could not be loaded', { error })
      return false
    }
  }

  #persistCloudQueue(snapshot: QueueSnapshot<EpicLibraryItem>): void {
    const accountId = this.#auth.getState().accountId
    if (!accountId || !this.#manifestCache.isReady) return
    const changed = snapshot.items.flatMap((item) => {
      const key = `${accountId}\u0000${this.#platform}\u0000${item.id}`
      const fingerprint = JSON.stringify([
        item.state,
        item.attempts,
        item.startedAt,
        item.finishedAt,
        item.error,
        item.message,
      ])
      return this.#persistedCloudItems.get(key) === fingerprint ? [] : [{ item, key, fingerprint }]
    })
    if (changed.length === 0) return
    try {
      this.#manifestCache.saveCloudQueueItems(
        accountId,
        this.#platform,
        changed.map((entry) => entry.item),
      )
      for (const entry of changed) this.#persistedCloudItems.set(entry.key, entry.fingerprint)
    } catch (error) {
      if (this.#cloudPersistenceWarningLogged) return
      this.#cloudPersistenceWarningLogged = true
      void this.#logger.warn('storage', 'Cloud sync status could not be persisted', { error })
    }
  }

  async #startCloudQueue(itemIds?: string[]): Promise<CloudQueueSnapshot> {
    const preferences = await this.#settings.getPreferences()
    if (!preferences.contributionConsent) throw new Error('Contribution consent is required.')
    if (!this.#auth.getState().authenticated) throw new Error('Connect Epic Games first.')
    if (this.#queue.snapshot.items.length === 0 && !(await this.#restoreCloudLibrary())) {
      await this.#refreshCloudLibrary()
    }
    if (itemIds?.length) {
      const selected = new Set(itemIds)
      const inputs = this.#queue.snapshot.items
        .filter((item) => selected.has(item.id))
        .map((item) => ({ id: item.id, value: item.value, title: item.title }))
      this.#queue.replace(inputs)
    }
    await this.#logger.info('cloud', 'Cloud sync queue started', {
      total: this.#queue.snapshot.progress.total,
      ...(itemIds?.length ? { selected: itemIds.length } : {}),
    })
    void this.#queue
      .start()
      .then(() => {
        const progress = this.#queue.snapshot.progress
        return this.#logger[progress.failed > 0 ? 'warn' : 'info'](
          'cloud',
          'Cloud sync queue completed',
          {
            total: progress.total,
            uploaded: progress.uploaded,
            alreadyUploaded: progress.alreadyUploaded,
            failed: progress.failed,
            skipped: progress.skipped,
            cancelled: progress.cancelled,
            elapsedMs: progress.elapsedMs,
          },
        )
      })
      .catch((error: unknown) => {
        void this.#logger.error('cloud', 'Cloud queue failed', { error })
      })
    return this.#mapQueueSnapshot(this.#queue.snapshot)
  }

  #resumeCloudQueue(): CloudQueueSnapshot {
    this.#assertNoScheduledUpload()
    void this.#logger.info('cloud', 'Cloud sync queue resumed')
    void this.#queue.resume().catch((error: unknown) => {
      void this.#logger.error('cloud', 'Cloud queue resume failed', { error })
    })
    return this.#mapQueueSnapshot(this.#queue.snapshot)
  }

  async #cancelCloudQueue(): Promise<CloudQueueSnapshot> {
    await this.#logger.info('cloud', 'Cloud sync queue cancellation requested')
    const cancellation = this.#queue.cancel()
    this.#send(IPC_CHANNELS.cloud.event, {
      type: 'snapshot',
      snapshot: this.#mapQueueSnapshot(this.#queue.snapshot, 'cancelling'),
    })
    await cancellation
    return this.#mapQueueSnapshot(this.#queue.snapshot)
  }

  #retryCloudQueue(ids: string[]): CloudQueueSnapshot {
    this.#assertNoScheduledUpload()
    void this.#logger.info('cloud', 'Cloud sync queue retry requested', { items: ids.length })
    void this.#queue.retry(new Set(ids)).catch((error: unknown) => {
      void this.#logger.error('cloud', 'Cloud queue retry failed', { error })
    })
    return this.#mapQueueSnapshot(this.#queue.snapshot)
  }

  async #refreshGameLibrary(): Promise<LibraryRefreshResult> {
    const warnings: string[] = []
    const previousLocalSnapshot = this.#localSnapshot
    this.#suppressLibraryEvents = true
    this.#gameLibrary.setRefreshing(true)
    try {
      try {
        await this.#scanLocal('default', true)
      } catch (error) {
        this.#localSnapshot = previousLocalSnapshot
        warnings.push(
          'Local games could not be rescanned; the previous scan was kept where possible.',
        )
        await this.#logger.warn('library', 'Library local refresh failed', { error })
      }
      if (this.#auth.getState().authenticated) {
        try {
          await this.#refreshCloudLibrary()
        } catch (error) {
          warnings.push('Epic ownership could not be refreshed; the cached library was kept.')
          await this.#logger.warn('library', 'Library ownership refresh failed', { error })
        }
      }
      const catalog = await this.#catalog.refresh()
      if (catalog.state === 'failed' && catalog.error) {
        warnings.push('Some game metadata could not be refreshed; cached details were kept.')
      }
      const taxonomy = await this.#catalog.refreshTaxonomy(true)
      if (taxonomy.warning) warnings.push(taxonomy.warning)
    } catch (error) {
      warnings.push('The Library refresh completed with cached data.')
      await this.#logger.warn('library', 'Library refresh completed with an unexpected warning', {
        error,
      })
    } finally {
      this.#updateGameLibrarySources()
      this.#gameLibrary.markRefreshed(warnings)
      this.#suppressLibraryEvents = false
    }
    const status = this.#gameLibrary.getStatus()
    this.#send(IPC_CHANNELS.library.changedEvent, { status })
    return { status, warnings: [...warnings].slice(0, 20) }
  }

  #mapQueueSnapshot(
    snapshot: QueueSnapshot<EpicLibraryItem>,
    stateOverride?: CloudQueueSnapshot['state'],
  ): CloudQueueSnapshot {
    return mapQueueSnapshot(snapshot, stateOverride, (item, fallback) =>
      this.#resolveCatalogDisplayName(
        {
          namespace: item.namespace,
          catalogItemId: item.catalogItemId,
          artifactId: item.assetId || item.appName,
          appName: item.appName,
          platform: this.#platform,
        },
        fallback,
      ),
    )
  }

  #resolveCatalogDisplayName(
    input: Parameters<CatalogService['resolveDisplayName']>[0],
    fallback: string,
  ): string {
    try {
      return this.#catalog.resolveDisplayName(input)?.displayName || fallback
    } catch {
      return fallback
    }
  }

  #cloudCatalogScope(accountId: string): string {
    const opaqueAccount = createHash('sha256').update(accountId, 'utf8').digest('hex').slice(0, 32)
    return `cloud:${opaqueAccount}:${this.#platform.toLowerCase()}`
  }

  #reconcileLibraryToolsCatalog(): void {
    void this.#catalog
      .reconcileNames('library-tools', 'library-tools', this.#libraryTools.catalogInterests())
      .catch((error: unknown) => {
        void this.#logger.warn(
          'catalog',
          'Library Tools catalog interests could not be reconciled',
          {
            error,
          },
        )
      })
  }

  #onCatalogUpdated(): void {
    if (this.#localSnapshot.manifests.length > 0) {
      this.#localSnapshot = {
        ...this.#localSnapshot,
        manifests: this.#localSnapshot.manifests.map((manifest) => ({
          ...manifest,
          displayName: this.#resolveCatalogDisplayName(
            {
              namespace: manifest.namespace,
              catalogItemId: manifest.catalogItemId,
              artifactId: manifest.appName,
              appName: manifest.appName,
              platform: manifest.platform,
            },
            manifest.displayName,
          ),
        })),
      }
      this.#send(IPC_CHANNELS.local.scanEvent, {
        type: 'finished',
        snapshot: this.#localSnapshot,
      })
    }
    this.#send(IPC_CHANNELS.cloud.event, {
      type: 'snapshot',
      snapshot: this.#mapQueueSnapshot(this.#queue.snapshot),
    })
    this.#gameLibrary.invalidate()
    this.#emitLibraryChanged()
  }

  #updateGameLibrarySources(): void {
    this.#gameLibrary.setSources({
      owned: this.#queue.snapshot.items.map((entry) => entry.value),
      local: this.#localSnapshot.manifests,
      signedIn: this.#auth.getState().authenticated,
      localScanState: this.#localSnapshot.state,
    })
  }

  #emitLibraryChanged(): void {
    if (this.#suppressLibraryEvents) return
    this.#send(IPC_CHANNELS.library.changedEvent, {
      status: this.#gameLibrary.getStatus(),
    })
  }

  async #diagnosticsSnapshot() {
    const logDirectory = join(this.#userData, 'diagnostics')
    let fileCount = 0
    let totalBytes = 0
    try {
      for (const entry of await readdir(logDirectory, { withFileTypes: true })) {
        if (!entry.isFile()) continue
        fileCount += 1
        totalBytes += (await stat(join(logDirectory, entry.name))).size
      }
    } catch {
      // The directory is created on the first diagnostic write.
    }
    return {
      logDirectory,
      fileCount,
      totalBytes,
      recentEntries: this.#logger.recentEntries(),
      logger: this.#logger.health(),
    }
  }

  async #exportDiagnostics(includePaths: boolean) {
    const settings = await this.#settings.getPreferences()
    if (includePaths && !settings.includePathsInDiagnostics) {
      throw new Error('Enable path sharing in settings before exporting paths.')
    }
    const result = await dialog.showSaveDialog(this.#requireWindow(), {
      title: 'Export egdata.app diagnostics',
      defaultPath: `egdata-diagnostics-${new Date().toISOString().slice(0, 10)}.log`,
      filters: [{ name: 'Log file', extensions: ['log'] }],
    })
    if (result.canceled || !result.filePath) return { cancelled: true }
    await this.#logger.flush()
    await mkdir(dirname(result.filePath), { recursive: true })
    try {
      await copyFile(join(this.#userData, 'diagnostics', 'egdata.log'), result.filePath)
    } catch {
      throw new Error('No diagnostic log is available yet.')
    }
    return { cancelled: false, filePath: result.filePath }
  }

  #revealLogs(): { ok: true } {
    const logPath = join(this.#userData, 'diagnostics', 'egdata.log')
    shell.showItemInFolder(logPath)
    return { ok: true }
  }

  #send(channel: string, value: unknown): void {
    const window = this.#getWindow()
    if (window && !window.isDestroyed()) window.webContents.send(channel, value)
  }

  async #getPublicSettings() {
    return this.#mapPublicSettings(await this.#settings.getPreferences())
  }

  #canRunScheduledUpload(source: 'local' | 'cloud'): boolean {
    if (this.#updateInstallBarrier || this.#scheduledUploadSource || this.#manifestWorkIsBusy())
      return false
    return source === 'local' || this.#auth.getState().authenticated
  }

  #manifestWorkIsBusy(): boolean {
    const queueState = this.#queue.snapshot.state
    const libraryTools = this.#libraryTools.snapshot
    const moveState = libraryTools.move?.state
    return (
      this.#scheduledUploadSource !== null ||
      this.#localSnapshot.state === 'scanning' ||
      this.#localUpload?.state === 'running' ||
      this.#cloudRefreshActive ||
      ['running', 'pausing', 'paused'].includes(queueState) ||
      libraryTools.state !== 'idle' ||
      (moveState !== undefined && !['complete', 'cancelled', 'failed'].includes(moveState))
    )
  }

  async #runScheduledUpload(source: 'local' | 'cloud', signal: AbortSignal): Promise<void> {
    this.#scheduledUploadSource = source
    await this.#logger.info('uploads', `Scheduled ${source} manifest cycle started`)
    try {
      if (source === 'local') await this.#runScheduledLocalUpload(signal)
      else await this.#runScheduledCloudUpload(signal)
      await this.#logger.info('uploads', `Scheduled ${source} manifest cycle completed`)
    } finally {
      this.#scheduledUploadSource = null
    }
  }

  async #runScheduledLocalUpload(signal: AbortSignal): Promise<void> {
    const snapshot = await this.#scanLocal('default')
    if (signal.aborted) return
    const manifestIds = snapshot.manifests
      .filter((manifest) => manifest.binaryManifestAvailable)
      .map((manifest) => manifest.id)
    if (manifestIds.length === 0) return
    await this.#uploadLocal(manifestIds, { concurrency: 1, signal })
  }

  async #runScheduledCloudUpload(signal: AbortSignal): Promise<void> {
    await this.#refreshCloudLibrary()
    if (signal.aborted) return
    const retryable = this.#queue.snapshot.items.some((item) =>
      ['failed', 'skipped', 'cancelled'].includes(item.state),
    )
    const cancel = () => void this.#queue.cancel()
    signal.addEventListener('abort', cancel, { once: true })
    try {
      if (retryable) await this.#queue.retry(undefined, { concurrency: 1 })
      else await this.#queue.start({ concurrency: 1 })
    } finally {
      signal.removeEventListener('abort', cancel)
    }
  }

  #assertNoScheduledUpload(): void {
    if (this.#updateInstallBarrier) {
      throw new Error('An egdata.app update is being prepared for installation.')
    }
    if (this.#scheduledUploadSource) {
      throw new Error('A scheduled manifest upload is already running.')
    }
  }

  #requireUpdates(): UpdateService {
    if (!this.#updates) throw new Error('The update service is not ready.')
    return this.#updates
  }

  async #cancelManifestWorkForUpdate(): Promise<void> {
    this.#scheduledUploads?.cancelActive()
    this.#localUploadController?.abort()
    this.#cloudRefreshController?.abort()

    const cancellations: Promise<unknown>[] = []
    if (['running', 'pausing', 'paused'].includes(this.#queue.snapshot.state)) {
      cancellations.push(this.#queue.cancel())
    }
    if (this.#libraryTools.snapshot.state === 'scanning') {
      cancellations.push(this.#libraryTools.cancelScan())
    }
    const move = this.#libraryTools.snapshot.move
    if (move && !['complete', 'cancelled', 'failed'].includes(move.state)) {
      this.#libraryTools.cancelMove(move.operationId)
    }
    await Promise.allSettled(cancellations)

    const deadline = Date.now() + 120_000
    while (this.#manifestWorkIsBusy() && Date.now() < deadline) {
      await new Promise<void>((resolve) => setTimeout(resolve, 100))
    }
    if (this.#manifestWorkIsBusy()) {
      throw new Error('Manifest work did not stop safely. Try installing again when it is idle.')
    }
  }

  #mapPublicSettings(settings: Awaited<ReturnType<SettingsStorage['getPreferences']>>) {
    const launchAtStartup = this.#launchAtStartup.getStatus()
    return PublicSettingsSchema.parse({
      ...settings,
      launchAtStartup: launchAtStartup.enabled,
      launchAtStartupAvailable: launchAtStartup.available,
    })
  }

  #requireWindow(): BrowserWindow {
    const window = this.#getWindow()
    if (!window || window.isDestroyed()) throw new Error('The application window is unavailable.')
    return window
  }

  #assertTrustedSender(event: IpcMainInvokeEvent): void {
    const frame = event.senderFrame
    if (
      !frame ||
      frame !== event.sender.mainFrame ||
      !isTrustedRenderer(event.sender, this.#isDevelopment)
    ) {
      throw new Error('Untrusted IPC sender')
    }
  }
}

function emptyLocalSnapshot(): LocalScanSnapshot {
  return { state: 'idle', manifests: [], issues: [] }
}

function cloudItemId(item: EpicLibraryItem): string {
  return `${item.namespace}:${item.catalogItemId}:${item.appName}`.slice(0, 256)
}

function mapQueueSnapshot(
  snapshot: QueueSnapshot<EpicLibraryItem>,
  stateOverride?: CloudQueueSnapshot['state'],
  resolveDisplayName?: (item: EpicLibraryItem, fallback: string) => string,
): CloudQueueSnapshot {
  const items: CloudQueueItem[] = snapshot.items.map((entry) => {
    const started = entry.startedAt ? Date.parse(entry.startedAt) : null
    const finished = entry.finishedAt ? Date.parse(entry.finishedAt) : Date.now()
    return {
      id: entry.id,
      appName: entry.value.appName,
      displayName: resolveDisplayName?.(entry.value, entry.title) ?? entry.title,
      catalogItemId: entry.value.catalogItemId,
      namespace: entry.value.namespace,
      state: entry.state === 'alreadyUploaded' ? 'already-uploaded' : entry.state,
      attempts: entry.attempts,
      ...(entry.startedAt ? { startedAt: entry.startedAt } : {}),
      ...(entry.finishedAt ? { finishedAt: entry.finishedAt } : {}),
      ...(started !== null ? { durationMs: Math.max(0, finished - started) } : {}),
      ...(entry.error
        ? {
            error: {
              code: queueErrorCode(entry.error),
              message: queueErrorMessage(entry.error),
              retryable: true,
            },
          }
        : {}),
    }
  })
  const state =
    stateOverride ??
    (snapshot.state === 'paused'
      ? 'paused'
      : snapshot.state === 'running' || snapshot.state === 'pausing'
        ? 'running'
        : snapshot.state === 'idle'
          ? 'idle'
          : 'complete')
  return {
    state,
    ...(snapshot.startedAt ? { startedAt: snapshot.startedAt } : {}),
    elapsedMs: snapshot.progress.elapsedMs,
    counts: {
      pending: snapshot.progress.pending,
      running: snapshot.progress.running,
      uploaded: snapshot.progress.uploaded,
      alreadyUploaded: snapshot.progress.alreadyUploaded,
      failed: snapshot.progress.failed,
      skipped: snapshot.progress.skipped,
      cancelled: snapshot.progress.cancelled,
    },
    items,
  }
}

function queueErrorCode(error: string): SafeError['code'] {
  if (error.includes('EPIC_SESSION')) return 'EPIC_SESSION_EXPIRED'
  if (error.includes('EPIC_MANIFEST')) return 'EPIC_MANIFEST_DOWNLOAD_FAILED'
  if (error.includes('UPLOAD_TIMEOUT')) return 'UPLOAD_TIMEOUT'
  if (error.includes('SYNC_CANCELLED')) return 'SYNC_CANCELLED'
  return 'UPLOAD_REJECTED'
}

function queueErrorMessage(error: string): string {
  const code = queueErrorCode(error)
  const messages: Record<SafeError['code'], string> = {
    LOCAL_MANIFEST_DIRECTORY_MISSING: 'The Epic manifest directory is missing.',
    LOCAL_ITEM_PERMISSION_DENIED: 'A local manifest could not be read.',
    LOCAL_ITEM_INVALID_JSON: 'A local item file contains malformed JSON.',
    LOCAL_BINARY_MANIFEST_MISSING: 'The binary manifest is missing.',
    EPIC_NOT_AUTHENTICATED: 'Connect Epic Games to continue.',
    EPIC_LOGIN_CANCELLED: 'Epic sign-in was cancelled.',
    EPIC_SESSION_EXPIRED: 'The Epic session expired. Connect again.',
    EPIC_LIBRARY_REQUEST_FAILED: 'The Epic library could not be loaded.',
    EPIC_MANIFEST_UNAVAILABLE: 'No cloud manifest is available.',
    EPIC_MANIFEST_DOWNLOAD_FAILED: 'The cloud manifest could not be downloaded.',
    UPLOAD_TIMEOUT: 'The manifest upload timed out.',
    UPLOAD_REJECTED: 'The manifest upload failed.',
    UPLOAD_RESPONSE_INVALID: 'The upload service returned an invalid response.',
    SYNC_CANCELLED: 'The sync item was cancelled.',
    CATALOG_UNAVAILABLE: 'The local catalog is unavailable.',
    CATALOG_SYNC_FAILED: 'The catalog could not be synchronized.',
    CATALOG_SYNC_CANCELLED: 'The catalog sync was cancelled.',
    CATALOG_RESPONSE_INVALID: 'The catalog hydration response failed validation.',
    CATALOG_STORAGE_FAILED: 'The local catalog could not be stored.',
    VALIDATION_FAILED: 'The request was invalid.',
    INTERNAL_ERROR: 'The operation failed.',
  }
  return messages[code]
}

function uploadSafeError(code: string, message: string): SafeError {
  const known = [
    'UPLOAD_TIMEOUT',
    'UPLOAD_REJECTED',
    'UPLOAD_RESPONSE_INVALID',
    'SYNC_CANCELLED',
    'LOCAL_BINARY_MANIFEST_MISSING',
    'LOCAL_ITEM_PERMISSION_DENIED',
  ] as const
  const safeCode = known.find((candidate) => candidate === code) ?? 'UPLOAD_REJECTED'
  return { code: safeCode, message: message.slice(0, 2_000), retryable: true }
}

function isTrustedRenderer(webContents: WebContents, isDevelopment: boolean): boolean {
  const url = webContents.getURL()
  try {
    const target = new URL(url)
    if (isDevelopment && process.env.ELECTRON_RENDERER_URL) {
      return target.origin === new URL(process.env.ELECTRON_RENDERER_URL).origin
    }
    const expected = pathToFileURL(join(__dirname, '../renderer/index.html'))
    return target.protocol === 'file:' && target.pathname === expected.pathname
  } catch {
    return false
  }
}

function publicErrorMessage(error: unknown): string {
  if (!(error instanceof Error)) return 'The operation failed.'
  const code = 'code' in error && typeof error.code === 'string' ? error.code : ''
  const known: Record<string, string> = {
    EPIC_CONFIGURATION_MISSING:
      'Epic sign-in is not configured in this build. Set EPIC_CLIENT_ID and EPIC_CLIENT_SECRET.',
    EPIC_LOGIN_CANCELLED: 'Epic sign-in was cancelled.',
    EPIC_LOGIN_TIMEOUT: 'Epic sign-in timed out.',
    EPIC_SESSION_EXPIRED: 'The Epic session expired. Connect again.',
    EPIC_NOT_AUTHENTICATED: 'Connect Epic Games first.',
  }
  return known[code] ?? (error.message.slice(0, 500) || 'The operation failed.')
}

function libraryToolsPublicErrorMessage(error: unknown): string {
  const message = error instanceof Error ? error.message : ''
  const approved = new Set([
    'Library tools are already working.',
    'Close Epic Games Launcher before recovery.',
    'A selected recovery candidate is no longer available.',
    'A discovered manifest changed. Scan the drives again.',
    'Game moving is available on Windows only.',
    'A game move is already active.',
    'Close Epic Games Launcher before moving a game.',
    'This game cannot be moved.',
    'Choose a regular destination folder.',
    'The destination is the current game location.',
    'The destination cannot be inside the game folder.',
    'A folder with this game name already exists at the destination.',
    'The installation is missing its .egstore data.',
    'The destination does not have enough free space.',
    'The prepared move has expired.',
    'Epic Games Launcher was opened during the move.',
  ])
  return approved.has(message) ? message : 'The library operation could not be completed.'
}

function catalogPublicErrorMessage(error: unknown): string {
  const code =
    error instanceof Error && 'code' in error && typeof error.code === 'string' ? error.code : ''
  const messages: Record<string, string> = {
    CATALOG_UNAVAILABLE: 'The local catalog is unavailable.',
    CATALOG_SYNC_FAILED: 'The catalog could not be synchronized.',
    CATALOG_SYNC_CANCELLED: 'The catalog sync was cancelled.',
    CATALOG_RESPONSE_INVALID: 'The catalog hydration response failed validation.',
    CATALOG_STORAGE_FAILED: 'The local catalog could not be stored.',
  }
  return messages[code] ?? 'The catalog operation could not be completed.'
}
