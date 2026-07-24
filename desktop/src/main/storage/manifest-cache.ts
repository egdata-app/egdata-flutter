import { mkdir } from 'node:fs/promises'
import { dirname } from 'node:path'
import { DatabaseSync } from 'node:sqlite'
import { randomUUID } from 'node:crypto'

import type { EpicLibraryItem, EpicPlatform } from '../cloud'
import type { QueueInput, QueueItemSnapshot, QueueRestoreInput } from '../queue'

export type ManifestConfirmation = 'uploaded' | 'already-uploaded'

export interface KnownManifest {
  contentHash: string
  serverManifestHash?: string
  confirmation: ManifestConfirmation
  firstConfirmedAt: string
  lastConfirmedAt: string
}

interface KnownManifestRow {
  content_hash: string
  server_manifest_hash: string | null
  confirmation: ManifestConfirmation
  first_confirmed_at: string
  last_confirmed_at: string
}

interface CloudLibraryRow {
  item_id: string
  app_name: string
  title: string
  catalog_item_id: string
  namespace: string
  asset_id: string
  build_version: string | null
  state: QueueRestoreInput<EpicLibraryItem>['state']
  attempts: number
  created_at: string
  started_at: string | null
  finished_at: string | null
  error: string | null
  message: string | null
}

export class ManifestCache {
  readonly #filePath: string
  #database: DatabaseSync | null = null

  constructor(filePath: string) {
    this.#filePath = filePath
  }

  get isReady(): boolean {
    return this.#database !== null
  }

