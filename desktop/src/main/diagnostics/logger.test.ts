import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'

import { afterEach, describe, expect, it } from 'vitest'

import { DiagnosticLogger } from './logger'

const directories: string[] = []

afterEach(async () => {
  await Promise.all(
    directories.splice(0).map((directory) => rm(directory, { recursive: true, force: true })),
  )
})

describe('DiagnosticLogger', () => {
  it('retains bounded operational metadata while redacting sensitive upload context', async () => {
    const directory = await mkdtemp(join(tmpdir(), 'egdata-diagnostics-'))
    directories.push(directory)
    const logger = new DiagnosticLogger(join(directory, 'egdata.log'))

    await logger.error('uploads', 'Cloud manifest upload failed', {
      manifestBytes: 1024,
      contentHash: 'e3b0c44298fc1c149afbf4c8996fb924',
      statusCode: 503,
      errorCode: 'UPLOAD_REJECTED',
      signature: 'secret',
      authorization: 'Bearer secret-token',
    })

    expect(logger.recentEntries()).toHaveLength(1)
    expect(logger.recentEntries()[0]).toMatchObject({
      level: 'error',
      scope: 'uploads',
      context: {
        manifestBytes: 1024,
        contentHash: 'e3b0c44298fc1c149afbf4c8996fb924',
        statusCode: 503,
        errorCode: 'UPLOAD_REJECTED',
        signature: '[REDACTED]',
        authorization: '[REDACTED]',
      },
    })
  })

  it('keeps logging non-fatal and reports a diagnostic write failure', async () => {
    const directory = await mkdtemp(join(tmpdir(), 'egdata-diagnostics-'))
    directories.push(directory)
    const blockedDirectory = join(directory, 'blocked')
    await writeFile(blockedDirectory, '')
    const logger = new DiagnosticLogger(join(blockedDirectory, 'egdata.log'))

    await expect(
      logger.warn('uploads', 'Unable to persist diagnostic entry'),
    ).resolves.toBeUndefined()

    expect(logger.health()).toMatchObject({
      pendingEntries: 0,
      droppedEntries: 0,
      writeFailures: 1,
    })
    expect(logger.health().lastWriteError).not.toBeNull()
  })

  it('bounds pending entries and retains higher-severity diagnostics', async () => {
    const directory = await mkdtemp(join(tmpdir(), 'egdata-diagnostics-'))
    directories.push(directory)
    const logPath = join(directory, 'egdata.log')
    const logger = new DiagnosticLogger(logPath, { maxPendingEntries: 2 })

    const writes = [
      logger.debug('test', 'debug entry'),
      logger.info('test', 'info entry'),
      logger.debug('test', 'dropped debug entry'),
      logger.error('test', 'retained error entry'),
    ]
    await Promise.all(writes)

    expect(logger.health()).toMatchObject({
      pendingEntries: 0,
      droppedEntries: 2,
      writeFailures: 0,
    })
    const lines = (await readFile(logPath, 'utf8')).trim().split('\n')
    expect(lines).toHaveLength(2)
    expect(lines.join('\n')).toContain('"message":"info entry"')
    expect(lines.join('\n')).toContain('"message":"retained error entry"')
  })
})
