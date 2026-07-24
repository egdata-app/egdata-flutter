import { createHash } from 'node:crypto'

import { normalizeInstallPath } from './paths'
import type {
  LocalManifestGroup,
  LocalManifestItem,
  LocalManifestPlatform,
  LocalManifestSource,
} from './types'

function normalized(value: string): string {
  return value.trim().toLowerCase()
}

export function localManifestGroupKey(
  source: LocalManifestSource,
  platform: LocalManifestPlatform,
): string {
  const item = source.parsed
  const mainNamespace = normalized(item.mainGameCatalogNamespace)
  const mainCatalogId = normalized(item.mainGameCatalogItemId)
  const mainAppName = normalized(item.mainGameAppName)
  if (mainNamespace && mainCatalogId && mainAppName) {
    return `main:${mainNamespace}:${mainCatalogId}:${mainAppName}`
  }

  const namespace = normalized(item.catalogNamespace)
  const catalogId = normalized(item.catalogItemId)
  const appName = normalized(item.appName)
  if (namespace && catalogId && appName) {
    return `main:${namespace}:${catalogId}:${appName}`
  }

  if (namespace && catalogId) {
    return `catalog:${namespace}:${catalogId}`
  }

  const installPath = normalizeInstallPath(platform, item.installLocation)
  if (installPath) return `path:${installPath}`

  return `guid:${normalized(item.installationGuid) || source.itemId}`
}

function isMainGame(source: LocalManifestSource): boolean {
  const item = source.parsed
  const catalogMatches =
    item.mainGameCatalogItemId.trim() !== '' &&
    normalized(item.catalogItemId) === normalized(item.mainGameCatalogItemId)
  const appMatches =
    item.mainGameAppName.trim() !== '' &&
    normalized(item.appName) === normalized(item.mainGameAppName)
  return catalogMatches || appMatches
}

function isBaseGame(source: LocalManifestSource): boolean {
  return (
    isMainGame(source) ||
    source.parsed.appCategories.some((category) => normalized(category) === 'games')
  )
}

function isAddon(source: LocalManifestSource): boolean {
  return !isBaseGame(source)
}

function compareRepresentatives(left: LocalManifestSource, right: LocalManifestSource): number {
  const priorities: Array<[boolean, boolean]> = [
    [isMainGame(left), isMainGame(right)],
    [left.parsed.launchExecutable.trim() !== '', right.parsed.launchExecutable.trim() !== ''],
    [!isAddon(left), !isAddon(right)],
  ]

  for (const [leftValue, rightValue] of priorities) {
    if (leftValue !== rightValue) return leftValue ? -1 : 1
  }

  if (left.parsed.installSize !== right.parsed.installSize) {
    return right.parsed.installSize - left.parsed.installSize
  }

  const titleOrder = left.parsed.displayName.localeCompare(right.parsed.displayName, undefined, {
    sensitivity: 'base',
  })
  return titleOrder || left.itemId.localeCompare(right.itemId)
}

export function groupLocalManifests(
  sources: LocalManifestSource[],
  platform: LocalManifestPlatform,
): LocalManifestGroup[] {
  const baseGamesByNamespace = new Map<string, LocalManifestSource[]>()
  for (const source of sources) {
    if (!isBaseGame(source)) continue
    const namespace = normalized(source.parsed.catalogNamespace)
    if (!namespace) continue
    const baseGames = baseGamesByNamespace.get(namespace) ?? []
    baseGames.push(source)
    baseGamesByNamespace.set(namespace, baseGames)
  }

  const buckets = new Map<string, LocalManifestSource[]>()
  for (const source of sources) {
    const namespace = normalized(source.parsed.catalogNamespace)
    const baseGames = isAddon(source) ? baseGamesByNamespace.get(namespace) : undefined
    const key =
      baseGames?.length === 1
        ? localManifestGroupKey(baseGames[0]!, platform)
        : localManifestGroupKey(source, platform)
    const bucket = buckets.get(key)
    if (bucket) bucket.push(source)
    else buckets.set(key, [source])
  }

  return [...buckets.entries()]
    .map(([key, bucket]) => {
      const sorted = [...bucket].sort(compareRepresentatives)
      return {
        groupId: createHash('sha256').update(key).digest('hex').slice(0, 20),
        representativeItemId: sorted[0]!.itemId,
        sourceItemIds: bucket.map((source) => source.itemId),
      }
    })
    .sort((left, right) => {
      const leftItem = sources.find((source) => source.itemId === left.representativeItemId)
      const rightItem = sources.find((source) => source.itemId === right.representativeItemId)
      return (leftItem?.parsed.displayName ?? '').localeCompare(
        rightItem?.parsed.displayName ?? '',
        undefined,
        { sensitivity: 'base' },
      )
    })
}

export function toPublicManifestItem(source: LocalManifestSource): LocalManifestItem {
  const item = source.parsed
  return {
    itemId: source.itemId,
    sourceName: source.sourceName,
    displayName: item.displayName || item.appName || 'Unnamed Epic item',
    appName: item.appName,
    catalogNamespace: item.catalogNamespace,
    catalogItemId: item.catalogItemId,
    installationGuid: item.installationGuid,
    appVersion: item.appVersion,
    installSize: item.installSize,
    launchExecutablePresent: item.launchExecutable.trim() !== '',
    isAddon: isAddon(source),
    uploadable: Boolean(source.manifestPath),
    ...(source.manifestFileName ? { manifestFileName: source.manifestFileName } : {}),
    diagnosticCodes: [...source.diagnosticCodes],
  }
}
