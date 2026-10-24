import { mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import path from 'node:path'

import { afterEach, describe, expect, it } from 'vitest'

import { LocalManifestScanner } from '../../src/main/manifests/scanner'
import { buildLocalManifestMultipart } from '../../src/main/uploads/multipart'

const directories: string[] = []
const baseId = '0123456789ABCDEF0123456789ABCDEF'
const addonId = 'ABCDEF0123456789ABCDEF0123456789'

afterEach(async () => {
  await Promise.all(
    directories.splice(0).map((directory) => rm(directory, { recursive: true, force: true })),
  )
})

async function createFixture(): Promise<{
  root: string
  legacy: string
  launcher: string
  install: string
  scanner: LocalManifestScanner
}> {
  const root = await mkdtemp(path.join(tmpdir(), 'egdata-launcher-v2-'))
  directories.push(root)
  const environment = {
    ProgramData: path.join(root, 'ProgramData'),
    LOCALAPPDATA: path.join(root, 'Local'),
  }
  const legacy = path.join(
    environment.ProgramData,
    'Epic',
    'EpicGamesLauncher',
    'Data',
    'Manifests',
  )
  const launcher = path.join(environment.LOCALAPPDATA, 'com.epicgames.eglv2')
  const install = path.join(root, 'Games', 'Fixture')
  await mkdir(launcher, { recursive: true })
  await mkdir(path.join(install, '.egstore'), { recursive: true })
  return {
    root,
    legacy,
    launcher,
    install,
    scanner: new LocalManifestScanner({
      platform: 'win32',
      environment,
      allowCustomDirectory: true,
    }),
  }
}

function createInstallation(
  dir: string,
  overrides: Record<string, unknown> = {},
): Record<string, unknown> {
  return {
    installationId: baseId,
    complete: true,
    dir,
    platform: 'Windows',
    namespace: 'fixture-namespace',
    itemId: 'base-item',
    artifactId: 'FixtureGame',
    version: '1.0',
    tags: [''],
    launchExecutable: 'Game.exe',
    launchCommand: '-test',
    writtenAt: '2026-10-01T15:22:15Z',
    ...overrides,
  }
}

async function writeIndex(launcher: string, records: unknown[]): Promise<void> {
  await writeFile(
    path.join(launcher, 'installations.jsonl'),
    '\uFEFF' +
      [
        JSON.stringify({ version: 1, writtenAt: '2026-10-01T15:22:15Z' }),
        ...records.map((record) => (typeof record === 'string' ? record : JSON.stringify(record))),
      ].join('\r\n') +
      '\r\n',
  )
}

async function writeManifest(
  install: string,
  id = baseId,
  bytes = Buffer.from([0x0c, 0xc0, 0xbe, 0x44, 0, 255]),
): Promise<Buffer> {
  await writeFile(path.join(install, '.egstore', `${id}.manifest`), bytes)
  return bytes
}

async function writeLegacy(
  legacy: string,
  install: string,
  overrides: Record<string, unknown> = {},
): Promise<string> {
  await mkdir(legacy, { recursive: true })
  const raw =
    '\uFEFF{\n  "DisplayName": "Original fixture name",\n' +
    Object.entries({
      InstallationGuid: baseId,
      InstallLocation: install,
      ManifestLocation: path.join(install, '.egstore'),
      AppName: 'FixtureGame',
      CatalogNamespace: 'fixture-namespace',
      CatalogItemId: 'base-item',
      AppVersionString: '1.0',
      AppCategories: ['games'],
      ...overrides,
    })
      .map(([key, value]) => `  ${JSON.stringify(key)}: ${JSON.stringify(value)}`)
      .join(',\n') +
    '\n}\n'
  await writeFile(path.join(legacy, 'original.item'), raw)
  return raw
}

describe.skipIf(process.platform !== 'win32')('coexisting Epic launcher manifest discovery', () => {
  it('discovers a new-only installation and uploads unchanged binary bytes through the existing multipart contract', async () => {
    const { root, legacy, launcher, install, scanner } = await createFixture()
    await writeIndex(launcher, [createInstallation(install)])
    const bytes = await writeManifest(install)
    const result = await scanner.scan()
    expect(result.directoryAvailable).toBe(true)
    expect(result.errors).toEqual([])
    expect(result.items).toHaveLength(1)
    expect(result.items[0]).toMatchObject({
      appName: 'FixtureGame',
      catalogItemId: 'base-item',
      uploadable: true,
      isAddon: false,
    })
    expect(JSON.stringify(result)).not.toContain(root)
    await expect(readFile(legacy)).rejects.toMatchObject({ code: 'ENOENT' })
    const payload = await scanner.getUploadPayload(result.sessionId, result.items[0]!.itemId)
    expect(Buffer.from(payload.manifestBytes)).toEqual(bytes)
    expect(JSON.parse(payload.rawItemText)).toMatchObject({
      InstallationGuid: baseId,
      CatalogNamespace: 'fixture-namespace',
      CatalogItemId: 'base-item',
      AppVersionString: '1.0',
      LaunchExecutable: 'Game.exe',
    })
    const multipart = buildLocalManifestMultipart(payload, 'win32', 'fixture-boundary')
    expect(multipart.body.includes(bytes)).toBe(true)
    expect(multipart.filename).toBe(`${baseId}.manifest`)
  })

  it('keeps old-only discovery working when the new index is absent', async () => {
    const { legacy, install, scanner } = await createFixture()
    const raw = await writeLegacy(legacy, install)
    await writeManifest(install)
    const result = await scanner.scan()
    expect(result.errors).toEqual([])
    expect(result.items).toHaveLength(1)
    expect(
      (await scanner.getUploadPayload(result.sessionId, result.items[0]!.itemId)).rawItemText,
    ).toBe(raw)
  })

  it('combines both launchers while deduplicating a shared installation and preserving original legacy JSON', async () => {
    const { legacy, launcher, install, scanner } = await createFixture()
    const raw = await writeLegacy(legacy, install)
    await writeIndex(launcher, [
      createInstallation(install),
      createInstallation(install, {
        installationId: addonId,
        parentInstallationId: baseId,
        itemId: 'addon-item',
        artifactId: 'FixtureAddon',
        launchExecutable: '',
      }),
    ])
    const baseBytes = await writeManifest(install)
    const addonBytes = await writeManifest(install, addonId, Buffer.from('addon-binary'))
    const result = await scanner.scan()
    expect(result.errors).toEqual([])
    expect(result.items).toHaveLength(2)
    expect(result.groups).toHaveLength(1)
    expect(result.groups[0]?.sourceItemIds).toHaveLength(2)
    const base = result.items.find((item) => item.installationGuid === baseId)!
    const addon = result.items.find((item) => item.installationGuid === addonId)!
    expect(addon.isAddon).toBe(true)
    const basePayload = await scanner.getUploadPayload(result.sessionId, base.itemId)
    expect(basePayload.rawItemText).toBe(raw)
    expect(Buffer.from(basePayload.manifestBytes)).toEqual(baseBytes)
    expect(
      Buffer.from((await scanner.getUploadPayload(result.sessionId, addon.itemId)).manifestBytes),
    ).toEqual(addonBytes)
  })

  it('keeps different builds of a shared installation as separate sources', async () => {
    const { legacy, launcher, install, scanner } = await createFixture()
    await writeLegacy(legacy, install)
    await writeIndex(launcher, [createInstallation(install, { version: '2.0' })])
    await writeManifest(install)
    expect((await scanner.scan()).items.map((item) => item.appVersion)).toEqual(['1.0', '2.0'])
  })

  it('does not substitute a sibling manifest when an add-on manifest is missing', async () => {
    const { launcher, install, scanner } = await createFixture()
    await writeIndex(launcher, [
      createInstallation(install),
      createInstallation(install, {
        installationId: addonId,
        parentInstallationId: baseId,
        artifactId: 'Addon',
        itemId: 'addon',
      }),
    ])
    await writeManifest(install)
    const result = await scanner.scan()
    const addon = result.items.find((item) => item.installationGuid === addonId)!
    expect(addon.uploadable).toBe(false)
    expect(result.errors.map((error) => error.code)).toEqual(['LOCAL_BINARY_MANIFEST_MISSING'])
    await expect(scanner.getUploadPayload(result.sessionId, addon.itemId)).rejects.toMatchObject({
      code: 'LOCAL_BINARY_MANIFEST_MISSING',
    })
  })

  it('skips incomplete and foreign-platform installations and uses the latest record for repeated IDs', async () => {
    const { launcher, install, scanner } = await createFixture()
    await writeIndex(launcher, [
      createInstallation(install),
      createInstallation(install, { version: '2.0' }),
      createInstallation(install, { installationId: addonId, complete: false }),
      createInstallation(install, { installationId: 'foreign', platform: 'Mac' }),
    ])
    await writeManifest(install)
    const result = await scanner.scan()
    expect(result.errors).toEqual([])
    expect(result.items).toHaveLength(1)
    expect(result.items[0]?.appVersion).toBe('2.0')
  })

  it('isolates malformed and unsafe records while retaining valid records and sanitizing diagnostics', async () => {
    const { root, launcher, install, scanner } = await createFixture()
    await writeIndex(launcher, [
      '{"broken":',
      createInstallation(install, { installationId: '..\\escape' }),
      createInstallation('relative-directory'),
      createInstallation(install),
    ])
    await writeManifest(install)
    const result = await scanner.scan()
    expect(result.items).toHaveLength(1)
    expect(result.errors.map((error) => error.code)).toEqual(
      Array(3).fill('LOCAL_ITEM_INVALID_JSON'),
    )
    expect(JSON.stringify(result)).not.toContain(root)
    expect(JSON.stringify(result)).not.toContain('escape')
  })

  it('retains legacy results when the new index has an unsupported format', async () => {
    const { legacy, launcher, install, scanner } = await createFixture()
    await writeLegacy(legacy, install)
    await writeManifest(install)
    await writeFile(path.join(launcher, 'installations.jsonl'), '{"version":2}\n')
    const result = await scanner.scan()
    expect(result.directoryAvailable).toBe(true)
    expect(result.items).toHaveLength(1)
    expect(result.errors[0]?.code).toBe('LOCAL_ITEM_INVALID_JSON')
  })

  it('supports selecting the new launcher directory without including automatic sources', async () => {
    const { launcher, legacy, install, scanner } = await createFixture()
    await writeLegacy(legacy, install, { InstallationGuid: 'other' })
    await writeIndex(launcher, [createInstallation(install)])
    await writeManifest(install)
    const result = await scanner.scan({ source: 'selected', manifestDirectory: launcher })
    expect(result.items).toHaveLength(1)
    expect(result.items[0]?.installationGuid).toBe(baseId)
  })

  it('reports missing sources only when neither launcher index is available', async () => {
    const { scanner } = await createFixture()
    const result = await scanner.scan()
    expect(result.directoryAvailable).toBe(false)
    expect(result.errors.map((error) => error.code)).toEqual(['LOCAL_MANIFEST_DIRECTORY_MISSING'])
  })

  it('rescans index changes and reports manifests deleted after discovery', async () => {
    const { launcher, install, scanner } = await createFixture()
    await writeIndex(launcher, [createInstallation(install)])
    await writeManifest(install)
    const first = await scanner.scan()
    await rm(path.join(install, '.egstore', `${baseId}.manifest`))
    await expect(
      scanner.getUploadPayload(first.sessionId, first.items[0]!.itemId),
    ).rejects.toMatchObject({ code: 'LOCAL_BINARY_MANIFEST_MISSING' })
    await writeIndex(launcher, [])
    expect((await scanner.scan()).items).toEqual([])
  })
})
