import type { CloudSyntheticItem, CloudUploadPayload, EpicLibraryItem, EpicPlatform } from './types'

function safePathName(value: string): string {
  const cleaned = Array.from(value.trim().replace(/[<>:"/\\|?*]/g, '_'), (character) =>
    character.charCodeAt(0) < 32 ? '_' : character,
  ).join('')
  return cleaned || 'EpicGame'
}

export function createCloudSyntheticItem(
  item: EpicLibraryItem,
  platform: EpicPlatform,
): CloudSyntheticItem {
  const name = safePathName(item.appName)
  const installLocation =
    platform === 'Windows' ? `C:\\Program Files\\Epic Games\\${name}` : `/Applications/${name}.app`
  return {
    InstallLocation: installLocation,
    AppName: item.appName,
    CatalogItemId: item.catalogItemId,
    CatalogNamespace: item.namespace,
    InstallationGuid: item.assetId,
    DisplayName: item.title,
    AppVersionString: item.buildVersion?.trim() || '1.0.0',
    MainGameCatalogNamespace: item.namespace,
    MainGameCatalogItemId: item.catalogItemId,
    MainGameAppName: item.appName,
    AppCategories: ['games'],
  }
}

export function manifestFilenameForAsset(assetId: string): string {
  const safeAssetId = assetId.trim().replace(/[^A-Za-z0-9._-]/g, '_')
  return `${safeAssetId || 'unknown-asset'}.manifest`
}

export function createCloudUploadPayload(
  item: EpicLibraryItem,
  manifest: Uint8Array,
  platform: EpicPlatform,
): CloudUploadPayload {
  const syntheticItem = createCloudSyntheticItem(item, platform)
  return {
    item: syntheticItem,
    itemJson: JSON.stringify(syntheticItem),
    os: platform,
    manifest,
    manifestFilename: manifestFilenameForAsset(item.assetId),
  }
}
