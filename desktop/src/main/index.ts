import { join } from 'node:path'

import { app, session, type BrowserWindow, type Tray } from 'electron'

import { DiagnosticLogger } from './diagnostics'
import { registerIpcHandlers } from './ipc'
import { hasHiddenLaunchArgument, LaunchAtStartupController } from './launch-at-startup'
import { SettingsStorage } from './storage'
import { createApplicationTray } from './tray'
import { createMainWindow, focusWindow } from './windows'

const isDevelopment = !app.isPackaged
const hiddenLaunchArgument = hasHiddenLaunchArgument(process.argv)
const hasSingleInstanceLock = app.requestSingleInstanceLock({
  hiddenLaunch: hiddenLaunchArgument,
})
let mainWindow: BrowserWindow | null = null
let windowCreation: Promise<BrowserWindow> | null = null
let applicationTray: Tray | null = null
let logger: DiagnosticLogger | null = null
let settings: SettingsStorage | null = null
let disposeIpc: (() => void) | null = null
let hiddenInitialLaunch = false
let initialization: Promise<void> | null = null

if (!hasSingleInstanceLock) {
  app.quit()
} else {
  app.setName('egdata.app')

  app.on('second-instance', (_event, _arguments, _workingDirectory, additionalData) => {
    if (!isHiddenLaunchData(additionalData)) void openMainWindow()
  })
  app.on('window-all-closed', () => {
    // The tray and background services keep the application alive.
  })
  app.on('before-quit', () => {
    disposeIpc?.()
    disposeIpc = null
    applicationTray?.destroy()
    applicationTray = null
    void logger?.flush()
  })

  initialization = app.whenReady().then(initializeApplication)
  void initialization
    .then(() => {
      if (hiddenInitialLaunch) hideDockIcon()
      else void openMainWindow()
    })
    .catch(async (error: unknown) => {
      await logger?.error('lifecycle', 'Unable to initialize application', { error })
      app.quit()
    })
}

async function initializeApplication(): Promise<void> {
  configureContentSecurityPolicy()
  const userData = app.getPath('userData')
  logger = new DiagnosticLogger(join(userData, 'diagnostics', 'egdata.log'))
  settings = new SettingsStorage(join(userData, 'settings.v1.json'))
  const launchAtStartup = new LaunchAtStartupController({
    app,
    platform: process.platform,
    executablePath: process.execPath,
    windowsStore: Boolean(process.windowsStore),
  })
  hiddenInitialLaunch = launchAtStartup.isHiddenLaunch(process.argv)
  applicationTray = createApplicationTray({
    isDevelopment,
    openWindow: () => void openMainWindow(),
    quit: () => app.quit(),
  })
  disposeIpc = await registerIpcHandlers({
    getWindow: () => mainWindow,
    settings,
    logger,
    launchAtStartup,
    userData,
    isDevelopment,
  })
  app.on('activate', () => void openMainWindow())
}

async function openMainWindow(): Promise<void> {
  const ready = initialization
  if (!ready) return
  try {
    await ready
  } catch {
    return
  }
  if (mainWindow && !mainWindow.isDestroyed()) {
    focusWindow(mainWindow)
    return
  }
  if (windowCreation) {
    try {
      focusWindow(await windowCreation)
    } catch {
      // The creating caller logs the failure and shuts down the application.
    }
    return
  }
  if (!settings || !logger) return

  if (process.platform === 'darwin') await app.dock?.show()
  windowCreation = createMainWindow({ settings, logger, isDevelopment })
  try {
    const window = await windowCreation
    mainWindow = window
    window.once('closed', () => {
      if (mainWindow === window) mainWindow = null
      hideDockIcon()
    })
    await logger.info('lifecycle', 'Main window opened', {
      version: app.getVersion(),
      platform: process.platform,
    })
  } catch (error) {
    await logger.error('lifecycle', 'Unable to create main window', { error })
    app.quit()
  } finally {
    windowCreation = null
  }
}

function hideDockIcon(): void {
  if (process.platform === 'darwin') app.dock?.hide()
}

function isHiddenLaunchData(value: unknown): boolean {
  return (
    typeof value === 'object' &&
    value !== null &&
    'hiddenLaunch' in value &&
    value.hiddenLaunch === true
  )
}

function configureContentSecurityPolicy(): void {
  const developmentSources = isDevelopment
    ? " http://localhost:* ws://localhost:* 'unsafe-eval' 'unsafe-inline'"
    : ''
  const policy = [
    "default-src 'self'",
    `script-src 'self'${developmentSources}`,
    "style-src 'self' 'unsafe-inline'",
    "font-src 'self' data:",
    "img-src 'self' data: https:",
    `connect-src 'self' https://api.egdata.app https://egdata-builds-api.snpm.workers.dev${developmentSources}`,
    "object-src 'none'",
    "base-uri 'none'",
    "form-action 'none'",
    "frame-ancestors 'none'",
  ].join('; ')

  session.defaultSession.webRequest.onHeadersReceived((details, callback) => {
    const responseHeaders = { ...details.responseHeaders }
    responseHeaders['Content-Security-Policy'] = [policy]
    callback({ responseHeaders })
  })
}
