import type { DesktopApi } from './api'

declare global {
  interface Window {
    readonly desktopApi: DesktopApi
  }
}

export {}
