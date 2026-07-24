import type { DesktopApi as PreloadDesktopApi } from '../../shared/api'
import type {
  AuthStatus,
  CloudQueueEvent,
  CloudQueueSnapshot,
  LocalManifest as PreloadLocalManifest,
  LocalScanSnapshot,
  LocalUploadSnapshot,
  LibraryChangedEvent,
  LibraryDetails,
  LibraryDetailsRequest,
  LibraryPage,
  LibraryQueryRequest,
  LibraryRefreshResult,
  LibraryStatus,
  LibraryToolsSnapshot,
  LauncherStatus,
  MovePreparation,
  PublicSettings,
  UpdateStatus as PreloadUpdateStatus,
} from '../../shared/contracts'

export type HealthState = 'healthy' | 'attention' | 'unavailable' | 'scanning'
export type QueueState =
  | 'pending'
  | 'running'
  | 'uploaded'
  | 'alreadyPresent'
  | 'failed'
  | 'skipped'
  | 'cancelled'
  | 'removed'

export interface ResultSummary {
  uploaded: number
  alreadyPresent: number
  skipped: number
  failed: number
  finishedAt?: string
}

export interface LocalManifest {
  id: string
  displayName: string
  appName: string
  kind: 'base' | 'addon'
  manifestAvailable: boolean
  sourceFile: string
  version?: string
  issue?: { code: string; message: string }
}

export interface LocalManifestGroup {
  id: string
  displayName: string
  base?: LocalManifest
  addons: LocalManifest[]
}

export interface LocalSnapshot {
  health: HealthState
  sourceLabel: string
  scannedAt?: string
  groups: LocalManifestGroup[]
  issues: Array<{ id: string; fileName: string; code: string; message: string }>
  lastResult?: ResultSummary
}

export interface EpicAuthStatus {
  state: 'signedOut' | 'connecting' | 'signedIn' | 'expired'
  displayName?: string
  accountHint?: string
}

export interface CloudQueueItem {
  id: string
  displayName: string
  appName: string
  state: QueueState
  attempts: number
  durationMs?: number
  startedAt?: string
  finishedAt?: string
  error?: { code: string; message: string }
}

export interface CloudSnapshot {
  state: 'idle' | 'running' | 'paused' | 'cancelling'
  libraryCount: number
  queue: CloudQueueItem[]
  completed: number
  elapsedMs?: number
  lastResult?: ResultSummary
}

export interface ContributionSettings {
  onboardingComplete: boolean
  contributionConsent: boolean
  automaticUploadsEnabled: boolean
  automaticLocalUploadIntervalMinutes: 60 | 180 | 360 | 720 | 1440 | 4320 | 10080
  automaticCloudUploadIntervalMinutes: 60 | 180 | 360 | 720 | 1440 | 4320 | 10080
  shareDiagnosticPaths: boolean
  automaticUpdateChecks: boolean
  updateChannel: 'stable' | 'beta'
  automaticallyScanWindowsDrives: boolean
  launchAtStartup: boolean
  launchAtStartupAvailable: boolean
}

export interface UpdateStatus {
  state:
    | 'idle'
    | 'checking'
    | 'available'
    | 'not-available'
    | 'downloading'
    | 'downloaded'
    | 'installing'
    | 'error'
  currentVersion: string
  channel: 'stable' | 'beta'
  delivery: 'managed' | 'manual' | 'store'
  availableVersion?: string
  progressPercent?: number
  releaseNotesUrl?: string
  message?: string
}

export interface DiagnosticsInfo {
  logLocationLabel: string
  retentionDays: number
}

export interface AppInfo {
  name: string
  version: string
  platform: 'Windows' | 'Mac'
}