  async initialize(): Promise<void> {
    if (this.#database) return
    await mkdir(dirname(this.#filePath), { recursive: true })

    const database = new DatabaseSync(this.#filePath, { timeout: 5_000 })
    try {
      database.exec(`
        PRAGMA journal_mode = WAL;
        PRAGMA synchronous = NORMAL;
        CREATE TABLE IF NOT EXISTS known_manifests (
          content_hash TEXT PRIMARY KEY NOT NULL,
          server_manifest_hash TEXT,
          confirmation TEXT NOT NULL CHECK (confirmation IN ('uploaded', 'already-uploaded')),
          first_confirmed_at TEXT NOT NULL,
          last_confirmed_at TEXT NOT NULL
        ) STRICT;
        CREATE TABLE IF NOT EXISTS cloud_library (
          account_id TEXT NOT NULL,
          platform TEXT NOT NULL CHECK (platform IN ('Windows', 'Mac')),
          item_id TEXT NOT NULL,
          app_name TEXT NOT NULL,
          title TEXT NOT NULL,
          catalog_item_id TEXT NOT NULL,
          namespace TEXT NOT NULL,
          asset_id TEXT NOT NULL,
          build_version TEXT,
          state TEXT NOT NULL CHECK (
            state IN (
              'pending', 'running', 'uploaded', 'alreadyUploaded',
              'failed', 'skipped', 'cancelled', 'removed'
            )
          ),
          attempts INTEGER NOT NULL DEFAULT 0 CHECK (attempts >= 0),
          created_at TEXT NOT NULL,
          started_at TEXT,
          finished_at TEXT,
          error TEXT,
          message TEXT,
          last_seen_generation TEXT NOT NULL,
          PRIMARY KEY (account_id, platform, item_id)
        ) STRICT;
        CREATE TABLE IF NOT EXISTS cloud_library_sync (
          account_id TEXT NOT NULL,
          platform TEXT NOT NULL CHECK (platform IN ('Windows', 'Mac')),
          last_refreshed_at TEXT NOT NULL,
          PRIMARY KEY (account_id, platform)
        ) STRICT;
        PRAGMA user_version = 2;
      `)
      this.#database = database
    } catch (error) {
      database.close()
      throw error
    }
  }

  find(contentHash: string): KnownManifest | null {
    if (!this.#database) return null
    const row = this.#database
      .prepare(
        `SELECT content_hash, server_manifest_hash, confirmation,
                first_confirmed_at, last_confirmed_at
           FROM known_manifests
          WHERE content_hash = ?`,
      )
      .get(contentHash) as KnownManifestRow | undefined

    if (!row) return null
    return {
      contentHash: row.content_hash,
      ...(row.server_manifest_hash ? { serverManifestHash: row.server_manifest_hash } : {}),
      confirmation: row.confirmation,
      firstConfirmedAt: row.first_confirmed_at,
      lastConfirmedAt: row.last_confirmed_at,
    }
  }

  confirm(
    contentHash: string,
    confirmation: ManifestConfirmation,
    serverManifestHash?: string,
  ): void {
    if (!this.#database) return
    const confirmedAt = new Date().toISOString()
    this.#database
      .prepare(
        `INSERT INTO known_manifests (
           content_hash, server_manifest_hash, confirmation,
           first_confirmed_at, last_confirmed_at
         ) VALUES (?, ?, ?, ?, ?)
         ON CONFLICT(content_hash) DO UPDATE SET
           server_manifest_hash = COALESCE(excluded.server_manifest_hash, server_manifest_hash),
           confirmation = excluded.confirmation,
           last_confirmed_at = excluded.last_confirmed_at`,
      )
      .run(contentHash, serverManifestHash ?? null, confirmation, confirmedAt, confirmedAt)
  }

  loadCloudQueue(accountId: string, platform: EpicPlatform): QueueRestoreInput<EpicLibraryItem>[] {
    if (!this.#database) return []
    const rows = this.#database
      .prepare(
        `SELECT item_id, app_name, title, catalog_item_id, namespace, asset_id,
                build_version, state, attempts, created_at, started_at,
                finished_at, error, message
           FROM cloud_library
          WHERE account_id = ? AND platform = ? AND state <> 'removed'
          ORDER BY title COLLATE NOCASE, item_id`,
      )
      .all(accountId, platform) as unknown as CloudLibraryRow[]

    return rows.map((row) => ({
      id: row.item_id,
      title: row.title || row.app_name,
      value: {
        appName: row.app_name,
        title: row.title,
        catalogItemId: row.catalog_item_id,
        namespace: row.namespace,
        assetId: row.asset_id,
        buildVersion: row.build_version,
      },
      state: row.state,
      attempts: row.attempts,
      createdAt: row.created_at,
      startedAt: row.started_at,
      finishedAt: row.finished_at,
      error: row.error,
      message: row.message,
    }))
  }

  hasCloudLibrarySnapshot(accountId: string, platform: EpicPlatform): boolean {
    if (!this.#database) return false
    return Boolean(
      this.#database
        .prepare(
          `SELECT 1
             FROM cloud_library_sync
            WHERE account_id = ? AND platform = ?`,
        )
        .get(accountId, platform),
    )
  }

  reconcileCloudLibrary(
    accountId: string,
    platform: EpicPlatform,
    items: ReadonlyArray<QueueInput<EpicLibraryItem>>,
  ): QueueRestoreInput<EpicLibraryItem>[] {
    if (!this.#database) return []
    const generation = randomUUID()
    const refreshedAt = new Date().toISOString()
    const upsert = this.#database.prepare(
      `INSERT INTO cloud_library (
         account_id, platform, item_id, app_name, title, catalog_item_id,
         namespace, asset_id, build_version, state, attempts, created_at,
         started_at, finished_at, error, message, last_seen_generation
       ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', 0, ?, NULL, NULL, NULL, NULL, ?)
       ON CONFLICT(account_id, platform, item_id) DO UPDATE SET
         app_name = excluded.app_name,
         title = excluded.title,
         catalog_item_id = excluded.catalog_item_id,
         namespace = excluded.namespace,
          asset_id = excluded.asset_id,
          state = CASE
            WHEN cloud_library.state = 'removed' THEN 'removed'
            WHEN cloud_library.build_version IS NOT excluded.build_version THEN 'pending'
            ELSE cloud_library.state
          END,
          attempts = CASE
            WHEN cloud_library.state = 'removed' THEN cloud_library.attempts
            WHEN cloud_library.build_version IS NOT excluded.build_version THEN 0
            ELSE cloud_library.attempts
          END,
          started_at = CASE
            WHEN cloud_library.state = 'removed' THEN cloud_library.started_at
            WHEN cloud_library.build_version IS NOT excluded.build_version THEN NULL
            ELSE cloud_library.started_at
          END,
          finished_at = CASE
            WHEN cloud_library.state = 'removed' THEN cloud_library.finished_at
            WHEN cloud_library.build_version IS NOT excluded.build_version THEN NULL
            ELSE cloud_library.finished_at
          END,
          error = CASE
            WHEN cloud_library.state = 'removed' THEN cloud_library.error
            WHEN cloud_library.build_version IS NOT excluded.build_version THEN NULL
            ELSE cloud_library.error
          END,
          message = CASE
            WHEN cloud_library.state = 'removed' THEN cloud_library.message
            WHEN cloud_library.build_version IS NOT excluded.build_version THEN NULL
            ELSE cloud_library.message
         END,
         build_version = excluded.build_version,
         last_seen_generation = excluded.last_seen_generation`,
    )

    this.#database.exec('BEGIN IMMEDIATE')
    try {
      for (const input of items) {
        upsert.run(
          accountId,
          platform,
          input.id,
          input.value.appName,
          input.value.title,
          input.value.catalogItemId,
          input.value.namespace,
          input.value.assetId,
          input.value.buildVersion,
          refreshedAt,
          generation,
        )
      }
      this.#database
        .prepare(
          `DELETE FROM cloud_library
            WHERE account_id = ? AND platform = ? AND last_seen_generation <> ?`,
        )
        .run(accountId, platform, generation)
      this.#database
        .prepare(
          `INSERT INTO cloud_library_sync (account_id, platform, last_refreshed_at)
           VALUES (?, ?, ?)
           ON CONFLICT(account_id, platform) DO UPDATE SET
             last_refreshed_at = excluded.last_refreshed_at`,
        )
        .run(accountId, platform, refreshedAt)
      this.#database.exec('COMMIT')
    } catch (error) {
      this.#database.exec('ROLLBACK')
      throw error
    }
    return this.loadCloudQueue(accountId, platform)
  }

  saveCloudQueueItems(
    accountId: string,
    platform: EpicPlatform,
    items: ReadonlyArray<QueueItemSnapshot<EpicLibraryItem>>,
  ): void {
    if (!this.#database) return
    const update = this.#database.prepare(
      `UPDATE cloud_library
          SET state = ?, attempts = ?, started_at = ?, finished_at = ?, error = ?, message = ?
        WHERE account_id = ? AND platform = ? AND item_id = ?`,
    )
    this.#database.exec('BEGIN IMMEDIATE')
    try {
      for (const item of items) {
        update.run(
          item.state,
          item.attempts,
          item.startedAt,
          item.finishedAt,
          item.error,
          item.message,
          accountId,
          platform,
          item.id,
        )
      }
      this.#database.exec('COMMIT')
    } catch (error) {
      this.#database.exec('ROLLBACK')
      throw error
    }
  }

  updateCloudBuildVersion(
    accountId: string,
    platform: EpicPlatform,
    itemId: string,
    buildVersion: string,
  ): void {
    if (!this.#database) return
    this.#database
      .prepare(
        `UPDATE cloud_library
            SET build_version = ?
          WHERE account_id = ? AND platform = ? AND item_id = ?`,
      )
      .run(buildVersion, accountId, platform, itemId)
  }

  close(): void {
    this.#database?.close()
    this.#database = null
  }
}
