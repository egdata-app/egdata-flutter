import { join } from 'node:path'
import { pathToFileURL } from 'node:url'

import { BrowserWindow, screen, shell } from 'electron'

import type { DiagnosticLogger } from './diagnostics'
import type { SettingsStorage } from './storage'
import { boundWindowState } from './storage'

const MINIMUM_WIDTH = 640
const MINIMUM_HEIGHT = 480

export interface CreateMainWindowOptions {
  readonly settings: SettingsStorage
  readonly logger: DiagnosticLogger
  readonly isDevelopment: boolean
}

export async function createMainWindow({
  settings,
  logger,
  isDevelopment,
}: CreateMainWindowOptions): Promise<BrowserWindow> {
  const savedSettings = await settings.load()
  const displays = screen.getAllDisplays()
  const primaryDisplay = screen.getPrimaryDisplay()
  const bounds = boundWindowState(
    savedSettings.window.bounds,
    displays.map(({ workArea }) => workArea),
    primaryDisplay.workArea,
  )
  const resourceDirectory = isDevelopment ? join(process.cwd(), 'resources') : process.resourcesPath
  const iconPath = join(resourceDirectory, process.platform === 'win32' ? 'icon.ico' : 'icon.png')
  const window = new BrowserWindow({
    ...bounds,
    minWidth: MINIMUM_WIDTH,
    minHeight: MINIMUM_HEIGHT,
    show: false,
    autoHideMenuBar: true,
    backgroundColor: '#090b10',
    title: 'egdata.app',
    icon: iconPath,
    titleBarStyle: 'hidden',
    ...(process.platform !== 'darwin'
      ? {
          titleBarOverlay: {
            color: '#0b0c0e',
            symbolColor: '#c7c7c7',
            height: 32,
          },
        }
      : {}),
    webPreferences: {
      preload: join(__dirname, '../preload/index.cjs'),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true,
      webSecurity: true,
      allowRunningInsecureContent: false,
      spellcheck: false,
      devTools: isDevelopment ? true : false,
    },
  })

  if (isDevelopment) window.webContents.openDevTools()

  if (process.platform !== 'darwin') window.removeMenu()

  if (savedSettings.window.maximized) window.maximize()

  window.once('ready-to-show', () => window.show())
  window.webContents.setWindowOpenHandler(({ url }) => {
    void openExternalLink(url, logger)
    return { action: 'deny' }
  })
  window.webContents.on('will-navigate', (event, url) => {
    if (isApplicationUrl(url, isDevelopment)) return
    event.preventDefault()
    void openExternalLink(url, logger)
  })
  window.webContents.on('will-attach-webview', (event) => event.preventDefault())
  window.webContents.on('render-process-gone', (_event, details) => {
    void logger.error('window', 'Renderer process exited', {
      reason: details.reason,
      exitCode: details.exitCode,
    })
  })
  window.on('close', () => {
    const normalBounds = window.getNormalBounds()
    void settings
      .updateWindowState(normalBounds, window.isMaximized())
      .catch((error: unknown) => logger.error('settings', 'Unable to save window state', { error }))
  })

  if (isDevelopment && process.env.ELECTRON_RENDERER_URL) {
    await window.loadURL(process.env.ELECTRON_RENDERER_URL)
  } else {
    await window.loadFile(join(__dirname, '../renderer/index.html'))
  }

  return window
}

export function focusWindow(window: BrowserWindow | null): void {
  if (!window || window.isDestroyed()) return
  if (window.isMinimized()) window.restore()
  window.show()
  window.focus()
}

function isApplicationUrl(url: string, isDevelopment: boolean): boolean {
  if (!isDevelopment) {
    try {
      const target = new URL(url)
      const application = pathToFileURL(join(__dirname, '../renderer/index.html'))
      return target.protocol === 'file:' && target.pathname === application.pathname
    } catch {
      return false
    }
  }
  if (!process.env.ELECTRON_RENDERER_URL) return false
  try {
    return new URL(url).origin === new URL(process.env.ELECTRON_RENDERER_URL).origin
  } catch {
    return false
  }
}

async function openExternalLink(url: string, logger: DiagnosticLogger): Promise<void> {
  try {
    const parsed = new URL(url)
    if (parsed.protocol !== 'https:' && parsed.protocol !== 'http:') {
      await logger.warn('navigation', 'Blocked external URL protocol', {
        protocol: parsed.protocol,
      })
      return
    }
    await shell.openExternal(parsed.toString())
  } catch (error) {
    await logger.warn('navigation', 'Failed to open external URL', { url, error })
  }
}
