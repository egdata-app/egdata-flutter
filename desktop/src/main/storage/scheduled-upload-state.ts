import { mkdir, readFile, rename, writeFile } from 'node:fs/promises'
import { dirname } from 'node:path'

import { z } from 'zod'

const timestampSchema = z.string().datetime({ offset: true })

const ScheduledUploadStateSchema = z.object({
  version: z.literal(1),
  lastAttemptAt: z.object({
    local: timestampSchema.optional(),
    cloud: timestampSchema.optional(),
  }),
})

export type ScheduledUploadSource = 'local' | 'cloud'
export type ScheduledUploadState = z.infer<typeof ScheduledUploadStateSchema>

export const EMPTY_SCHEDULED_UPLOAD_STATE: ScheduledUploadState = {
  version: 1,
  lastAttemptAt: {},
}

export function parseScheduledUploadState(value: unknown): ScheduledUploadState {
  const parsed = ScheduledUploadStateSchema.safeParse(value)
  return parsed.success ? parsed.data : structuredClone(EMPTY_SCHEDULED_UPLOAD_STATE)
}

export class ScheduledUploadStateStorage {
  readonly #filePath: string
  #state: ScheduledUploadState = structuredClone(EMPTY_SCHEDULED_UPLOAD_STATE)
  #loaded = false

  constructor(filePath: string) {
    this.#filePath = filePath
  }

  async load(): Promise<ScheduledUploadState> {
    if (!this.#loaded) {
      try {
        this.#state = parseScheduledUploadState(JSON.parse(await readFile(this.#filePath, 'utf8')))
      } catch {
        this.#state = structuredClone(EMPTY_SCHEDULED_UPLOAD_STATE)
      }
      this.#loaded = true
    }
    return structuredClone(this.#state)
  }

  async recordAttempt(source: ScheduledUploadSource, attemptedAt: string): Promise<void> {
    await this.load()
    this.#state = ScheduledUploadStateSchema.parse({
      ...this.#state,
      lastAttemptAt: {
        ...this.#state.lastAttemptAt,
        [source]: attemptedAt,
      },
    })
    await this.#persist()
  }

  async #persist(): Promise<void> {
    await mkdir(dirname(this.#filePath), { recursive: true })
    const temporaryPath = `${this.#filePath}.${process.pid}.tmp`
    await writeFile(temporaryPath, `${JSON.stringify(this.#state, null, 2)}\n`, {
      encoding: 'utf8',
      mode: 0o600,
    })
    await rename(temporaryPath, this.#filePath)
  }
}
