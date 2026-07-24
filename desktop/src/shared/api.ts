import type {
  AboutInfo,
  AuthStatus,
  CloudQueueEvent,
  CloudQueueSnapshot,
  CloudQueueStart,
  DiagnosticExportRequest,
  DiagnosticExportResult,
  DiagnosticsSnapshot,
  DirectorySelection,
  EmptyResult,
  LocalScanEvent,
  LocalScanRequest,
  LocalScanSnapshot,
  LocalUploadRequest,
  LocalUploadSnapshot,
  LibrarySelection,
  LibraryChangedEvent,
  LibraryDetails,
  LibraryDetailsRequest,
  LibraryPage,
  LibraryQueryRequest,
  LibraryRefreshResult,
  LibraryStatus,
  LauncherStatus,
  LibraryToolsEvent,
  LibraryToolsSnapshot,
  GameSelection,
  MovePreparation,
  OperationId,
  PublicSettings,
  QueueSelection,
  SettingsUpdate,
  UpdateInstallRequest,
  UpdateInstallResult,
  UpdateStatus,
} from './contracts'

export type Unsubscribe = () => void

export interface DesktopApi {
  localManifests: {
    selectDirectory(): Promise<DirectorySelection>
    scan(request: LocalScanRequest): Promise<LocalScanSnapshot>
    getScanSnapshot(): Promise<LocalScanSnapshot>
    onScanEvent(listener: (event: LocalScanEvent) => void): Unsubscribe
    upload(request: LocalUploadRequest): Promise<LocalUploadSnapshot>
    cancelUpload(request: OperationId): Promise<EmptyResult>
    onUploadEvent(listener: (snapshot: LocalUploadSnapshot) => void): Unsubscribe
  }
  libraryTools: {
    getSnapshot(): Promise<LibraryToolsSnapshot>
    getLauncherStatus(): Promise<LauncherStatus>
    tryCloseLauncher(): Promise<LauncherStatus>
    scan(): Promise<LibraryToolsSnapshot>
    cancelScan(): Promise<LibraryToolsSnapshot>
    recover(request: LibrarySelection): Promise<LibraryToolsSnapshot>
    prepareMove(request: GameSelection): Promise<MovePreparation>
    startMove(request: OperationId): Promise<LibraryToolsSnapshot>
    cancelMove(request: OperationId): Promise<LibraryToolsSnapshot>
    onEvent(listener: (event: LibraryToolsEvent) => void): Unsubscribe
  }
  epicAuth: {
    getStatus(): Promise<AuthStatus>
    login(): Promise<AuthStatus>
    logout(): Promise<AuthStatus>
    onStatusChange(listener: (status: AuthStatus) => void): Unsubscribe
  }
  cloudQueue: {
    getSnapshot(): Promise<CloudQueueSnapshot>
    refresh(): Promise<CloudQueueSnapshot>
    start(request: CloudQueueStart): Promise<CloudQueueSnapshot>
    pause(): Promise<CloudQueueSnapshot>
    resume(): Promise<CloudQueueSnapshot>
    cancel(): Promise<CloudQueueSnapshot>
    retry(request: QueueSelection): Promise<CloudQueueSnapshot>
    remove(request: QueueSelection): Promise<CloudQueueSnapshot>
    clearCompleted(): Promise<CloudQueueSnapshot>
    onEvent(listener: (event: CloudQueueEvent) => void): Unsubscribe
  }
  library: {
    getStatus(): Promise<LibraryStatus>
    query(request: LibraryQueryRequest): Promise<LibraryPage>
    getDetails(request: LibraryDetailsRequest): Promise<LibraryDetails>
    refresh(): Promise<LibraryRefreshResult>
    onChanged(listener: (event: LibraryChangedEvent) => void): Unsubscribe
  }
  settings: {
    get(): Promise<PublicSettings>
    update(request: SettingsUpdate): Promise<PublicSettings>
    onChange(listener: (settings: PublicSettings) => void): Unsubscribe
  }
  diagnostics: {
    getSnapshot(): Promise<DiagnosticsSnapshot>
    export(request: DiagnosticExportRequest): Promise<DiagnosticExportResult>
    revealLogs(): Promise<EmptyResult>
  }
  updates: {
    getStatus(): Promise<UpdateStatus>
    check(): Promise<UpdateStatus>
    download(): Promise<UpdateStatus>
    install(request: UpdateInstallRequest): Promise<UpdateInstallResult>
    onStatusChange(listener: (status: UpdateStatus) => void): Unsubscribe
  }
  about: {
    getInfo(): Promise<AboutInfo>
  }
}
