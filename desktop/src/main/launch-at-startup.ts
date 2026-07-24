import type { App } from 'electron'

const HIDDEN_LAUNCH_ARGUMENT = '--hidden'

export interface LaunchAtStartupStatus {
  readonly available: boolean
  readonly enabled: boolean
}

export interface LaunchAtStartupOptions {
  readonly app: Pick<App, 'getLoginItemSettings' | 'isPackaged' | 'setLoginItemSettings'>
  readonly platform: NodeJS.Platform
  readonly executablePath: string
  readonly windowsStore: boolean
}

export class LaunchAtStartupController {
  readonly #app: LaunchAtStartupOptions['app']
  readonly #platform: NodeJS.Platform
  readonly #executablePath: string
  readonly #windowsStore: boolean

  constructor(options: LaunchAtStartupOptions) {
    this.#app = options.app
    this.#platform = options.platform
    this.#executablePath = options.executablePath
    this.#windowsStore = options.windowsStore
  }

  get available(): boolean {
    return (
      this.#app.isPackaged &&
      !this.#windowsStore &&
      (this.#platform === 'win32' || this.#platform === 'darwin')
    )
  }

  getStatus(): LaunchAtStartupStatus {
    if (!this.available) return { available: false, enabled: false }
    const settings = this.#app.getLoginItemSettings(this.#loginItemOptions())
    const enabled =
      this.#platform === 'win32'
        ? settings.openAtLogin && settings.executableWillLaunchAtLogin
        : settings.openAtLogin
    return { available: true, enabled }
  }

  setEnabled(enabled: boolean): void {
    if (!this.available) {
      throw new Error('Launch at startup is unavailable in this build.')
    }
    this.#app.setLoginItemSettings({
      openAtLogin: enabled,
      ...(this.#platform === 'win32'
        ? { path: this.#executablePath, args: [HIDDEN_LAUNCH_ARGUMENT] }
        : {}),
    })
  }

  isHiddenLaunch(arguments_: readonly string[]): boolean {
    if (this.#platform === 'win32') return arguments_.includes(HIDDEN_LAUNCH_ARGUMENT)
    return this.available && this.#platform === 'darwin'
      ? this.#app.getLoginItemSettings().wasOpenedAtLogin
      : false
  }

  #loginItemOptions(): Electron.LoginItemSettingsOptions | undefined {
    return this.#platform === 'win32'
      ? { path: this.#executablePath, args: [HIDDEN_LAUNCH_ARGUMENT] }
      : undefined
  }
}

export function hasHiddenLaunchArgument(arguments_: readonly string[]): boolean {
  return arguments_.includes(HIDDEN_LAUNCH_ARGUMENT)
}
