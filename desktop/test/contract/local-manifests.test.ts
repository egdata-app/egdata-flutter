import { mkdtemp, mkdir, readFile, rm, writeFile } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import path from 'node:path'

import { afterEach, describe, expect, it } from 'vitest'

import {
  LocalManifestScanner,
  localManifestGroupKey,
  parseLocalItem,
  resolveDefaultManifestDirectory,
  toPublicManifestItem,
  type LocalManifestSource,
} from '../../src/main/manifests/index'

const fixtureDirectory = new URL('../fixtures/local/', import.meta.url)
const temporaryDirectories: string[] = []

async function temporaryDirectory(): Promise<string> {
  const directory = await mkdtemp(path.join(tmpdir(), 'egdata-local-'))
  temporaryDirectories.push(directory)
  return directory
}

afterEach(async () => {
  await Promise.all(
    temporaryDirectories
      .splice(0)
      .map((directory) => rm(directory, { recursive: true, force: true })),
  )
})

describe('local manifest paths and parsing', () => {
  it('resolves the Windows and macOS launcher defaults', () => {
    expect(resolveDefaultManifestDirectory('win32', {})).toBe(
      String.raw`C:\ProgramData\Epic\EpicGamesLauncher\Data\Manifests`,
    )
    expect(resolveDefaultManifestDirectory('darwin', { HOME: '/Users/tester' })).toBe(
      '/Users/tester/Library/Application Support/Epic/EpicGamesLauncher/Data/Manifests',
    )
  })

  it('parses only safe field types without reconstructing source JSON', async () => {
    const raw = await readFile(new URL('valid-windows.item', fixtureDirectory), 'utf8')
    const parsed = parseLocalItem(raw)
    expect(parsed.displayName).toBe('Fixture Base Game')
    expect(parsed.installSize).toBe(4096)

    const unsafe = parseLocalItem(
      JSON.stringify({ DisplayName: 12, InstallSize: '4096', AppCategories: ['games', 1] }),
    )
    expect(unsafe.displayName).toBe('')
    expect(unsafe.installSize).toBe(0)
    expect(unsafe.appCategories).toEqual(['games'])
  })

  it('applies the exact group-key fallback precedence', () => {
    const source = (parsed: Partial<LocalManifestSource['parsed']>): LocalManifestSource => ({
      itemId: 'opaque',
      sourceName: 'fixture.item',
      itemPath: '/private/fixture.item',
      rawItemText: '{}',
      diagnosticCodes: [],
      parsed: {
        displayName: '',
        installationGuid: 'guid',
        installLocation: '/Games/Fixture',
        manifestLocation: '',
        catalogNamespace: 'namespace',
        catalogItemId: 'catalog',
        appName: 'app',
        appVersion: '',
        launchExecutable: '',
        installSize: 0,
        mainGameCatalogNamespace: '',
        mainGameCatalogItemId: '',
        mainGameAppName: '',
        appCategories: [],
        ...parsed,
      },
    })

    expect(
      localManifestGroupKey(
        source({
          mainGameCatalogNamespace: 'MainNS',
          mainGameCatalogItemId: 'MainID',
          mainGameAppName: 'MainApp',
        }),
        'darwin',
      ),
    ).toBe('main:mainns:mainid:mainapp')
    expect(localManifestGroupKey(source({}), 'darwin')).toBe('main:namespace:catalog:app')
    expect(localManifestGroupKey(source({ appName: '' }), 'darwin')).toBe(
      'catalog:namespace:catalog',
    )
    expect(
      localManifestGroupKey(source({ catalogNamespace: '', catalogItemId: '' }), 'darwin'),
    ).toBe('path:/games/fixture')
    expect(
      localManifestGroupKey(
        source({ catalogNamespace: '', catalogItemId: '', installLocation: '' }),
        'darwin',
      ),
    ).toBe('guid:guid')
  })

  it('treats Epic digital extras as add-ons', () => {
    const item = toPublicManifestItem({
      itemId: 'redmod',
      sourceName: 'redmod.item',
      itemPath: '/private/redmod.item',
      rawItemText: '{}',
      diagnosticCodes: [],
      parsed: {
        displayName: 'Cyberpunk 2077 - REDmod',
        installationGuid: 'guid',
        installLocation: '/Games/Cyberpunk2077',
        manifestLocation: '',
        catalogNamespace: 'namespace',
        catalogItemId: 'redmod',
        appName: 'redmod',
        appVersion: '',
        launchExecutable: '',
        installSize: 0,
        mainGameCatalogNamespace: 'namespace',
        mainGameCatalogItemId: 'base',
        mainGameAppName: 'game',
        appCategories: ['digitalextras', 'applications'],
      },
    })

    expect(item.isAddon).toBe(true)
  })
})

