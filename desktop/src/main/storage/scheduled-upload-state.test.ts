import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'

import { afterEach, describe, expect, it } from 'vitest'

import {
  EMPTY_SCHEDULED_UPLOAD_STATE,
  parseScheduledUploadState,
  ScheduledUploadStateStorage,
} from './scheduled-upload-state'

const temporaryDirectories: string[] = []

afterEach(async () => {
  await Promise.all(
    temporaryDirectories.splice(0).map((directory) => rm(directory, { recursive: true })),
  )
})

describe('scheduled upload state storage', () => {
  it('falls back safely for malformed state', () => {
    expect(parseScheduledUploadState(null)).toEqual(EMPTY_SCHEDULED_UPLOAD_STATE)
    expect(parseScheduledUploadState({ version: 2 })).toEqual(EMPTY_SCHEDULED_UPLOAD_STATE)
    expect(
      parseScheduledUploadState({ version: 1, lastAttemptAt: { local: 'not-a-date' } }),
    ).toEqual(EMPTY_SCHEDULED_UPLOAD_STATE)
  })

  it('persists source attempts atomically without dropping the other source', async () => {
    const directory = await mkdtemp(join(tmpdir(), 'egdata-scheduled-state-'))
    temporaryDirectories.push(directory)
    const filePath = join(directory, 'scheduled-uploads.v1.json')
    const storage = new ScheduledUploadStateStorage(filePath)

    await storage.recordAttempt('local', '2026-07-21T08:00:00.000Z')
    await storage.recordAttempt('cloud', '2026-07-21T09:00:00.000Z')

    expect(JSON.parse(await readFile(filePath, 'utf8'))).toEqual({
      version: 1,
      lastAttemptAt: {
        local: '2026-07-21T08:00:00.000Z',
        cloud: '2026-07-21T09:00:00.000Z',
      },
    })
  })

  it('recovers from an unreadable document', async () => {
    const directory = await mkdtemp(join(tmpdir(), 'egdata-scheduled-state-'))
    temporaryDirectories.push(directory)
    const filePath = join(directory, 'scheduled-uploads.v1.json')
    await writeFile(filePath, '{broken', 'utf8')

    expect(await new ScheduledUploadStateStorage(filePath).load()).toEqual(
      EMPTY_SCHEDULED_UPLOAD_STATE,
    )
  })
})
