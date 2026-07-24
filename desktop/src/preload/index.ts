import { contextBridge, ipcRenderer } from 'electron'
import type { IpcRendererEvent } from 'electron'
import type { z } from 'zod'

import type { DesktopApi } from '../shared/api'
import {
  AboutInfoSchema,
  AuthStatusSchema,
  CloudQueueEventSchema,
  CloudQueueSnapshotSchema,
  CloudQueueStartSchema,
  DiagnosticExportRequestSchema,
  DiagnosticExportResultSchema,
  DiagnosticsSnapshotSchema,
  DirectorySelectionSchema,
  EmptyResultSchema,
  LocalScanEventSchema,
  LocalScanRequestSchema,
  LocalScanSnapshotSchema,
  LocalUploadRequestSchema,
  LocalUploadSnapshotSchema,
  LibrarySelectionSchema,
  LibraryChangedEventSchema,
  LibraryDetailsRequestSchema,
  LibraryDetailsSchema,
  LibraryPageSchema,
  LibraryQueryRequestSchema,
  LibraryRefreshResultSchema,
  LibraryStatusSchema,
  LauncherStatusSchema,
  LibraryToolsEventSchema,
  LibraryToolsSnapshotSchema,
  GameSelectionSchema,
  MovePreparationSchema,
  OperationIdSchema,
  PublicSettingsSchema,
  QueueSelectionSchema,
  SettingsUpdateSchema,
  UpdateInstallRequestSchema,
  UpdateInstallResultSchema,
  UpdateStatusSchema,
} from '../shared/contracts'
import { IPC_CHANNELS } from '../shared/ipc'

type Schema<T> = z.ZodType<T>

async function invoke<T>(channel: string, output: Schema<T>): Promise<T>
async function invoke<I, T>(
  channel: string,
  output: Schema<T>,
  input: Schema<I>,
  value: I,
): Promise<T>
async function invoke<I, T>(
  channel: string,
  output: Schema<T>,
  input?: Schema<I>,
  value?: I,
): Promise<T> {
  const response: unknown = input
    ? await ipcRenderer.invoke(channel, input.parse(value))
    : await ipcRenderer.invoke(channel)
  return output.parse(response)
}

function subscribe<T>(
  channel: string,
  schema: Schema<T>,
  listener: (value: T) => void,
): () => void {
  const handler = (_event: IpcRendererEvent, value: unknown): void => {
    const parsed = schema.safeParse(value)
    if (parsed.success) listener(parsed.data)
  }

  ipcRenderer.on(channel, handler)
  return () => ipcRenderer.removeListener(channel, handler)
}

