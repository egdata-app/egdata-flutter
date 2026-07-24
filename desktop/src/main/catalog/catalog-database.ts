import { mkdirSync, rmSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { DatabaseSync } from 'node:sqlite'

import {
  applyCatalogHydrationRoot,
  catalogCounts,
  deferCatalogHydrationIdentifiers,
  hydrationRequest,
  lastCatalogSync,
  listInterestedIdentifiers,
  reconcileInterestScope,
  removeInterestScope,
} from './database-hydration'
import {
  getCatalogDetails,
  getCatalogLibraryMetadata,
  resolveCatalogDisplayName,
  resolveCatalogLauncherCandidate,
  searchCatalog,
} from './database-read'
import { initializeCatalogSchema } from './database-schema'
import type {
  CatalogCounts,
  CatalogDetails,
  CatalogDetailsRequest,
  CatalogHydrationApplyResult,
  CatalogHydrationIdentifier,
  CatalogHydrationRequest,
  CatalogInterestScopeKind,
  CatalogLauncherCandidateInput,
  CatalogLauncherResolution,
  CatalogLibraryMetadata,
  CatalogNameResolution,
  CatalogNameResolutionInput,
  CatalogSearchPage,
  CatalogSearchRequest,
  CatalogTaxonomySnapshot,
  CatalogTaxonomyTag,
} from './types'
import { catalogHydrationRootKey, parseCatalogHydrationRootResult } from './validation'

export interface CatalogDatabaseState {
  counts: CatalogCounts
  lastSyncedAt: string | null
}

export class CatalogDatabase {
  readonly #filePath: string
  #database: DatabaseSync | null = null

  constructor(filePath: string) {
    this.#filePath = filePath
  }

  initialize(): Promise<void> {
    mkdirSync(dirname(this.#filePath), { recursive: true })
    const database = new DatabaseSync(this.#filePath)
    try {
      initializeCatalogSchema(database)
      database.exec(
        `INSERT INTO catalog_fts(document_id, offer_title) VALUES ('__verify__', 'verify'); DELETE FROM catalog_fts WHERE document_id='__verify__';`,
      )
      this.#database = database
    } catch (error) {
      database.close()
      throw error
    }
    const legacyBase = join(dirname(this.#filePath), 'catalog.v1.sqlite')
    if (legacyBase !== this.#filePath) {
      for (const legacyPath of [legacyBase, `${legacyBase}-wal`, `${legacyBase}-shm`]) {
        try {
          rmSync(legacyPath, { force: true })
        } catch {
          /* v2 remains usable if cleanup is denied */
        }
      }
    }
    return Promise.resolve()
  }

  getState(): CatalogDatabaseState {
    const database = this.#requiredDatabase()
    return { counts: catalogCounts(database), lastSyncedAt: lastCatalogSync(database) }
  }

  applyHydrationRoot(value: unknown): CatalogHydrationApplyResult {
    return applyCatalogHydrationRoot(
      this.#requiredDatabase(),
      parseCatalogHydrationRootResult(value),
    )
  }

  reconcileScope(
    scopeKey: string,
    kind: CatalogInterestScopeKind,
    identifiers: readonly CatalogHydrationIdentifier[],
    reconciledAt?: string,
  ): CatalogHydrationIdentifier[] {
    return reconcileInterestScope(
      this.#requiredDatabase(),
      scopeKey,
      kind,
      identifiers,
      reconciledAt,
    )
  }

  removeScope(scopeKey: string): void {
    removeInterestScope(this.#requiredDatabase(), scopeKey)
  }

  getHydrationRequest(identifiers: readonly CatalogHydrationIdentifier[]): CatalogHydrationRequest {
    return hydrationRequest(this.#requiredDatabase(), identifiers)
  }

  listHydrationIdentifiers(olderThan?: string, retryBefore?: string): CatalogHydrationIdentifier[] {
    return listInterestedIdentifiers(this.#requiredDatabase(), olderThan, retryBefore)
  }

  deferHydrationIdentifiers(
    identifiers: readonly CatalogHydrationIdentifier[],
    retryAt: string,
    errorCode: string,
  ): void {
    deferCatalogHydrationIdentifiers(this.#requiredDatabase(), identifiers, retryAt, errorCode)
  }

  filterInterestedIdentifiers(
    identifiers: readonly CatalogHydrationIdentifier[],
    olderThan: string,
    retryBefore: string,
  ): CatalogHydrationIdentifier[] {
    const database = this.#requiredDatabase()
    const query = database.prepare(
      `SELECT 1 FROM catalog_roots r JOIN catalog_interests i ON i.root_key=r.root_key
       WHERE r.root_key=? AND (
         r.sync_state = 'pending'
         OR (r.sync_state = 'error' AND (r.retry_at IS NULL OR r.retry_at <= ?))
         OR (r.sync_state IN ('resolved', 'not-found')
           AND (r.last_synced_at IS NULL OR r.last_synced_at < ?))
       ) LIMIT 1`,
    )
    return identifiers.filter((identifier) =>
      query.get(catalogHydrationRootKey(identifier), retryBefore, olderThan),
    )
  }

  listIdentifiersForDetails(
    request: CatalogDetailsRequest,
    olderThan: string,
    retryBefore: string,
  ): CatalogHydrationIdentifier[] {
    const database = this.#requiredDatabase()
    const table = request.kind === 'offer' ? 'catalog_offers' : 'catalog_items'
    const rows = database
      .prepare(
        `SELECT DISTINCT r.identifier_json FROM ${table} entity
       JOIN catalog_root_records rr ON rr.record_key=entity.record_key
       JOIN catalog_roots r ON r.root_key=rr.root_key
       JOIN catalog_interests interest ON interest.root_key=r.root_key
       WHERE entity.namespace=? AND entity.id=?
        AND (
          r.sync_state = 'pending'
          OR (r.sync_state = 'error' AND (r.retry_at IS NULL OR r.retry_at <= ?))
          OR (r.sync_state IN ('resolved', 'not-found')
            AND (r.last_synced_at IS NULL OR r.last_synced_at < ?))
        )
       LIMIT 100`,
      )
      .all(request.namespace, request.id, retryBefore, olderThan) as unknown as Array<{
      identifier_json: string
    }>
    return rows.map((row) => JSON.parse(row.identifier_json) as CatalogHydrationIdentifier)
  }

  search(request: CatalogSearchRequest): CatalogSearchPage {
    return searchCatalog(this.#requiredDatabase(), request)
  }

  getDetails(request: CatalogDetailsRequest): CatalogDetails | null {
    return getCatalogDetails(this.#requiredDatabase(), request)
  }

  getLibraryMetadata(input: CatalogNameResolutionInput): CatalogLibraryMetadata | null {
    return getCatalogLibraryMetadata(this.#requiredDatabase(), input)
  }

  getTaxonomy(): CatalogTaxonomySnapshot {
    const database = this.#requiredDatabase()
    const rows = database
      .prepare(
        'SELECT id, name, group_name, status FROM catalog_tag_taxonomy ORDER BY name COLLATE NOCASE, id',
      )
      .all() as unknown as Array<{
      id: string
      name: string
      group_name: CatalogTaxonomyTag['groupName']
      status: string
    }>
    const updated = database
      .prepare("SELECT value FROM catalog_meta WHERE key='taxonomy_updated_at'")
      .get() as { value: string } | undefined
    return {
      tags: rows.map((row) => ({
        id: row.id,
        name: row.name,
        groupName: row.group_name,
        status: row.status,
      })),
      updatedAt: updated?.value ?? null,
    }
  }

  replaceTaxonomy(tags: readonly CatalogTaxonomyTag[], updatedAt: string): void {
    const database = this.#requiredDatabase()
    database.exec('BEGIN IMMEDIATE')
    try {
      database.exec('DELETE FROM catalog_tag_taxonomy')
      const insert = database.prepare(
        'INSERT INTO catalog_tag_taxonomy(id, name, group_name, status) VALUES (?, ?, ?, ?)',
      )
      for (const tag of tags) insert.run(tag.id, tag.name, tag.groupName, tag.status)
      database
        .prepare(
          "INSERT INTO catalog_meta(key, value) VALUES ('taxonomy_updated_at', ?) ON CONFLICT(key) DO UPDATE SET value=excluded.value",
        )
        .run(updatedAt)
      database.exec('COMMIT')
    } catch (error) {
      database.exec('ROLLBACK')
      throw error
    }
  }

  resolveDisplayName(input: CatalogNameResolutionInput): CatalogNameResolution | null {
    return resolveCatalogDisplayName(this.#requiredDatabase(), input)
  }

  resolveLauncherCandidate(input: CatalogLauncherCandidateInput): CatalogLauncherResolution | null {
    return resolveCatalogLauncherCandidate(this.#requiredDatabase(), input)
  }

  close(): void {
    this.#database?.close()
    this.#database = null
  }

  #requiredDatabase(): DatabaseSync {
    if (!this.#database) throw new Error('The catalog database is not initialized.')
    return this.#database
  }
}
