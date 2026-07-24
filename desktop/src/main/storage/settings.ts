import { mkdir, readFile, rename, writeFile } from 'node:fs/promises'
import { dirname } from 'node:path'

import type { SettingsDocument, SettingsUpdate, StoredSettings, WindowBounds } from '../../shared'
import {
  SettingsDocumentSchema,
  SettingsUpdateSchema,
  StoredSettingsSchema,
  WindowBoundsSchema,
} from '../../shared'

export const DEFAULT_SETTINGS: SettingsDocument = {
  version: 4,
  window: {
    maximized: false,
  },
  preferences: {
    contributionConsent: false,
    automaticUploadsEnabled: true,
    automaticLocalUploadIntervalMinutes: 360,
    automaticCloudUploadIntervalMinutes: 1_440,
    includePathsInDiagnostics: false,
    updateChannel: 'stable',
    automaticallyCheckForUpdates: true,
    automaticallyScanWindowsDrives: true,
    launchAtStartup: false,
  },
}

export function parseSettingsDocument(value: unknown): SettingsDocument {
  const parsed = SettingsDocumentSchema.safeParse(value)
  if (parsed.success) return parsed.data
  if (value && typeof value === 'object' && !Array.isArray(value)) {
    const legacy = value as Record<string, unknown>
    if (legacy.version === 1 || legacy.version === 2 || legacy.version === 3) {
      const window =
        legacy.window && typeof legacy.window === 'object' && !Array.isArray(legacy.window)
          ? (legacy.window as Record<string, unknown>)
          : {}
      const preferences =
        legacy.preferences &&
        typeof legacy.preferences === 'object' &&
        !Array.isArray(legacy.preferences)
          ? (legacy.preferences as Record<string, unknown>)
          : {}
      const migrated = SettingsDocumentSchema.safeParse({
        version: 4,
        window,
        preferences: {
          contributionConsent:
            typeof preferences.contributionConsent === 'boolean'
              ? preferences.contributionConsent
              : DEFAULT_SETTINGS.preferences.contributionConsent,
          automaticUploadsEnabled: DEFAULT_SETTINGS.preferences.automaticUploadsEnabled,
          automaticLocalUploadIntervalMinutes:
            DEFAULT_SETTINGS.preferences.automaticLocalUploadIntervalMinutes,
          automaticCloudUploadIntervalMinutes:
            DEFAULT_SETTINGS.preferences.automaticCloudUploadIntervalMinutes,
          includePathsInDiagnostics:
            typeof preferences.includePathsInDiagnostics === 'boolean'
              ? preferences.includePathsInDiagnostics
              : DEFAULT_SETTINGS.preferences.includePathsInDiagnostics,
          updateChannel:
            preferences.updateChannel === 'beta'
              ? 'beta'
              : DEFAULT_SETTINGS.preferences.updateChannel,
          automaticallyCheckForUpdates:
            typeof preferences.automaticallyCheckForUpdates === 'boolean'
              ? preferences.automaticallyCheckForUpdates
              : DEFAULT_SETTINGS.preferences.automaticallyCheckForUpdates,
          automaticallyScanWindowsDrives:
            legacy.version === 2 && typeof preferences.automaticallyScanWindowsDrives === 'boolean'
              ? preferences.automaticallyScanWindowsDrives
              : DEFAULT_SETTINGS.preferences.automaticallyScanWindowsDrives,
          launchAtStartup:
            legacy.version === 3 && typeof preferences.launchAtStartup === 'boolean'
              ? preferences.launchAtStartup
              : false,
        },
      })
      if (migrated.success) return migrated.data
    }
  }
  return structuredClone(DEFAULT_SETTINGS)
}

export class SettingsStorage {
  readonly #filePath: string
  #document: SettingsDocument = structuredClone(DEFAULT_SETTINGS)
  #loaded = false

  constructor(filePath: string) {
    this.#filePath = filePath
  }

  async load(): Promise<SettingsDocument> {
    if (this.#loaded) return structuredClone(this.#document)

    try {
      this.#document = parseSettingsDocument(JSON.parse(await readFile(this.#filePath, 'utf8')))
    } catch (error) {
      if (!isMissingFileError(error)) {
        this.#document = structuredClone(DEFAULT_SETTINGS)
      }
    }

    this.#loaded = true
    return structuredClone(this.#document)
  }

  async getPreferences(): Promise<StoredSettings> {
    return (await this.load()).preferences
  }

  async updatePreferences(update: SettingsUpdate): Promise<StoredSettings> {
    const validUpdate = SettingsUpdateSchema.parse(update)
    await this.load()
    this.#document.preferences = StoredSettingsSchema.parse({
      ...this.#document.preferences,
      ...validUpdate,
    })
    await this.#persist()
    return structuredClone(this.#document.preferences)
  }

  async updateWindowState(bounds: WindowBounds, maximized: boolean): Promise<void> {
    await this.load()
    this.#document.window = {
      bounds: WindowBoundsSchema.parse(bounds),
      maximized,
    }
    await this.#persist()
  }

  async #persist(): Promise<void> {
    await mkdir(dirname(this.#filePath), { recursive: true })
    const temporaryPath = `${this.#filePath}.${process.pid}.tmp`
    await writeFile(temporaryPath, `${JSON.stringify(this.#document, null, 2)}\n`, {
      encoding: 'utf8',
      mode: 0o600,
    })
    await rename(temporaryPath, this.#filePath)
  }
}

function isMissingFileError(error: unknown): boolean {
  return error instanceof Error && 'code' in error && error.code === 'ENOENT'
}
