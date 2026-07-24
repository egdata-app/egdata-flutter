import { randomUUID } from 'node:crypto'
import { existsSync } from 'node:fs'
import { createRequire } from 'node:module'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

interface NativeScanResult {
  egstores: string[]
  directoriesChecked: number
}

interface NativeScannerBinding {
  scan(root: string, operationId: string, maxDepth?: number): Promise<unknown>
  cancel(operationId: string): boolean
}

let cachedBinding: NativeScannerBinding | null | undefined

export async function scanWindowsEgstores(
  root: string,
  signal: AbortSignal,
  maxDepth?: number,
): Promise<NativeScanResult | null> {
  const binding = loadBinding()
  if (!binding) return null
  if (signal.aborted) throw new DOMException('Cancelled', 'AbortError')

  const operationId = randomUUID()
  const cancel = (): void => {
    binding.cancel(operationId)
  }
  signal.addEventListener('abort', cancel, { once: true })
  try {
    const result = await binding.scan(root, operationId, maxDepth)
    if (signal.aborted) throw new DOMException('Cancelled', 'AbortError')
    if (!isNativeScanResult(result)) throw new Error('Invalid native drive scan response')
    return result
  } catch (error) {
    if (signal.aborted || (error instanceof Error && error.message.includes('SCAN_CANCELLED'))) {
      throw new DOMException('Cancelled', 'AbortError')
    }
    throw error
  } finally {
    signal.removeEventListener('abort', cancel)
  }
}

export function nativeScannerAvailable(): boolean {
  return loadBinding() !== null
}

function loadBinding(): NativeScannerBinding | null {
  if (cachedBinding !== undefined) return cachedBinding
  if (process.platform !== 'win32' || !['x64', 'arm64'].includes(process.arch)) {
    cachedBinding = null
    return cachedBinding
  }

  const processWithResources = process as NodeJS.Process & { resourcesPath?: string }
  const outputDirectory = path.dirname(fileURLToPath(import.meta.url))
  const relativeBinding = path.join(
    'native',
    `win32-${process.arch}`,
    'egdata-native-scanner-v2.node',
  )
  const candidates = [
    ...(processWithResources.resourcesPath
      ? [path.join(processWithResources.resourcesPath, relativeBinding)]
      : []),
    path.join(process.cwd(), 'resources', relativeBinding),
    path.resolve(outputDirectory, '..', '..', 'resources', relativeBinding),
  ]
  const require = createRequire(import.meta.url)
  for (const candidate of candidates) {
    if (!existsSync(candidate)) continue
    try {
      const loaded: unknown = require(candidate)
      if (isNativeScannerBinding(loaded)) {
        cachedBinding = loaded
        return cachedBinding
      }
    } catch {
      // A missing or incompatible binding falls back to the safe scanner.
    }
  }
  cachedBinding = null
  return cachedBinding
}

function isNativeScannerBinding(value: unknown): value is NativeScannerBinding {
  return (
    value !== null &&
    typeof value === 'object' &&
    'scan' in value &&
    typeof value.scan === 'function' &&
    'cancel' in value &&
    typeof value.cancel === 'function'
  )
}

function isNativeScanResult(value: unknown): value is NativeScanResult {
  if (value === null || typeof value !== 'object' || !('egstores' in value)) return false
  if (!('directoriesChecked' in value)) return false
  return (
    Array.isArray(value.egstores) &&
    value.egstores.every((entry) => typeof entry === 'string') &&
    typeof value.directoriesChecked === 'number' &&
    Number.isSafeInteger(value.directoriesChecked) &&
    value.directoriesChecked >= 0
  )
}