export interface DesktopApi {
  localManifests: {
    getSnapshot(): Promise<LocalSnapshot>
    scan(): Promise<LocalSnapshot>
    upload(input: { ids: string[] }): Promise<ResultSummary>
    onChanged(listener: (snapshot: LocalSnapshot) => void): () => void
  }
  libraryTools: {
    getSnapshot(): Promise<LibraryToolsSnapshot>
    getLauncherStatus(): Promise<LauncherStatus>
    tryCloseLauncher(): Promise<LauncherStatus>
    scan(): Promise<LibraryToolsSnapshot>
    cancelScan(): Promise<LibraryToolsSnapshot>
    recover(input: { candidateIds: string[] }): Promise<LibraryToolsSnapshot>
    prepareMove(input: { gameId: string }): Promise<MovePreparation>
    startMove(input: { operationId: string }): Promise<LibraryToolsSnapshot>
    cancelMove(input: { operationId: string }): Promise<LibraryToolsSnapshot>
    onChanged(listener: (snapshot: LibraryToolsSnapshot) => void): () => void
  }
  epicAuth: {
    getStatus(): Promise<EpicAuthStatus>
    connect(): Promise<EpicAuthStatus>
    disconnect(): Promise<void>
    onChanged(listener: (status: EpicAuthStatus) => void): () => void
  }
  cloudSync: {
    getSnapshot(): Promise<CloudSnapshot>
    refreshLibrary(): Promise<CloudSnapshot>
    start(): Promise<void>
    pause(): Promise<void>
    resume(): Promise<void>
    cancel(): Promise<void>
    retry(input: { ids?: string[] }): Promise<void>
    remove(input: { ids: string[] }): Promise<void>
    clearCompleted(): Promise<void>
    onChanged(listener: (snapshot: CloudSnapshot) => void): () => void
  }
  library: {
    getStatus(): Promise<LibraryStatus>
    query(request: LibraryQueryRequest): Promise<LibraryPage>
    getDetails(request: LibraryDetailsRequest): Promise<LibraryDetails>
    refresh(): Promise<LibraryRefreshResult>
    onChanged(listener: (event: LibraryChangedEvent) => void): () => void
  }
  settings: {
    get(): Promise<ContributionSettings>
    update(patch: Partial<ContributionSettings>): Promise<ContributionSettings>
    clearEpicSession(): Promise<void>
  }
  updates: {
    getStatus(): Promise<UpdateStatus>
    check(): Promise<UpdateStatus>
    download(): Promise<UpdateStatus>
    install(input: { cancelActiveWork: boolean }): Promise<{
      outcome: 'started' | 'confirmation-required'
    }>
    onChanged(listener: (status: UpdateStatus) => void): () => void
  }
  diagnostics: {
    getInfo(): Promise<DiagnosticsInfo>
    export(input: { includePaths: boolean }): Promise<{ savedTo?: string; cancelled: boolean }>
    openLogLocation(): Promise<void>
  }
  app: {
    getInfo(): Promise<AppInfo>
    openExternal(url: string): Promise<void>
  }
}

const onboardingKey = 'egdata.renderer.onboarding-complete'
let lastLocalResult: ResultSummary | undefined

export class DesktopApiUnavailableError extends Error {
  constructor() {
    super('The secure desktop bridge is unavailable. Restart egdata.app and try again.')
    this.name = 'DesktopApiUnavailableError'
  }
}

function preload(): PreloadDesktopApi {
  const desktopApi = (window as Window & { readonly desktopApi?: PreloadDesktopApi }).desktopApi
  if (!desktopApi) throw new DesktopApiUnavailableError()
  return desktopApi
}

function mapManifest(manifest: PreloadLocalManifest, kind?: 'base' | 'addon'): LocalManifest {
  return {
    id: manifest.id,
    displayName: manifest.displayName || manifest.appName,
    appName: manifest.appName,
    kind: kind ?? (manifest.kind === 'addon' ? 'addon' : 'base'),
    manifestAvailable: manifest.binaryManifestAvailable,
    sourceFile: manifest.sourceFilename,
  }
}