describe('LocalManifestScanner', () => {
  it('reports a missing directory without exposing its path', async () => {
    const parent = await temporaryDirectory()
    const scanner = new LocalManifestScanner({
      platform: process.platform === 'win32' ? 'win32' : 'darwin',
      allowCustomDirectory: true,
    })
    const result = await scanner.scan({
      source: 'selected',
      manifestDirectory: path.join(parent, 'missing'),
    })

    expect(result.directoryAvailable).toBe(false)
    expect(result.errors[0]?.code).toBe('LOCAL_MANIFEST_DIRECTORY_MISSING')
    expect(JSON.stringify(result)).not.toContain(parent)
  })

  it('enumerates .item and .egstore files non-recursively and preserves source data', async () => {
    const manifests = await temporaryDirectory()
    const install = await temporaryDirectory()
    const egstore = path.join(install, '.egstore')
    await mkdir(egstore)
    await mkdir(path.join(manifests, 'nested'))
    await mkdir(path.join(egstore, 'nested'))

    const fixtureRaw = await readFile(new URL('valid-windows.item', fixtureDirectory), 'utf8')
    const raw = fixtureRaw
      .replace(/"ManifestLocation": "[^"]*"/, '"ManifestLocation": ""')
      .replace(/"InstallLocation": "[^"]*"/, `"InstallLocation": ${JSON.stringify(install)}`)
    const expectedBytes = await readFile(new URL('fixture.manifest', fixtureDirectory))
    await writeFile(path.join(manifests, 'fixture.item'), raw, 'utf8')
    await writeFile(path.join(manifests, 'nested', 'ignored.item'), raw, 'utf8')
    await writeFile(path.join(egstore, 'fixture.manifest'), expectedBytes)
    await writeFile(path.join(egstore, 'nested', 'ignored.manifest'), 'ignored')

    const platform = process.platform === 'win32' ? 'win32' : 'darwin'
    const scanner = new LocalManifestScanner({ platform, allowCustomDirectory: true })
    const result = await scanner.scan({ manifestDirectory: manifests })

    expect(result.items).toHaveLength(1)
    expect(result.items[0]?.uploadable).toBe(true)
    expect(JSON.stringify(result)).not.toContain(raw)
    expect(JSON.stringify(result)).not.toContain(install)

    const payload = await scanner.getUploadPayload(result.sessionId, result.items[0]!.itemId)
    expect(payload.rawItemText).toBe(raw)
    expect(Buffer.from(payload.manifestBytes)).toEqual(expectedBytes)
  })

  it('returns malformed and missing-binary errors while retaining parsed items', async () => {
    const manifests = await temporaryDirectory()
    await writeFile(
      path.join(manifests, 'broken.item'),
      await readFile(new URL('malformed.item', fixtureDirectory)),
    )
    await writeFile(
      path.join(manifests, 'missing.item'),
      JSON.stringify({ DisplayName: 'Missing binary', InstallationGuid: 'missing' }),
    )

    const scanner = new LocalManifestScanner({
      platform: process.platform === 'win32' ? 'win32' : 'darwin',
      allowCustomDirectory: true,
    })
    const result = await scanner.scan({ manifestDirectory: manifests })

    expect(result.errors.map((error) => error.code)).toEqual([
      'LOCAL_ITEM_INVALID_JSON',
      'LOCAL_BINARY_MANIFEST_MISSING',
    ])
    expect(result.items).toHaveLength(1)
    expect(result.items[0]?.uploadable).toBe(false)
  })

  it('groups every non-base manifest with the sole base game in its namespace', async () => {
    const manifests = await temporaryDirectory()
    const install = await temporaryDirectory()
    const egstore = path.join(install, '.egstore')
    await mkdir(egstore)
    await writeFile(path.join(egstore, 'fixture.manifest'), 'binary')

    for (const fixture of ['base-game.item', 'addon.item']) {
      const text = await readFile(new URL(fixture, fixtureDirectory), 'utf8')
      await writeFile(
        path.join(manifests, fixture),
        text.replace('__INSTALL_LOCATION__', install.replaceAll('\\', '\\\\')),
      )
    }
    const unlinkedExtra = JSON.parse(
      await readFile(new URL('addon.item', fixtureDirectory), 'utf8'),
    )
    unlinkedExtra.DisplayName = 'Fixture extra'
    unlinkedExtra.CatalogItemId = 'extra-id'
    unlinkedExtra.AppName = 'extra-app'
    unlinkedExtra.MainGameCatalogNamespace = ''
    unlinkedExtra.MainGameCatalogItemId = ''
    unlinkedExtra.MainGameAppName = ''
    unlinkedExtra.AppCategories = ['applications']
    await writeFile(
      path.join(manifests, 'extra.item'),
      JSON.stringify(unlinkedExtra).replace(
        '__INSTALL_LOCATION__',
        install.replaceAll('\\', '\\\\'),
      ),
    )

    const scanner = new LocalManifestScanner({
      platform: process.platform === 'win32' ? 'win32' : 'darwin',
      allowCustomDirectory: true,
    })
    const result = await scanner.scan({ manifestDirectory: manifests })

    expect(result.groups).toHaveLength(1)
    expect(result.groups[0]?.sourceItemIds).toHaveLength(3)
    expect(result.groups[0]?.representativeItemId).toBe(
      result.items.find((item) => item.displayName === 'Fixture Game')?.itemId,
    )
    expect(new Set(result.groups[0]?.sourceItemIds)).toEqual(
      new Set(result.items.map((item) => item.itemId)),
    )
    expect(result.items.find((item) => item.displayName === 'Fixture extra')?.isAddon).toBe(true)
  })
})
