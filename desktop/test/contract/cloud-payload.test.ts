import { describe, expect, it } from 'vitest'

import {
  buildLauncherAssetUrl,
  createCloudUploadPayload,
  manifestFilenameForAsset,
  type EpicLibraryItem,
} from '../../src/main/cloud'

const item: EpicLibraryItem = {
  appName: 'App Name/Live',
  title: 'Friendly Game',
  catalogItemId: 'catalog/id',
  namespace: 'namespace value',
  assetId: 'asset:id/one',
  buildVersion: null,
}

describe('cloud contribution contract', () => {
  it('encodes every launcher asset path segment', () => {
    const url = buildLauncherAssetUrl(item, 'Windows')

    expect(url.origin).toBe('https://launcher-public-service-prod06.ol.epicgames.com')
    expect(url.pathname).toContain('/platform/Windows/')
    expect(url.pathname).toContain('/namespace/namespace%20value/')
    expect(url.pathname).toContain('/catalogItem/catalog%2Fid/')
    expect(url.pathname).toContain('/app/App%20Name%2FLive/')
    expect(url.pathname.endsWith('/label/Live')).toBe(true)
  })

  it('builds the backend-compatible Windows synthetic item', () => {
    const manifest = new Uint8Array([1, 2, 3])
    const payload = createCloudUploadPayload(item, manifest, 'Windows')

    expect(payload).toMatchObject({
      os: 'Windows',
      manifest,
      manifestFilename: 'asset_id_one.manifest',
      item: {
        InstallLocation: 'C:\\Program Files\\Epic Games\\App Name_Live',
        AppName: 'App Name/Live',
        CatalogItemId: 'catalog/id',
        CatalogNamespace: 'namespace value',
        InstallationGuid: 'asset:id/one',
        DisplayName: 'Friendly Game',
        BuildLabel: 'Live',
        AppVersionString: '1.0.0',
        MainGameCatalogNamespace: 'namespace value',
        MainGameCatalogItemId: 'catalog/id',
        MainGameAppName: 'App Name/Live',
        AppCategories: ['games'],
      },
    })
    expect(JSON.parse(payload.itemJson)).toEqual(payload.item)
  })

  it('uses a platform-compatible macOS placeholder and deterministic filename', () => {
    const payload = createCloudUploadPayload(
      { ...item, buildVersion: '9.1' },
      new Uint8Array([7]),
      'Mac',
    )
    expect(payload.item.InstallLocation).toBe('/Applications/App Name_Live.app')
    expect(payload.item.AppVersionString).toBe('9.1')
    expect(manifestFilenameForAsset(item.assetId)).toBe('asset_id_one.manifest')
  })
})
