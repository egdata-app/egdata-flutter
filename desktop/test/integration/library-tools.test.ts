import { mkdtemp, mkdir, readFile, rm, stat, writeFile } from 'node:fs/promises'
import os from 'node:os'
import path from 'node:path'

import type { Manifest } from '@egdata/manifests-parser'
import { afterEach, describe, expect, test, vi } from 'vitest'

import {
  discoveryScopesForRoot,
  driveRootsFromResponse,
  LibraryToolsService,
  moveDestinationForParent,
} from '../../src/main/library-tools'

const GUID = '0123456789ABCDEF0123456789ABCDEF'
const temporaryDirectories: string[] = []

async function temporaryDirectory(): Promise<string> {
  const directory = await mkdtemp(path.join(os.tmpdir(), 'egdata-library-tools-'))
  temporaryDirectories.push(directory)
  return directory
}

function parsedManifest(): Manifest {
  return {
    header: {
      headerSize: 41,
      dataSizeUncompressed: 100,
      dataSizeCompressed: 80,
      sha1Hash: '0123456789abcdef0123456789abcdef01234567',
      storedAs: 1,
      version: 18,
      guid: GUID,
      rollingHash: 0,
      hashType: 1,
    },
    meta: {
      dataSize: 1,
      dataVersion: 1,
      featureLevel: 18,
      isFileData: false,
      appId: 10,
      appName: 'TestBuildApp',
      buildVersion: '1.2.3',
      launchExe: 'Binaries\\TestGame.exe',
      launchCommand: '-epicportal',
      prereqIds: ['Prereq'],
      prereqName: '',
      prereqPath: '',
      prereqArgs: '',
    },
    fileList: {
      dataSize: 1,
      dataVersion: 1,
      count: 1,
      fileManifestList: [
        {
          filename: 'Binaries/TestGame.exe',
          symlinkTarget: '',
          shaHash: 'abcdef',
          fileMetaFlags: 0,
          installTags: ['core'],
          chunkParts: [],
          fileSize: 4,
          mimeType: '',
        },
      ],
    },
  }
}

async function writeJson(filePath: string, value: unknown): Promise<void> {
  await mkdir(path.dirname(filePath), { recursive: true })
  await writeFile(filePath, `${JSON.stringify(value, null, 2)}\n`)
}

afterEach(async () => {
  vi.restoreAllMocks()
  await Promise.all(
    temporaryDirectories
      .splice(0)
      .map((directory) => rm(directory, { recursive: true, force: true })),
  )
})

