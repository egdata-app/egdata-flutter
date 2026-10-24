import path from 'node:path'

import type { LocalManifestPlatform } from './types'

const WINDOWS_MANIFEST_DIRECTORY = 'C:\\ProgramData\\Epic\\EpicGamesLauncher\\Data\\Manifests'

export function resolveDefaultManifestDirectory(
  platform: LocalManifestPlatform,
  environment: NodeJS.ProcessEnv = process.env,
): string {
  if (platform === 'win32') {
    const programData = environment.ProgramData || environment.PROGRAMDATA
    if (programData && path.win32.isAbsolute(programData)) {
      return path.win32.join(programData, 'Epic', 'EpicGamesLauncher', 'Data', 'Manifests')
    }
    return WINDOWS_MANIFEST_DIRECTORY
  }

  const home = environment.HOME
  if (home && path.posix.isAbsolute(home)) {
    return path.posix.join(
      home,
      'Library',
      'Application Support',
      'Epic',
      'EpicGamesLauncher',
      'Data',
      'Manifests',
    )
  }

  const user = environment.USER || environment.LOGNAME
  if (user && /^[^/\\\0]+$/.test(user)) {
    return path.posix.join(
      '/Users',
      user,
      'Library',
      'Application Support',
      'Epic',
      'EpicGamesLauncher',
      'Data',
      'Manifests',
    )
  }

  throw new Error('Could not determine the macOS home directory')
}

/** The Windows launcher v2 stores its installation index in per-user app data. */
export function resolveNewLauncherDirectory(
  platform: LocalManifestPlatform,
  environment: NodeJS.ProcessEnv = process.env,
): string | undefined {
  if (platform !== 'win32') return undefined
  const localAppData =
    environment.LOCALAPPDATA ||
    (environment.USERPROFILE && path.win32.join(environment.USERPROFILE, 'AppData', 'Local'))
  if (!localAppData || !path.win32.isAbsolute(localAppData)) return undefined
  return path.win32.join(localAppData, 'com.epicgames.eglv2')
}

export function isAbsoluteManifestDirectory(
  platform: LocalManifestPlatform,
  directory: string,
): boolean {
  return platform === 'win32' ? path.win32.isAbsolute(directory) : path.posix.isAbsolute(directory)
}

export function normalizeInstallPath(platform: LocalManifestPlatform, installPath: string): string {
  const trimmed = installPath.trim()
  if (!trimmed) return ''

  if (platform === 'win32') {
    return path.win32
      .normalize(trimmed)
      .replace(/[\\/]+$/, '')
      .toLowerCase()
  }

  return path.posix.normalize(trimmed).replace(/\/+$/, '').toLowerCase()
}