const desktopApi: DesktopApi = {
  localManifests: {
    selectDirectory: () => invoke(IPC_CHANNELS.local.selectDirectory, DirectorySelectionSchema),
    scan: (request) =>
      invoke(IPC_CHANNELS.local.scan, LocalScanSnapshotSchema, LocalScanRequestSchema, request),
    getScanSnapshot: () => invoke(IPC_CHANNELS.local.getScanSnapshot, LocalScanSnapshotSchema),
    onScanEvent: (listener) =>
      subscribe(IPC_CHANNELS.local.scanEvent, LocalScanEventSchema, listener),
    upload: (request) =>
      invoke(
        IPC_CHANNELS.local.upload,
        LocalUploadSnapshotSchema,
        LocalUploadRequestSchema,
        request,
      ),
    cancelUpload: (request) =>
      invoke(IPC_CHANNELS.local.cancelUpload, EmptyResultSchema, OperationIdSchema, request),
    onUploadEvent: (listener) =>
      subscribe(IPC_CHANNELS.local.uploadEvent, LocalUploadSnapshotSchema, listener),
  },
  libraryTools: {
    getSnapshot: () => invoke(IPC_CHANNELS.libraryTools.getSnapshot, LibraryToolsSnapshotSchema),
    getLauncherStatus: () =>
      invoke(IPC_CHANNELS.libraryTools.getLauncherStatus, LauncherStatusSchema),
    tryCloseLauncher: () =>
      invoke(IPC_CHANNELS.libraryTools.tryCloseLauncher, LauncherStatusSchema),
    scan: () => invoke(IPC_CHANNELS.libraryTools.scan, LibraryToolsSnapshotSchema),
    cancelScan: () => invoke(IPC_CHANNELS.libraryTools.cancelScan, LibraryToolsSnapshotSchema),
    recover: (request) =>
      invoke(
        IPC_CHANNELS.libraryTools.recover,
        LibraryToolsSnapshotSchema,
        LibrarySelectionSchema,
        request,
      ),
    prepareMove: (request) =>
      invoke(
        IPC_CHANNELS.libraryTools.prepareMove,
        MovePreparationSchema,
        GameSelectionSchema,
        request,
      ),
    startMove: (request) =>
      invoke(
        IPC_CHANNELS.libraryTools.startMove,
        LibraryToolsSnapshotSchema,
        OperationIdSchema,
        request,
      ),
    cancelMove: (request) =>
      invoke(
        IPC_CHANNELS.libraryTools.cancelMove,
        LibraryToolsSnapshotSchema,
        OperationIdSchema,
        request,
      ),
    onEvent: (listener) =>
      subscribe(IPC_CHANNELS.libraryTools.event, LibraryToolsEventSchema, listener),
  },
  epicAuth: {
    getStatus: () => invoke(IPC_CHANNELS.auth.getStatus, AuthStatusSchema),
    login: () => invoke(IPC_CHANNELS.auth.login, AuthStatusSchema),
    logout: () => invoke(IPC_CHANNELS.auth.logout, AuthStatusSchema),
    onStatusChange: (listener) =>
      subscribe(IPC_CHANNELS.auth.statusEvent, AuthStatusSchema, listener),
  },
  cloudQueue: {
    getSnapshot: () => invoke(IPC_CHANNELS.cloud.getSnapshot, CloudQueueSnapshotSchema),
    refresh: () => invoke(IPC_CHANNELS.cloud.refresh, CloudQueueSnapshotSchema),
    start: (request) =>
      invoke(IPC_CHANNELS.cloud.start, CloudQueueSnapshotSchema, CloudQueueStartSchema, request),
    pause: () => invoke(IPC_CHANNELS.cloud.pause, CloudQueueSnapshotSchema),
    resume: () => invoke(IPC_CHANNELS.cloud.resume, CloudQueueSnapshotSchema),
    cancel: () => invoke(IPC_CHANNELS.cloud.cancel, CloudQueueSnapshotSchema),
    retry: (request) =>
      invoke(IPC_CHANNELS.cloud.retry, CloudQueueSnapshotSchema, QueueSelectionSchema, request),
    remove: (request) =>
      invoke(IPC_CHANNELS.cloud.remove, CloudQueueSnapshotSchema, QueueSelectionSchema, request),
    clearCompleted: () => invoke(IPC_CHANNELS.cloud.clearCompleted, CloudQueueSnapshotSchema),
    onEvent: (listener) => subscribe(IPC_CHANNELS.cloud.event, CloudQueueEventSchema, listener),
  },
  library: {
    getStatus: () => invoke(IPC_CHANNELS.library.getStatus, LibraryStatusSchema),
    query: (request) =>
      invoke(IPC_CHANNELS.library.query, LibraryPageSchema, LibraryQueryRequestSchema, request),
    getDetails: (request) =>
      invoke(
        IPC_CHANNELS.library.getDetails,
        LibraryDetailsSchema,
        LibraryDetailsRequestSchema,
        request,
      ),
    refresh: () => invoke(IPC_CHANNELS.library.refresh, LibraryRefreshResultSchema),
    onChanged: (listener) =>
      subscribe(IPC_CHANNELS.library.changedEvent, LibraryChangedEventSchema, listener),
  },
  settings: {
    get: () => invoke(IPC_CHANNELS.settings.get, PublicSettingsSchema),
    update: (request) =>
      invoke(IPC_CHANNELS.settings.update, PublicSettingsSchema, SettingsUpdateSchema, request),
    onChange: (listener) =>
      subscribe(IPC_CHANNELS.settings.changedEvent, PublicSettingsSchema, listener),
  },
  diagnostics: {
    getSnapshot: () => invoke(IPC_CHANNELS.diagnostics.getSnapshot, DiagnosticsSnapshotSchema),
    export: (request) =>
      invoke(
        IPC_CHANNELS.diagnostics.export,
        DiagnosticExportResultSchema,
        DiagnosticExportRequestSchema,
        request,
      ),
    revealLogs: () => invoke(IPC_CHANNELS.diagnostics.revealLogs, EmptyResultSchema),
  },
  updates: {
    getStatus: () => invoke(IPC_CHANNELS.updates.getStatus, UpdateStatusSchema),
    check: () => invoke(IPC_CHANNELS.updates.check, UpdateStatusSchema),
    download: () => invoke(IPC_CHANNELS.updates.download, UpdateStatusSchema),
    install: (request) =>
      invoke(
        IPC_CHANNELS.updates.install,
        UpdateInstallResultSchema,
        UpdateInstallRequestSchema,
        request,
      ),
    onStatusChange: (listener) =>
      subscribe(IPC_CHANNELS.updates.statusEvent, UpdateStatusSchema, listener),
  },
  about: {
    getInfo: () => invoke(IPC_CHANNELS.about.getInfo, AboutInfoSchema),
  },
}

contextBridge.exposeInMainWorld('desktopApi', Object.freeze(desktopApi))