function mapLocal(snapshot: LocalScanSnapshot): LocalSnapshot {
  const grouped = new Map<string, PreloadLocalManifest[]>()
  for (const manifest of snapshot.manifests) {
    const current = grouped.get(manifest.groupId) ?? []
    current.push(manifest)
    grouped.set(manifest.groupId, current)
  }

  const groups = Array.from(grouped, ([id, records]) => {
    const representative = records.find((record) => record.kind === 'base-game') ?? records[0]
    const addons = records
      .filter((record) => record !== representative)
      .map((record) => mapManifest(record, 'addon'))
    return {
      id,
      displayName: representative?.displayName || representative?.appName || 'Unknown application',
      ...(representative
        ? { base: mapManifest(representative, representative.kind === 'addon' ? 'addon' : 'base') }
        : {}),
      addons,
    } satisfies LocalManifestGroup
  })

  const health: HealthState =
    snapshot.state === 'scanning'
      ? 'scanning'
      : snapshot.state === 'failed'
        ? 'unavailable'
        : snapshot.issues.length > 0
          ? 'attention'
          : 'healthy'

  return {
    health,
    sourceLabel: 'Epic Launcher default manifest directory',
    ...(snapshot.scannedAt ? { scannedAt: snapshot.scannedAt } : {}),
    groups,
    issues: snapshot.issues.map((issue) => ({
      id: issue.id,
      fileName: issue.sourceFilename,
      code: issue.error.code,
      message: issue.error.message,
    })),
    ...(lastLocalResult ? { lastResult: lastLocalResult } : {}),
  }
}

function summarizeUpload(snapshot: LocalUploadSnapshot): ResultSummary {
  const summary: ResultSummary = {
    uploaded: snapshot.items.filter((item) => item.state === 'uploaded').length,
    alreadyPresent: snapshot.items.filter((item) => item.state === 'already-uploaded').length,
    skipped: snapshot.items.filter((item) => item.state === 'cancelled').length,
    failed: snapshot.items.filter((item) => item.state === 'failed').length,
    finishedAt: new Date().toISOString(),
  }
  lastLocalResult = summary
  return summary
}

function mapAuth(status: AuthStatus): EpicAuthStatus {
  const states = {
    'signed-out': 'signedOut',
    'signing-in': 'connecting',
    'signed-in': 'signedIn',
    expired: 'expired',
  } as const
  return {
    state: states[status.state],
    ...(status.displayName ? { displayName: status.displayName } : {}),
    ...(status.accountId ? { accountHint: status.accountId } : {}),
  }
}

function mapQueueState(state: CloudQueueSnapshot['items'][number]['state']): QueueState {
  return state === 'already-uploaded' ? 'alreadyPresent' : state
}

function mapCloud(snapshot: CloudQueueSnapshot): CloudSnapshot {
  const finished = snapshot.items.filter((item) => !['pending', 'running'].includes(item.state))
  const hasResults = finished.length > 0
  return {
    state: snapshot.state === 'complete' ? 'idle' : snapshot.state,
    libraryCount: snapshot.items.length,
    queue: snapshot.items.map((item) => ({
      id: item.id,
      displayName: item.displayName || item.appName,
      appName: item.appName,
      state: mapQueueState(item.state),
      attempts: item.attempts,
      ...(item.durationMs !== undefined ? { durationMs: item.durationMs } : {}),
      ...(item.startedAt ? { startedAt: item.startedAt } : {}),
      ...(item.finishedAt ? { finishedAt: item.finishedAt } : {}),
      ...(item.error ? { error: { code: item.error.code, message: item.error.message } } : {}),
    })),
    completed: finished.length,
    elapsedMs: snapshot.elapsedMs,
    ...(hasResults
      ? {
          lastResult: {
            uploaded: snapshot.counts.uploaded,
            alreadyPresent: snapshot.counts.alreadyUploaded,
            skipped: snapshot.counts.skipped + snapshot.counts.cancelled,
            failed: snapshot.counts.failed,
            finishedAt: new Date().toISOString(),
          },
        }
      : {}),
  }
}

function mapSettings(settings: PublicSettings): ContributionSettings {
  let onboardingComplete = false
  try {
    onboardingComplete = localStorage.getItem(onboardingKey) === 'true'
  } catch {
    // The settings API remains usable if storage is blocked by browser policy.
  }
  return {
    onboardingComplete,
    contributionConsent: settings.contributionConsent,
    automaticUploadsEnabled: settings.automaticUploadsEnabled,
    automaticLocalUploadIntervalMinutes: settings.automaticLocalUploadIntervalMinutes,
    automaticCloudUploadIntervalMinutes: settings.automaticCloudUploadIntervalMinutes,
    shareDiagnosticPaths: settings.includePathsInDiagnostics,
    automaticUpdateChecks: settings.automaticallyCheckForUpdates,
    updateChannel: settings.updateChannel,
    automaticallyScanWindowsDrives: settings.automaticallyScanWindowsDrives,
    launchAtStartup: settings.launchAtStartup,
    launchAtStartupAvailable: settings.launchAtStartupAvailable,
  }
}

