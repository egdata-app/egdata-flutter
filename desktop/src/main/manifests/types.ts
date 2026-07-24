export type LocalManifestPlatform = 'win32' | 'darwin'

export type LocalManifestErrorCode =
  | 'LOCAL_MANIFEST_DIRECTORY_MISSING'
  | 'LOCAL_ITEM_PERMISSION_DENIED'
  | 'LOCAL_ITEM_INVALID_JSON'
  | 'LOCAL_BINARY_MANIFEST_MISSING'

export interface LocalManifestDiagnostic {
  code: LocalManifestErrorCode
  message: string
  sourceName?: string
  itemId?: string
}

export interface LocalManifestItem {
  itemId: string
  sourceName: string
  displayName: string
  appName: string
  catalogNamespace: string
  catalogItemId: string
  installationGuid: string
  appVersion: string
  installSize: number
  launchExecutablePresent: boolean
  isAddon: boolean
  uploadable: boolean
  manifestFileName?: string
  diagnosticCodes: LocalManifestErrorCode[]
}

export interface LocalManifestGroup {
  groupId: string
  representativeItemId: string
  sourceItemIds: string[]
}

export interface LocalManifestScanResult {
  sessionId: string
  directoryAvailable: boolean
  items: LocalManifestItem[]
  groups: LocalManifestGroup[]
  errors: LocalManifestDiagnostic[]
}

export interface ParsedLocalManifest {
  displayName: string
  installationGuid: string
  installLocation: string
  manifestLocation: string
  catalogNamespace: string
  catalogItemId: string
  appName: string
  appVersion: string
  launchExecutable: string
  installSize: number
  mainGameCatalogNamespace: string
  mainGameCatalogItemId: string
  mainGameAppName: string
  appCategories: string[]
}

/** Main-process-only data. Do not return this shape from an IPC handler. */
export interface LocalManifestSource {
  itemId: string
  sourceName: string
  rawItemText: string
  itemPath: string
  manifestPath?: string
  manifestFileName?: string
  parsed: ParsedLocalManifest
  diagnosticCodes: LocalManifestErrorCode[]
}

/** Main-process-only upload payload. */
export interface LocalManifestUploadPayload {
  itemId: string
  rawItemText: string
  manifestBytes: Uint8Array
  manifestFileName?: string
  installationGuid: string
}
