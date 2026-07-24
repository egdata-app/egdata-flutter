import { mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises'
import os from 'node:os'
import path from 'node:path'

import { afterEach, describe, expect, test } from 'vitest'

import {
  nativeScannerAvailable,
  scanWindowsEgstores,
} from '../../src/main/library-tools/native-scanner'
const temporaryDirectories: string[] = []

afterEach(async () => {
  await Promise.all(
    temporaryDirectories
      .splice(0)
      .map((directory) => rm(directory, { recursive: true, force: true })),
  )
})

describe.skipIf(process.platform !== 'win32')('native Windows egstore scanner', () => {
  test('ships ABI-stable x64 and arm64 Windows bindings', async () => {
    const resources = path.resolve('resources', 'native')
    await expectPeMachine(
      path.join(resources, 'win32-x64', 'egdata-native-scanner-v2.node'),
      0x8664,
    )
    await expectPeMachine(
      path.join(resources, 'win32-arm64', 'egdata-native-scanner-v2.node'),
      0xaa64,
    )
  })

  test('finds direct manifests without traversing protected or egstore directories', async () => {
    const root = await mkdtemp(path.join(os.tmpdir(), 'egdata-native-scan-'))
    temporaryDirectories.push(root)
    await writeFileTree(root, {
      'Game/.egstore/0123456789ABCDEF0123456789ABCDEF.manifest': 'manifest',
      'Empty/.egstore/readme.txt': 'not a manifest',
      'Nested/.egstore/cache/ABCDEF0123456789ABCDEF0123456789.manifest': 'nested',
      'Windows/Hidden/.egstore/ABCDEF0123456789ABCDEF0123456789.manifest': 'protected',
    })

    expect(nativeScannerAvailable()).toBe(true)
    const result = await scanWindowsEgstores(root, new AbortController().signal)

    expect(result).not.toBeNull()
    expect(result?.egstores.map((entry) => path.normalize(entry))).toEqual([
      path.join(root, 'Game', '.egstore'),
    ])
    expect(result?.directoriesChecked).toBeGreaterThan(0)
  })

  test('honors cancellation before native work starts', async () => {
    const controller = new AbortController()
    controller.abort()
    await expect(scanWindowsEgstores(os.tmpdir(), controller.signal)).rejects.toMatchObject({
      name: 'AbortError',
    })
  })

  test('stops traversal at the requested depth', async () => {
    const root = await mkdtemp(path.join(os.tmpdir(), 'egdata-native-depth-'))
    temporaryDirectories.push(root)
    const egstore = path.join(root, 'One', 'Two', 'Three', '.egstore')
    await writeFileTree(root, {
      'One/Two/Three/.egstore/0123456789ABCDEF0123456789ABCDEF.manifest': 'manifest',
    })

    const limited = await scanWindowsEgstores(root, new AbortController().signal, 2)
    const unlimited = await scanWindowsEgstores(root, new AbortController().signal)

    expect(limited?.egstores).toEqual([])
    expect(unlimited?.egstores.map((entry) => path.normalize(entry))).toEqual([egstore])
  })

  test('cancels native work after it has been queued', async () => {
    const controller = new AbortController()
    const scanning = scanWindowsEgstores(os.tmpdir(), controller.signal)
    controller.abort()
    await expect(scanning).rejects.toMatchObject({ name: 'AbortError' })
  })
})

async function expectPeMachine(filePath: string, expectedMachine: number): Promise<void> {
  const binary = await readFile(filePath)
  const peOffset = binary.readUInt32LE(0x3c)
  expect(binary.toString('ascii', peOffset, peOffset + 4)).toBe('PE\0\0')
  expect(binary.readUInt16LE(peOffset + 4)).toBe(expectedMachine)
}

async function writeFileTree(root: string, files: Record<string, string>): Promise<void> {
  await Promise.all(
    Object.entries(files).map(async ([relativePath, contents]) => {
      const filePath = path.join(root, relativePath)
      await mkdir(path.dirname(filePath), { recursive: true })
      await writeFile(filePath, contents)
    }),
  )
}
