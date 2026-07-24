import { mkdir, readFile, rename, rm, writeFile } from 'node:fs/promises'
import { dirname } from 'node:path'

import type { TokenPersistenceAdapter } from '../auth/token-persistence'

export class TokenStorage implements TokenPersistenceAdapter {
  readonly #filePath: string

  constructor(filePath: string) {
    this.#filePath = filePath
  }

  async save(encryptedTokenEnvelope: string): Promise<void> {
    await mkdir(dirname(this.#filePath), { recursive: true })
    const temporaryPath = `${this.#filePath}.${process.pid}.tmp`
    await writeFile(temporaryPath, encryptedTokenEnvelope, { encoding: 'utf8', mode: 0o600 })
    await rename(temporaryPath, this.#filePath)
  }

  async load(): Promise<string | null> {
    try {
      const value = await readFile(this.#filePath, 'utf8')
      return value.trim() || null
    } catch {
      return null
    }
  }

  async clear(): Promise<void> {
    await rm(this.#filePath, { force: true })
  }
}