function mapUpdate(status: PreloadUpdateStatus): UpdateStatus {
  return {
    state: status.state,
    currentVersion: status.currentVersion,
    channel: status.channel,
    delivery: status.delivery,
    ...(status.availableVersion ? { availableVersion: status.availableVersion } : {}),
    ...(status.progressPercent !== undefined ? { progressPercent: status.progressPercent } : {}),
    ...(status.releaseNotesUrl ? { releaseNotesUrl: status.releaseNotesUrl } : {}),
    ...(status.message
      ? { message: status.message }
      : status.error?.message
        ? { message: status.error.message }
        : {}),
  }
}

async function updateSettings(patch: Partial<ContributionSettings>): Promise<ContributionSettings> {
  if (patch.onboardingComplete !== undefined) {
    try {
      localStorage.setItem(onboardingKey, String(patch.onboardingComplete))
    } catch {
      // Contribution preferences still persist through the privileged settings API.
    }
  }
  const request: Partial<PublicSettings> = {}
  if (patch.contributionConsent !== undefined)
    request.contributionConsent = patch.contributionConsent
  if (patch.automaticUploadsEnabled !== undefined)
    request.automaticUploadsEnabled = patch.automaticUploadsEnabled
  if (patch.automaticLocalUploadIntervalMinutes !== undefined)
    request.automaticLocalUploadIntervalMinutes = patch.automaticLocalUploadIntervalMinutes
  if (patch.automaticCloudUploadIntervalMinutes !== undefined)
    request.automaticCloudUploadIntervalMinutes = patch.automaticCloudUploadIntervalMinutes
  if (patch.shareDiagnosticPaths !== undefined)
    request.includePathsInDiagnostics = patch.shareDiagnosticPaths
  if (patch.automaticUpdateChecks !== undefined)
    request.automaticallyCheckForUpdates = patch.automaticUpdateChecks
  if (patch.updateChannel !== undefined) request.updateChannel = patch.updateChannel
  if (patch.automaticallyScanWindowsDrives !== undefined)
    request.automaticallyScanWindowsDrives = patch.automaticallyScanWindowsDrives
  if (patch.launchAtStartup !== undefined) request.launchAtStartup = patch.launchAtStartup
  const settings =
    Object.keys(request).length > 0
      ? await preload().settings.update(request)
      : await preload().settings.get()
  return mapSettings(settings)
}

function onCloudEvent(listener: (snapshot: CloudSnapshot) => void, event: CloudQueueEvent): void {
  if (event.type === 'snapshot') {
    listener(mapCloud(event.snapshot))
    return
  }
  void preload()
    .cloudQueue.getSnapshot()
    .then((snapshot) => listener(mapCloud(snapshot)))
}

