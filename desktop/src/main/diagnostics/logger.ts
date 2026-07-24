import { mkdir, open, rename, rm, stat, type FileHandle } from 'node:fs/promises'
import { dirname } from 'node:path'

import type { DiagnosticEntry } from '../../shared'
import { DiagnosticEntrySchema } from '../../shared'
import { redactString, redactValue } from './redaction'

export interface DiagnosticLoggerOptions {
  readonly maxFileBytes?: number
  readonly maxArchives?: number
  readonly maxRecentEntries?: number
  readonly maxPendingEntries?: number
}

export interface DiagnosticLoggerHealth {
  readonly pendingEntries: number
  readonly droppedEntries: number
  readonly writeFailures: number
  readonly lastWriteError: string | null
}

interface PendingEntry {
  readonly level: DiagnosticEntry['level']
  readonly line: string
}

export class DiagnosticLogger {
  readonly #filePath: string
  readonly #maxFileBytes: number
  readonly #maxArchives: number
  readonly #maxRecentEntries: number
  readonly #maxPendingEntries: number
  readonly #recentEntries: DiagnosticEntry[] = []
  readonly #pendingEntries: PendingEntry[] = []
  #flushPromise: Promise<void> | null = null
  #directoryReady = false
  #currentFileBytes: number | null = null
  #droppedEntries = 0
  #writeFailures = 0
  #lastWriteError: string | null = null

  constructor(filePath: string, options: DiagnosticLoggerOptions = {}) {
    this.#filePath = filePath
    this.#maxFileBytes = Math.max(options.maxFileBytes ?? 1_048_576, 4_096)
    this.#maxArchives = options.maxArchives ?? 2
    this.#maxRecentEntries = options.maxRecentEntries ?? 200
    this.#maxPendingEntries = Math.max(options.maxPendingEntries ?? 1_000, 1)
  }

  debug(scope: string, message: string, context?: Record<string, unknown>): Promise<void> {
    return this.write('debug', scope, message, context)
  }

  info(scope: string, message: string, context?: Record<string, unknown>): Promise<void> {
    return this.write('info', scope, message, context)
  }

  warn(scope: string, message: string, context?: Record<string, unknown>): Promise<void> {
    return this.write('warn', scope, message, context)
  }

  error(scope: string, message: string, context?: Record<string, unknown>): Promise<void> {
    return this.write('error', scope, message, context)
  }

  write(
    level: DiagnosticEntry['level'],
    scope: string,
    message: string,
    context?: Record<string, unknown>,
  ): Promise<void> {
    const redactedContext = context ? (redactValue(context) as Record<string, unknown>) : undefined
    const rawEntry = {
      timestamp: new Date().toISOString(),
      level,
      scope: redactString(scope).slice(0, 128),
      message: redactString(message),
      ...(redactedContext ? { context: redactedContext } : {}),
    }
    const entry = DiagnosticEntrySchema.parse(
      Buffer.byteLength(JSON.stringify(rawEntry)) > this.#maxFileBytes / 2
        ? {
            timestamp: rawEntry.timestamp,
            level,
            scope: rawEntry.scope,
            message: rawEntry.message,
            context: { truncated: true },
          }
        : rawEntry,
    )
    this.#recentEntries.push(entry)
    if (this.#recentEntries.length > this.#maxRecentEntries) this.#recentEntries.shift()

    this.#enqueue({ level, line: `${JSON.stringify(entry)}\n` })
    return this.#scheduleFlush()
  }

  recentEntries(): readonly DiagnosticEntry[] {
    return structuredClone(this.#recentEntries)
  }

  health(): DiagnosticLoggerHealth {
    return {
      pendingEntries: this.#pendingEntries.length,
      droppedEntries: this.#droppedEntries,
      writeFailures: this.#writeFailures,
      lastWriteError: this.#lastWriteError,
    }
  }

  async flush(): Promise<void> {
    while (this.#flushPromise) await this.#flushPromise
  }

  #enqueue(entry: PendingEntry): void {
    if (this.#pendingEntries.length >= this.#maxPendingEntries) {
      const replaceableIndex = this.#pendingEntries.findIndex(
        (pending) => pending.level === 'debug' || pending.level === 'info',
      )
      if (replaceableIndex >= 0 && (entry.level === 'warn' || entry.level === 'error')) {
        this.#pendingEntries.splice(replaceableIndex, 1)
      } else {
        this.#droppedEntries += 1
        return
      }
      this.#droppedEntries += 1
    }
    this.#pendingEntries.push(entry)
  }

  #scheduleFlush(): Promise<void> {
    if (this.#flushPromise) return this.#flushPromise
    const scheduled = new Promise<void>((resolve) => {
      setImmediate(() => {
        void this.#drain().then(resolve, resolve)
      })
    })
    const queued = scheduled.then(() => {
      if (this.#flushPromise === queued) this.#flushPromise = null
    })
    this.#flushPromise = queued
    return queued
  }

  async #drain(): Promise<void> {
    while (this.#pendingEntries.length > 0) {
      const batch = this.#pendingEntries.splice(0)
      try {
        await this.#appendBatch(batch)
      } catch (error) {
        this.#writeFailures += 1
        this.#lastWriteError = diagnosticError(error)
        this.#currentFileBytes = null
      }
    }
  }

  async #appendBatch(entries: readonly PendingEntry[]): Promise<void> {
    if (!this.#directoryReady) {
      await mkdir(dirname(this.#filePath), { recursive: true })
      this.#directoryReady = true
    }
    this.#currentFileBytes ??= await fileSize(this.#filePath)
    let file: FileHandle | null = null
    try {
      for (const entry of entries) {
        const lineBytes = Buffer.byteLength(entry.line)
        if (this.#currentFileBytes + lineBytes > this.#maxFileBytes) {
          await file?.close()
          file = null
          await this.#rotate()
        }

        file ??= await open(this.#filePath, 'a', 0o600)
        await file.writeFile(entry.line, 'utf8')
        this.#currentFileBytes += lineBytes
      }
    } finally {
      await file?.close()
    }
  }

  async #rotate(): Promise<void> {
    if (this.#maxArchives <= 0) {
      await rm(this.#filePath, { force: true })
      this.#currentFileBytes = 0
      return
    }

    await rm(`${this.#filePath}.${this.#maxArchives}`, { force: true })
    for (let index = this.#maxArchives - 1; index >= 1; index -= 1) {
      await renameIfPresent(`${this.#filePath}.${index}`, `${this.#filePath}.${index + 1}`)
    }
    await renameIfPresent(this.#filePath, `${this.#filePath}.1`)
    this.#currentFileBytes = 0
  }
}

function diagnosticError(error: unknown): string {
  if (error instanceof Error) return redactString(`${error.name}: ${error.message}`).slice(0, 512)
  return 'Unknown diagnostic write failure'
}

async function fileSize(filePath: string): Promise<number> {
  try {
    return (await stat(filePath)).size
  } catch {
    return 0
  }
}

async function renameIfPresent(from: string, to: string): Promise<void> {
  try {
    await rename(from, to)
  } catch (error) {
    if (!(error instanceof Error && 'code' in error && error.code === 'ENOENT')) throw error
  }
}
