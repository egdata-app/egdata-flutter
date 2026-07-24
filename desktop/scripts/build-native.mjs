import { copyFile, mkdir, readFile } from 'node:fs/promises'
import path from 'node:path'
import { spawn } from 'node:child_process'
import { fileURLToPath } from 'node:url'

const desktopRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const manifestPath = path.join(desktopRoot, 'native', 'egstore-scanner', 'Cargo.toml')
const requestedArch = process.argv.find((argument) => argument.startsWith('--arch='))?.slice(7)
const architectures = requestedArch === 'all' ? ['x64', 'arm64'] : [requestedArch ?? process.arch]
const rustTargets = {
  x64: 'x86_64-pc-windows-msvc',
  arm64: 'aarch64-pc-windows-msvc',
}

if (process.platform !== 'win32') {
  process.stdout.write('[native] Windows scanner build skipped on this platform.\n')
  process.exit(0)
}

for (const architecture of architectures) {
  const target = rustTargets[architecture]
  if (!target) throw new Error(`Unsupported native scanner architecture: ${architecture}`)
  const cargoArguments = [
    ...(architecture === 'arm64' && process.arch !== 'arm64' ? ['xwin'] : []),
    'build',
    '--manifest-path',
    manifestPath,
    '--release',
    '--target',
    target,
  ]
  const environment =
    architecture === 'arm64' && process.arch !== 'arm64'
      ? await arm64CrossEnvironment()
      : process.env
  await run('cargo', cargoArguments, environment)
  const source = path.join(
    desktopRoot,
    'native',
    'egstore-scanner',
    'target',
    target,
    'release',
    'egdata_native_scanner.dll',
  )
  const outputDirectory = path.join(desktopRoot, 'resources', 'native', `win32-${architecture}`)
  await mkdir(outputDirectory, { recursive: true })
  const destination = path.join(outputDirectory, 'egdata-native-scanner-v2.node')
  const copied = await copyIfChanged(source, destination)
  process.stdout.write(
    copied
      ? `[native] Built Windows ${architecture} scanner.\n`
      : `[native] Windows ${architecture} scanner is current.\n`,
  )
}

async function copyIfChanged(source, destination) {
  const sourceContents = await readFile(source)
  const destinationContents = await readFile(destination).catch(() => null)
  if (destinationContents?.equals(sourceContents)) return false
  try {
    await copyFile(source, destination)
  } catch (error) {
    if (error && typeof error === 'object' && 'code' in error && error.code === 'EBUSY') {
      throw new Error('The native scanner changed. Restart egdata.app before rebuilding it.', {
        cause: error,
      })
    }
    throw error
  }
  return true
}

function run(command, arguments_, environment = process.env) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, arguments_, {
      cwd: desktopRoot,
      stdio: 'inherit',
      windowsHide: true,
      env: environment,
    })
    child.once('error', reject)
    child.once('exit', (code) => {
      if (code === 0) resolve()
      else reject(new Error(`${command} exited with code ${code ?? 'unknown'}`))
    })
  })
}

async function arm64CrossEnvironment() {
  const rustSysroot = (await output('rustc', ['--print', 'sysroot'])).trim()
  const rustLld = path.join(
    rustSysroot,
    'lib',
    'rustlib',
    'x86_64-pc-windows-msvc',
    'bin',
    'rust-lld.exe',
  )
  const toolDirectory = path.join(desktopRoot, 'native', 'egstore-scanner', 'target', 'xwin-tools')
  await mkdir(toolDirectory, { recursive: true })
  await copyFile(rustLld, path.join(toolDirectory, 'lld-link.exe'))
  return { ...process.env, PATH: `${toolDirectory};${process.env.PATH ?? ''}` }
}

function output(command, arguments_) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, arguments_, { cwd: desktopRoot, windowsHide: true })
    let stdout = ''
    let stderr = ''
    child.stdout.setEncoding('utf8')
    child.stderr.setEncoding('utf8')
    child.stdout.on('data', (chunk) => {
      stdout += chunk
    })
    child.stderr.on('data', (chunk) => {
      stderr += chunk
    })
    child.once('error', reject)
    child.once('exit', (code) => {
      if (code === 0) resolve(stdout)
      else reject(new Error(stderr.trim() || `${command} exited with code ${code ?? 'unknown'}`))
    })
  })
}
