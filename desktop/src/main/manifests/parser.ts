import type { ParsedLocalManifest } from './types'

function stringField(value: unknown): string {
  return typeof value === 'string' ? value : ''
}

function sizeField(value: unknown): number {
  return typeof value === 'number' && Number.isFinite(value) && value >= 0 ? value : 0
}

export function parseLocalItem(rawText: string): ParsedLocalManifest {
  const jsonText = rawText.charCodeAt(0) === 0xfeff ? rawText.slice(1) : rawText
  const decoded: unknown = JSON.parse(jsonText)
  if (!decoded || typeof decoded !== 'object' || Array.isArray(decoded)) {
    throw new SyntaxError('The item JSON root must be an object')
  }

  const value = decoded as Record<string, unknown>
  const categories = Array.isArray(value.AppCategories)
    ? value.AppCategories.filter((category): category is string => typeof category === 'string')
    : []

  return {
    displayName: stringField(value.DisplayName),
    installationGuid: stringField(value.InstallationGuid),
    installLocation: stringField(value.InstallLocation),
    manifestLocation: stringField(value.ManifestLocation),
    catalogNamespace: stringField(value.CatalogNamespace),
    catalogItemId: stringField(value.CatalogItemId),
    appName: stringField(value.AppName),
    appVersion: stringField(value.AppVersionString),
    launchExecutable: stringField(value.LaunchExecutable),
    installSize: sizeField(value.InstallSize),
    mainGameCatalogNamespace: stringField(value.MainGameCatalogNamespace),
    mainGameCatalogItemId: stringField(value.MainGameCatalogItemId),
    mainGameAppName: stringField(value.MainGameAppName),
    appCategories: categories,
  }
}
