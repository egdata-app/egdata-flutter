import { describe, expect, it } from 'vitest'

import { DEFAULT_SETTINGS, parseSettingsDocument } from './settings'
import { boundWindowState } from './window_state'

describe('settings storage', () => {
  it('uses safe defaults for malformed or unsupported documents', () => {
    expect(parseSettingsDocument({ version: 99 })).toEqual(DEFAULT_SETTINGS)
    expect(parseSettingsDocument(null)).toEqual(DEFAULT_SETTINGS)
  })

  it('accepts a valid versioned document', () => {
    const document = structuredClone(DEFAULT_SETTINGS)
    document.preferences.contributionConsent = true
    expect(parseSettingsDocument(document).preferences.contributionConsent).toBe(true)
  })

  it('migrates version 2 preferences without enabling startup launch', () => {
    const document = parseSettingsDocument({
      version: 2,
      window: { maximized: true },
      preferences: {
        contributionConsent: true,
        includePathsInDiagnostics: true,
        updateChannel: 'beta',
        automaticallyCheckForUpdates: false,
        automaticallyScanWindowsDrives: false,
      },
    })

    expect(document).toEqual({
      version: 4,
      window: { maximized: true },
      preferences: {
        contributionConsent: true,
        automaticUploadsEnabled: true,
        automaticLocalUploadIntervalMinutes: 360,
        automaticCloudUploadIntervalMinutes: 1_440,
        includePathsInDiagnostics: true,
        updateChannel: 'beta',
        automaticallyCheckForUpdates: false,
        automaticallyScanWindowsDrives: false,
        launchAtStartup: false,
      },
    })
  })

  it('migrates version 3 preferences and enables safe automatic upload defaults', () => {
    const document = parseSettingsDocument({
      version: 3,
      window: { maximized: false },
      preferences: {
        contributionConsent: true,
        includePathsInDiagnostics: false,
        updateChannel: 'stable',
        automaticallyCheckForUpdates: true,
        automaticallyScanWindowsDrives: true,
        launchAtStartup: true,
      },
    })

    expect(document.preferences).toMatchObject({
      contributionConsent: true,
      automaticUploadsEnabled: true,
      automaticLocalUploadIntervalMinutes: 360,
      automaticCloudUploadIntervalMinutes: 1_440,
      launchAtStartup: true,
    })
  })

  it('moves an off-screen window onto the primary display', () => {
    const primary = { x: 0, y: 0, width: 1920, height: 1080 }
    const bounds = boundWindowState(
      { x: 50_000, y: 50_000, width: 1200, height: 800 },
      [primary],
      primary,
    )
    expect(bounds).toEqual({ x: 360, y: 140, width: 1200, height: 800 })
  })

  it('shrinks restored bounds to the available work area', () => {
    const primary = { x: 0, y: 0, width: 1024, height: 700 }
    const bounds = boundWindowState({ x: 10, y: 10, width: 2000, height: 1500 }, [primary], primary)
    expect(bounds).toEqual({ x: 0, y: 0, width: 1024, height: 700 })
  })
})
