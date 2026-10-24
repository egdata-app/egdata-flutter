import path from 'node:path'

import { z } from 'zod'

import { parseLocalItem } from './parser'
import type { LocalManifestDiagnostic, ParsedLocalManifest } from './types'

const installationSchema = z.object({
  installationId: z.string().regex(/^[A-Za-z0-9_-]{1,128}$/),
  complete: z.boolean(),
  dir: z
    .string()
    .min(1)
    .max(4096)
    .refine((value) => path.win32.isAbsolute(value)),
  platform: z.string().max(32),
  namespace: z.string().min(1).max(256),
  itemId: z.string().min(1).max(256),
  artifactId: z.string().min(1).max(256),
  version: z.string().max(1024),
  parentInstallationId: z
    .string()
    .regex(/^[A-Za-z0-9_-]{1,128}$/)
    .optional(),
  launchCommand: z.string().max(8192).default(''),
  launchExecutable: z.string().max(4096).default(''),
})

export interface ManifestDiscoverySource {
  sourceName: string
  itemPath: string
  rawItemText: string
  parsed: ParsedLocalManifest
  /** New-launcher records must only resolve their own installation ID. */
  exactBinary?: boolean
}

export function parseNewLauncherIndex(
  text: string,
  itemPath: string,
): { sources: ManifestDiscoverySource[]; errors: LocalManifestDiagnostic[] } {
  const sources: ManifestDiscoverySource[] = []
  const errors: LocalManifestDiagnostic[] = []
  const records = new Map<string, z.infer<typeof installationSchema>>()
  const lines = text.replace(/^\uFEFF/, '').split(/\r?\n/)
  const invalid = (line: number): void => {
    errors.push({
      code: 'LOCAL_ITEM_INVALID_JSON',
      message: 'The Epic installation record is invalid.',
      sourceName: `installations.jsonl:${line}`,
    })
  }
  // The first nonempty line is the index format version, not an installation.
  const headerIndex = lines.findIndex((line) => line.trim() !== '')
  try {
    const header: unknown = JSON.parse(lines[headerIndex] ?? '')
    z.object({ version: z.literal(1) }).parse(header)
  } catch {
    invalid(Math.max(1, headerIndex + 1))
    return { sources, errors }
  }

  for (let index = headerIndex + 1; index < lines.length; index += 1) {
    const line = lines[index]!
    if (!line.trim()) continue
    try {
      const decoded: unknown = JSON.parse(line)
      const record = installationSchema.parse(decoded)
      records.set(record.installationId.toLowerCase(), record)
    } catch {
      invalid(index + 1)
    }
  }

  for (const record of records.values()) {
    if (!record.complete || record.platform !== 'Windows') continue
    const parent = record.parentInstallationId
      ? records.get(record.parentInstallationId.toLowerCase())
      : undefined
    const manifestPath = path.win32.join(
      record.dir,
      '.egstore',
      `${record.installationId}.manifest`,
    )
    // There is no original .item file in this format. Adapt only validated fields
    // to the existing multipart contract, leaving the binary manifest untouched.
    const rawItemText = JSON.stringify({
      InstallationGuid: record.installationId,
      InstallLocation: record.dir,
      ManifestLocation: manifestPath,
      AppName: record.artifactId,
      CatalogNamespace: record.namespace,
      CatalogItemId: record.itemId,
      AppVersionString: record.version,
      DisplayName: record.artifactId,
      BuildLabel: 'Live',
      LaunchExecutable: record.launchExecutable,
      LaunchCommand: record.launchCommand,
      AppCategories: record.parentInstallationId ? ['addons'] : ['games'],
      MainGameCatalogNamespace: parent?.namespace ?? '',
      MainGameCatalogItemId: parent?.itemId ?? '',
      MainGameAppName: parent?.artifactId ?? '',
    })
    sources.push({
      sourceName: `${record.installationId}.manifest`,
      itemPath,
      rawItemText,
      parsed: parseLocalItem(rawItemText),
      exactBinary: true,
    })
  }
  return { sources, errors }
}