const rendererApi: DesktopApi = {
  localManifests: {
    getSnapshot: async () => mapLocal(await preload().localManifests.getScanSnapshot()),
    scan: async () => mapLocal(await preload().localManifests.scan({ source: 'default' })),
    upload: async ({ ids }) =>
      summarizeUpload(await preload().localManifests.upload({ manifestIds: ids })),
    onChanged: (listener) => {
      const cleanScan = preload().localManifests.onScanEvent((event) => {
        if (event.type === 'finished') listener(mapLocal(event.snapshot))
      })
      const cleanUpload = preload().localManifests.onUploadEvent((snapshot) => {
        summarizeUpload(snapshot)
        void preload()
          .localManifests.getScanSnapshot()
          .then((scan) => listener(mapLocal(scan)))
      })
      return () => {
        cleanScan()
        cleanUpload()
      }
    },
  },
  libraryTools: {
    getSnapshot: () => preload().libraryTools.getSnapshot(),
    getLauncherStatus: () => preload().libraryTools.getLauncherStatus(),
    tryCloseLauncher: () => preload().libraryTools.tryCloseLauncher(),
    scan: () => preload().libraryTools.scan(),
    cancelScan: () => preload().libraryTools.cancelScan(),
    recover: ({ candidateIds }) => preload().libraryTools.recover({ candidateIds }),
    prepareMove: ({ gameId }) => preload().libraryTools.prepareMove({ gameId }),
    startMove: ({ operationId }) => preload().libraryTools.startMove({ operationId }),
    cancelMove: ({ operationId }) => preload().libraryTools.cancelMove({ operationId }),
    onChanged: (listener) => preload().libraryTools.onEvent((event) => listener(event.snapshot)),
  },
  epicAuth: {
    getStatus: async () => mapAuth(await preload().epicAuth.getStatus()),
    connect: async () => mapAuth(await preload().epicAuth.login()),
    disconnect: async () => {
      await preload().epicAuth.logout()
    },
    onChanged: (listener) =>
      preload().epicAuth.onStatusChange((status) => listener(mapAuth(status))),
  },
  cloudSync: {
    getSnapshot: async () => mapCloud(await preload().cloudQueue.getSnapshot()),
    refreshLibrary: async () => mapCloud(await preload().cloudQueue.refresh()),
    start: async () => {
      await preload().cloudQueue.start({})
    },
    pause: async () => {
      await preload().cloudQueue.pause()
    },
    resume: async () => {
      await preload().cloudQueue.resume()
    },
    cancel: async () => {
      await preload().cloudQueue.cancel()
    },
    retry: async ({ ids }) => {
      let itemIds = ids
      if (!itemIds?.length) {
        const snapshot = await preload().cloudQueue.getSnapshot()
        itemIds = snapshot.items
          .filter((item) => ['failed', 'skipped', 'cancelled'].includes(item.state))
          .map((item) => item.id)
      }
      if (itemIds.length) await preload().cloudQueue.retry({ itemIds })
    },
    remove: async ({ ids }) => {
      await preload().cloudQueue.remove({ itemIds: ids })
    },
    clearCompleted: async () => {
      await preload().cloudQueue.clearCompleted()
    },
    onChanged: (listener) => preload().cloudQueue.onEvent((event) => onCloudEvent(listener, event)),
  },
  library: {
    getStatus: () => preload().library.getStatus(),
    query: (request) => preload().library.query(request),
    getDetails: (request) => preload().library.getDetails(request),
    refresh: () => preload().library.refresh(),
    onChanged: (listener) => preload().library.onChanged(listener),
  },
  settings: {
    get: async () => mapSettings(await preload().settings.get()),
    update: updateSettings,
    clearEpicSession: async () => {
      await preload().epicAuth.logout()
    },
  },
  updates: {
    getStatus: async () => mapUpdate(await preload().updates.getStatus()),
    check: async () => mapUpdate(await preload().updates.check()),
    download: async () => mapUpdate(await preload().updates.download()),
    install: (input) => preload().updates.install(input),
    onChanged: (listener) =>
      preload().updates.onStatusChange((status) => listener(mapUpdate(status))),
  },
  diagnostics: {
    getInfo: async () => {
      const snapshot = await preload().diagnostics.getSnapshot()
      return { logLocationLabel: snapshot.logDirectory, retentionDays: 7 }
    },
    export: async (input) => {
      const result = await preload().diagnostics.export(input)
      return {
        cancelled: result.cancelled,
        ...(result.filePath ? { savedTo: result.filePath } : {}),
      }
    },
    openLogLocation: async () => {
      await preload().diagnostics.revealLogs()
    },
  },
  app: {
    getInfo: async () => {
      const info = await preload().about.getInfo()
      return {
        name: info.productName,
        version: info.version,
        platform: info.platform === 'windows' ? 'Windows' : 'Mac',
      }
    },
    openExternal: (url) => {
      window.open(url, '_blank', 'noopener,noreferrer')
      return Promise.resolve()
    },
  },
}

export function getDesktopApi(): DesktopApi {
  preload()
  return rendererApi
}

export function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : 'Something went wrong. Try again.'
}
