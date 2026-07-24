import { readFile, writeFile } from 'node:fs/promises'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const desktopRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const packagePath = path.join(desktopRoot, 'package.json')
const version = process.argv[2]

if (!version || !/^\d+\.\d+\.\d+(?:-[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?$/.test(version)) {
  throw new Error('Release version must be SemVer, for example 1.4.0 or 1.4.0-beta.1.')
}

const packageDocument = JSON.parse(await readFile(packagePath, 'utf8'))
packageDocument.version = version
await writeFile(packagePath, `${JSON.stringify(packageDocument, null, 2)}\n`, 'utf8')
process.stdout.write(`Electron package version set to ${version}.\n`)
