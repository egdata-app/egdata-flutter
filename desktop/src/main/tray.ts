import { join } from 'node:path'

import { Menu, Tray } from 'electron'

export interface CreateApplicationTrayOptions {
  readonly isDevelopment: boolean
  readonly openWindow: () => void
  readonly quit: () => void
}

export function createApplicationTray(options: CreateApplicationTrayOptions): Tray {
  const resourceDirectory = options.isDevelopment
    ? join(process.cwd(), 'resources')
    : process.resourcesPath
  const iconPath = join(resourceDirectory, process.platform === 'win32' ? 'icon.ico' : 'icon.png')
  const tray = new Tray(iconPath)
  tray.setToolTip('egdata.app')
  tray.setContextMenu(
    Menu.buildFromTemplate([
      { label: 'Open egdata.app', click: options.openWindow },
      { type: 'separator' },
      { label: 'Quit egdata.app', click: options.quit },
    ]),
  )
  tray.on('click', options.openWindow)
  return tray
}
