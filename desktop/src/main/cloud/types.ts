export type EpicPlatform = 'Windows' | 'Mac'

export interface EpicLibraryItem {
  appName: string
  title: string
  catalogItemId: string
  namespace: string
  assetId: string
  buildVersion: string | null
}

export interface CloudManifest {
  bytes: Uint8Array
  buildVersion: string | null
}

export interface CloudSyntheticItem {
  InstallLocation: string
  AppName: string
  CatalogItemId: string
  CatalogNamespace: string
  InstallationGuid: string
  DisplayName: string
  BuildLabel: string
  AppVersionString: string
  MainGameCatalogNamespace: string
  MainGameCatalogItemId: string
  MainGameAppName: string
  AppCategories: ['games']
}

export interface CloudUploadPayload {
  item: CloudSyntheticItem
  itemJson: string
  os: EpicPlatform
  manifest: Uint8Array
  manifestFilename: string
}