describe('LibraryToolsService', () => {
  test('preserves the exact installation directory name at the destination', () => {
    expect(moveDestinationForParent('K:\\Epic Games\\DeltaForce77xWn', 'F:\\')).toBe(
      'F:\\DeltaForce77xWn',
    )
  })

  test('limits the system drive to Program Files and registered locations', () => {
    const scopes = discoveryScopesForRoot(
      'C:\\',
      {
        SystemDrive: 'C:',
        ProgramFiles: 'C:\\Program Files',
        'ProgramFiles(x86)': 'C:\\Program Files (x86)',
      },
      ['C:\\Custom Library\\KnownGame', 'D:\\Epic Games\\OtherGame'],
    )

    expect(scopes).toEqual(
      expect.arrayContaining([
        { root: 'C:\\Program Files', maxDepth: 6 },
        { root: 'C:\\Program Files (x86)', maxDepth: 6 },
        { root: 'C:\\Custom Library\\KnownGame', maxDepth: 6 },
      ]),
    )
    expect(scopes.some((scope) => scope.root.startsWith('C:\\Users'))).toBe(false)
    expect(scopes.some((scope) => scope.root.startsWith('D:\\'))).toBe(false)
  })

  test('excludes ReFS Dev Drives from discovery', () => {
    expect(
      driveRootsFromResponse([
        { root: 'C:\\', fileSystem: 'NTFS' },
        { root: 'D:\\', fileSystem: 'ReFS' },
        { root: 'E:\\', fileSystem: 'exFAT' },
        { root: 'F:\\', fileSystem: '' },
      ]),
    ).toEqual(['C:\\', 'E:\\'])
  })

  test('cancels an active drive scan and returns to idle', async () => {
    const root = await temporaryDirectory()
    const egstore = path.join(root, 'drive', 'TestGame', '.egstore')
    await mkdir(egstore, { recursive: true })
    await writeFile(path.join(egstore, `${GUID}.manifest`), 'binary-placeholder')
    let releaseParser: (() => void) | undefined
    const parserResult = new Promise<Manifest>((resolve) => {
      releaseParser = () => resolve(parsedManifest())
    })
    const parseManifest = vi.fn(() => parserResult)
    const service = new LibraryToolsService({
      platform: 'win32',
      environment: { ProgramData: path.join(root, 'ProgramData') },
      userData: path.join(root, 'userData'),
      isLauncherRunning: () => Promise.resolve(false),
      parseManifest,
    })

    const scanning = service.scan([path.join(root, 'drive')])
    await vi.waitFor(() => expect(parseManifest).toHaveBeenCalledOnce())
    expect(service.snapshot).toMatchObject({
      state: 'scanning',
      scanProgress: {
        phase: 'parsing',
        totalDrives: 1,
        manifestDirectories: 1,
      },
    })
    const cancelling = service.cancelScan()
    releaseParser?.()

    expect((await cancelling).state).toBe('idle')
    expect((await scanning).state).toBe('idle')
  })

  test('discovers and atomically recovers a resolved installation', async () => {
    const root = await temporaryDirectory()
    const programData = path.join(root, 'ProgramData')
    const installation = path.join(root, 'drive', 'TestGame')
    const egstore = path.join(installation, '.egstore')
    const manifestPath = path.join(egstore, `${GUID}.manifest`)
    await mkdir(path.join(installation, 'Binaries'), { recursive: true })
    await writeFile(path.join(installation, 'Binaries', 'TestGame.exe'), 'game')
    await mkdir(egstore, { recursive: true })
    await writeFile(manifestPath, 'binary-placeholder')

    const installedPath = path.join(
      programData,
      'Epic',
      'UnrealEngineLauncher',
      'LauncherInstalled.dat',
    )
    await writeJson(installedPath, { InstallationList: [], FutureTopLevelField: 'preserved' })
    const fetchImpl: typeof fetch = (_input, init) => {
      if (typeof init?.body !== 'string') throw new Error('Expected a JSON request body')
      const request = JSON.parse(init.body) as {
        candidates: Array<{ requestId: string }>
      }
      return Promise.resolve(
        Response.json({
          results: request.candidates.map(({ requestId }) => ({
            requestId,
            status: 'resolved',
            record: {
              artifactId: 'TestArtifact',
              catalogItemId: 'TestCatalogItem',
              catalogNamespace: 'test-namespace',
              displayName: 'Test Game',
              kind: 'base-game',
              appCategories: ['games'],
              mainGame: null,
              mandatoryAppFolderName: 'TestGame',
              canRunOffline: true,
              requiresAuth: false,
              ownershipToken: false,
              ignoredProcessNames: [],
            },
          })),
        }),
      )
    }
    const service = new LibraryToolsService({
      platform: 'win32',
      environment: { ProgramData: programData },
      userData: path.join(root, 'userData'),
      isLauncherRunning: () => Promise.resolve(false),
      parseManifest: () => Promise.resolve(parsedManifest()),
      fetchImpl,
    })

    const scanned = await service.scan([path.join(root, 'drive')])
    expect(scanned.candidates).toHaveLength(1)
    expect(scanned.candidates[0]).toMatchObject({
      displayName: 'Test Game',
      recoverable: true,
      status: 'resolved',
    })

    const recovered = await service.recover([scanned.candidates[0]!.id])
    expect(recovered.candidates).toHaveLength(0)
    const itemPath = path.join(
      programData,
      'Epic',
      'EpicGamesLauncher',
      'Data',
      'Manifests',
      `${GUID}.item`,
    )
    const item = JSON.parse(await readFile(itemPath, 'utf8')) as Record<string, unknown>
    expect(item).toMatchObject({
      InstallationGuid: GUID,
      AppName: 'TestArtifact',
      AppVersionString: '1.2.3',
      InstallLocation: installation,
      ManifestHash: parsedManifest().header.sha1Hash,
      InstallTags: ['core'],
    })
    expect(item.InstallSessionId).toMatch(/^[A-F0-9]{32}$/)
    const installed = JSON.parse(await readFile(installedPath, 'utf8')) as {
      FutureTopLevelField: string
      InstallationList: Array<Record<string, unknown>>
    }
    expect(installed.FutureTopLevelField).toBe('preserved')
    expect(installed.InstallationList[0]).toMatchObject({
      InstallLocation: installation,
      AppName: 'TestArtifact',
    })
  })
  test('uses the local catalog resolver before the live fallback', async () => {
    const root = await temporaryDirectory()
    const egstore = path.join(root, 'drive', 'TestGame', '.egstore')
    await mkdir(path.join(root, 'drive', 'TestGame', 'Binaries'), { recursive: true })
    await writeFile(path.join(root, 'drive', 'TestGame', 'Binaries', 'TestGame.exe'), 'game')
    await mkdir(egstore, { recursive: true })
    await writeFile(path.join(egstore, `${GUID}.manifest`), 'binary-placeholder')

    let localCalls = 0
    let remoteCalls = 0
    const fetchImpl: typeof fetch = () => {
      remoteCalls += 1
      throw new Error('The live resolver should not be called')
    }
    const service = new LibraryToolsService({
      platform: 'win32',
      environment: { ProgramData: path.join(root, 'ProgramData') },
      userData: path.join(root, 'userData'),
      isLauncherRunning: () => Promise.resolve(false),
      parseManifest: () => Promise.resolve(parsedManifest()),
      fetchImpl,
      resolveLauncherRecords: (candidates) => {
        localCalls += 1
        return Promise.resolve(
          candidates.map((candidate) => ({
            requestId: candidate.requestId,
            status: 'resolved' as const,
            record: {
              artifactId: 'TestArtifact',
              catalogItemId: 'TestCatalogItem',
              catalogNamespace: 'test-namespace',
              displayName: 'Catalog Test Game',
              kind: 'base-game' as const,
              appCategories: ['games'],
              mainGame: null,
              mandatoryAppFolderName: 'TestGame',
              canRunOffline: true,
              requiresAuth: false,
              ownershipToken: false,
              ignoredProcessNames: [],
            },
          })),
        )
      },
    })

    const scanned = await service.scan([path.join(root, 'drive')])

    expect(localCalls).toBe(1)
    expect(remoteCalls).toBe(0)
    expect(scanned.candidates[0]).toMatchObject({
      displayName: 'Catalog Test Game',
      recoverable: true,
      status: 'resolved',
    })
  })

  test('moves a same-volume group and preserves unknown launcher fields', async () => {
    const root = await temporaryDirectory()
    const programData = path.join(root, 'ProgramData')
    const source = path.join(root, 'source', 'TestGame')
    const destinationParent = path.join(root, 'destination')
    const destination = path.join(destinationParent, 'TestGame')
    await mkdir(path.join(source, '.egstore'), { recursive: true })
    await mkdir(destinationParent, { recursive: true })
    await writeFile(path.join(source, '.egstore', `${GUID}.manifest`), 'manifest')
    await writeFile(path.join(source, 'payload.bin'), 'payload')

    const itemPath = path.join(
      programData,
      'Epic',
      'EpicGamesLauncher',
      'Data',
      'Manifests',
      `${GUID}.item`,
    )
    await writeJson(itemPath, {
      DisplayName: 'Test Game',
      AppName: 'TestArtifact',
      AppCategories: ['games'],
      InstallLocation: source,
      ManifestLocation: path.join(source, '.egstore'),
      CompleteManifestPath: path.join(source, '.egstore', `${GUID}.manifest`),
      PendingManifestPath: path.join(source, '.egstore', 'Pending', `${GUID}.manifest`),
      StagingLocation: path.join(source, '.egstore', 'bps'),
      InstallSize: 15,
      FutureItemField: { preserved: true },
    })
    const installedPath = path.join(
      programData,
      'Epic',
      'UnrealEngineLauncher',
      'LauncherInstalled.dat',
    )
    await writeJson(installedPath, {
      InstallationList: [
        { InstallLocation: source, AppName: 'TestArtifact', FutureEntryField: 'preserved' },
      ],
      FutureTopLevelField: 'preserved',
    })
    const service = new LibraryToolsService({
      platform: 'win32',
      environment: { ProgramData: programData },
      userData: path.join(root, 'userData'),
      isLauncherRunning: () => Promise.resolve(false),
    })
    await service.initialize(false)
    const game = service.snapshot.registeredGames[0]!
    const prepared = await service.prepareMove(game.id, destinationParent)
    const completed = await service.startMove(prepared.operationId)

    expect(completed.move).toMatchObject({ state: 'complete', restartLauncher: true })
    await expect(stat(source)).rejects.toMatchObject({ code: 'ENOENT' })
    expect((await stat(destination)).isDirectory()).toBe(true)
    const movedItem = JSON.parse(await readFile(itemPath, 'utf8')) as Record<string, unknown>
    expect(movedItem).toMatchObject({
      InstallLocation: destination,
      ManifestLocation: path.join(destination, '.egstore'),
      FutureItemField: { preserved: true },
    })
    const installed = JSON.parse(await readFile(installedPath, 'utf8')) as {
      InstallationList: Array<Record<string, unknown>>
      FutureTopLevelField: string
    }
    expect(installed.FutureTopLevelField).toBe('preserved')
    expect(installed.InstallationList[0]).toMatchObject({
      InstallLocation: destination,
      FutureEntryField: 'preserved',
    })
  })
})
