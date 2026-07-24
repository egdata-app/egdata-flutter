import type { App, LoginItemSettings } from 'electron'
import { describe, expect, it, vi } from 'vitest'

import { LaunchAtStartupController } from './launch-at-startup'

function loginItemSettings(overrides: Partial<LoginItemSettings> = {}): LoginItemSettings {
  return {
    openAtLogin: false,
    openAsHidden: false,
    wasOpenedAtLogin: false,
    wasOpenedAsHidden: false,
    restoreState: false,
    status: 'not-registered',
    executableWillLaunchAtLogin: false,
    launchItems: [],
    ...overrides,
  }
}

function createApp(settings: LoginItemSettings, isPackaged = true) {
  return {
    isPackaged,
    getLoginItemSettings: vi.fn(() => settings),
    setLoginItemSettings: vi.fn(),
  } satisfies Pick<App, 'getLoginItemSettings' | 'isPackaged' | 'setLoginItemSettings'>
}

describe('launch at startup', () => {
  it('registers an installed Windows app with a hidden launch argument', () => {
    const app = createApp(
      loginItemSettings({ openAtLogin: true, executableWillLaunchAtLogin: true }),
    )
    const controller = new LaunchAtStartupController({
      app,
      platform: 'win32',
      executablePath: 'C:\\Program Files\\egdata.app\\egdata.app.exe',
      windowsStore: false,
    })

    expect(controller.getStatus()).toEqual({ available: true, enabled: true })
    expect(app.getLoginItemSettings).toHaveBeenCalledWith({
      path: 'C:\\Program Files\\egdata.app\\egdata.app.exe',
      args: ['--hidden'],
    })

    controller.setEnabled(true)
    expect(app.setLoginItemSettings).toHaveBeenCalledWith({
      openAtLogin: true,
      path: 'C:\\Program Files\\egdata.app\\egdata.app.exe',
      args: ['--hidden'],
    })
  })

  it('does not expose registration in development or AppX builds', () => {
    const development = new LaunchAtStartupController({
      app: createApp(loginItemSettings(), false),
      platform: 'win32',
      executablePath: 'electron.exe',
      windowsStore: false,
    })
    const appx = new LaunchAtStartupController({
      app: createApp(loginItemSettings()),
      platform: 'win32',
      executablePath: 'egdata.app.exe',
      windowsStore: true,
    })

    expect(development.getStatus()).toEqual({ available: false, enabled: false })
    expect(appx.getStatus()).toEqual({ available: false, enabled: false })
    expect(() => development.setEnabled(true)).toThrow('unavailable')
    expect(() => appx.setEnabled(true)).toThrow('unavailable')
  })

  it('detects Windows arguments and macOS login launches', () => {
    const windows = new LaunchAtStartupController({
      app: createApp(loginItemSettings(), false),
      platform: 'win32',
      executablePath: 'electron.exe',
      windowsStore: false,
    })
    const macos = new LaunchAtStartupController({
      app: createApp(loginItemSettings({ wasOpenedAtLogin: true })),
      platform: 'darwin',
      executablePath: '/Applications/egdata.app.app/Contents/MacOS/egdata.app',
      windowsStore: false,
    })

    expect(windows.isHiddenLaunch(['electron.exe', '.', '--hidden'])).toBe(true)
    expect(macos.isHiddenLaunch([])).toBe(true)
  })
})
