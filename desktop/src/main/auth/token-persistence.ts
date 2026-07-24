export interface TokenPersistenceAdapter {
  load(): Promise<string | null>
  save(encryptedTokenEnvelope: string): Promise<void>
  clear(): Promise<void>
}

export interface TokenCipher {
  encrypt(plainText: string): string
  decrypt(cipherText: string): string
}

export interface SafeStorageLike {
  isEncryptionAvailable(): boolean
  encryptString(plainText: string): Uint8Array
  decryptString(cipherText: Uint8Array): string
}

export class SafeStorageTokenCipher implements TokenCipher {
  constructor(private readonly safeStorage: SafeStorageLike) {}

  encrypt(plainText: string): string {
    if (!this.safeStorage.isEncryptionAvailable()) {
      throw new EpicTokenStorageError()
    }
    return Buffer.from(this.safeStorage.encryptString(plainText)).toString('base64')
  }

  decrypt(cipherText: string): string {
    if (!this.safeStorage.isEncryptionAvailable()) {
      throw new EpicTokenStorageError()
    }
    try {
      return this.safeStorage.decryptString(Buffer.from(cipherText, 'base64'))
    } catch (error) {
      throw new EpicTokenStorageError({ cause: error })
    }
  }
}

export class EpicTokenStorageError extends Error {
  readonly code = 'EPIC_TOKEN_STORAGE_FAILED'

  constructor(options?: ErrorOptions) {
    super('Secure Epic session storage is unavailable.', options)
    this.name = 'EpicTokenStorageError'
  }
}
