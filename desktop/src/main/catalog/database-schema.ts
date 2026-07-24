import { DatabaseSync } from 'node:sqlite'

const DATABASE_VERSION = 3

export function initializeCatalogSchema(database: DatabaseSync): void {
  database.exec(`
    PRAGMA journal_mode = WAL;
    PRAGMA synchronous = NORMAL;
    PRAGMA foreign_keys = ON;
    CREATE TABLE IF NOT EXISTS catalog_meta (
      key TEXT PRIMARY KEY NOT NULL,
      value TEXT NOT NULL
    ) STRICT;
    CREATE TABLE IF NOT EXISTS catalog_tag_taxonomy (
      id TEXT PRIMARY KEY NOT NULL,
      name TEXT NOT NULL,
      group_name TEXT NOT NULL CHECK (group_name IN ('genre', 'feature', 'epicfeature', 'platform', 'subscription')),
      status TEXT NOT NULL
    ) STRICT;
    CREATE TABLE IF NOT EXISTS catalog_roots (
      root_key TEXT PRIMARY KEY NOT NULL,
      identifier_json TEXT NOT NULL,
      graph_hash TEXT,
      sync_state TEXT NOT NULL CHECK (sync_state IN ('pending', 'resolved', 'not-found', 'error')),
      last_synced_at TEXT,
      retry_at TEXT,
      last_error_code TEXT
    ) STRICT;
    CREATE TABLE IF NOT EXISTS catalog_interest_scopes (
      scope_key TEXT PRIMARY KEY NOT NULL,
      kind TEXT NOT NULL CHECK (kind IN ('local-default', 'local-selected', 'cloud-account', 'library-tools')),
      reconciled_at TEXT NOT NULL
    ) STRICT;
    CREATE TABLE IF NOT EXISTS catalog_interests (
      scope_key TEXT NOT NULL REFERENCES catalog_interest_scopes(scope_key) ON DELETE CASCADE,
      root_key TEXT NOT NULL REFERENCES catalog_roots(root_key) ON DELETE CASCADE,
      PRIMARY KEY (scope_key, root_key)
    ) STRICT;
    CREATE TABLE IF NOT EXISTS catalog_records (
      record_key TEXT PRIMARY KEY NOT NULL,
      record_type TEXT NOT NULL CHECK (record_type IN ('offer', 'item', 'asset', 'release-app', 'offer-item')),
      sha256 TEXT NOT NULL,
      raw_json TEXT NOT NULL,
      updated_at TEXT NOT NULL
    ) STRICT;
    CREATE TABLE IF NOT EXISTS catalog_root_records (
      root_key TEXT NOT NULL REFERENCES catalog_roots(root_key) ON DELETE CASCADE,
      record_key TEXT NOT NULL REFERENCES catalog_records(record_key) ON DELETE CASCADE,
      PRIMARY KEY (root_key, record_key)
    ) STRICT;
    CREATE TABLE IF NOT EXISTS catalog_offers (
      record_key TEXT PRIMARY KEY NOT NULL REFERENCES catalog_records(record_key) ON DELETE CASCADE,
      namespace TEXT NOT NULL,
      id TEXT NOT NULL,
      title TEXT NOT NULL,
      description TEXT NOT NULL,
      long_description TEXT NOT NULL,
      offer_type TEXT,
      developer TEXT,
      publisher TEXT,
      image_url TEXT,
      product_slug TEXT,
      url_slug TEXT,
      raw_json TEXT NOT NULL,
      UNIQUE (namespace, id)
    ) STRICT;
    CREATE TABLE IF NOT EXISTS catalog_items (
      record_key TEXT PRIMARY KEY NOT NULL REFERENCES catalog_records(record_key) ON DELETE CASCADE,
      namespace TEXT NOT NULL,
      id TEXT NOT NULL,
      title TEXT NOT NULL,
      description TEXT NOT NULL,
      long_description TEXT NOT NULL,
      technical_details TEXT NOT NULL,
      primary_offer_namespace TEXT,
      primary_offer_id TEXT,
      raw_json TEXT NOT NULL,
      UNIQUE (namespace, id)
    ) STRICT;
    CREATE TABLE IF NOT EXISTS catalog_assets (
      record_key TEXT PRIMARY KEY NOT NULL REFERENCES catalog_records(record_key) ON DELETE CASCADE,
      namespace TEXT NOT NULL,
      artifact_id TEXT NOT NULL,
      platform TEXT NOT NULL,
      item_namespace TEXT NOT NULL,
      item_id TEXT NOT NULL,
      raw_json TEXT NOT NULL,
      UNIQUE (namespace, artifact_id, platform, item_namespace, item_id)
    ) STRICT;
    CREATE TABLE IF NOT EXISTS catalog_release_apps (
      record_key TEXT PRIMARY KEY NOT NULL REFERENCES catalog_records(record_key) ON DELETE CASCADE,
      namespace TEXT NOT NULL,
      app_id TEXT NOT NULL,
      platform TEXT NOT NULL,
      item_namespace TEXT NOT NULL,
      item_id TEXT NOT NULL,
      raw_json TEXT NOT NULL,
      UNIQUE (namespace, app_id, platform, item_namespace, item_id)
    ) STRICT;
    CREATE TABLE IF NOT EXISTS catalog_offer_items (
      record_key TEXT PRIMARY KEY NOT NULL REFERENCES catalog_records(record_key) ON DELETE CASCADE,
      offer_namespace TEXT NOT NULL,
      offer_id TEXT NOT NULL,
      item_namespace TEXT NOT NULL,
      item_id TEXT NOT NULL,
      sources_json TEXT NOT NULL,
      is_primary INTEGER NOT NULL CHECK (is_primary IN (0, 1)),
      UNIQUE (offer_namespace, offer_id, item_namespace, item_id)
    ) STRICT;
    CREATE TABLE IF NOT EXISTS catalog_search_documents (
      document_id TEXT PRIMARY KEY NOT NULL,
      kind TEXT NOT NULL CHECK (kind IN ('offer', 'orphan-item')),
      namespace TEXT NOT NULL,
      id TEXT NOT NULL,
      title TEXT NOT NULL,
      description TEXT NOT NULL,
      offer_type TEXT,
      developer TEXT,
      publisher TEXT,
      image_url TEXT,
      platforms_json TEXT NOT NULL,
      platforms_search TEXT NOT NULL,
      item_count INTEGER NOT NULL,
      UNIQUE (kind, namespace, id)
    ) STRICT;
    CREATE TABLE IF NOT EXISTS catalog_identifiers (
      target_kind TEXT NOT NULL CHECK (target_kind IN ('offer', 'orphan-item')),
      target_namespace TEXT NOT NULL,
      target_id TEXT NOT NULL,
      identifier TEXT NOT NULL,
      identifier_lower TEXT NOT NULL,
      field TEXT NOT NULL,
      priority INTEGER NOT NULL,
      PRIMARY KEY (target_kind, target_namespace, target_id, identifier_lower, field)
    ) STRICT;
    CREATE VIRTUAL TABLE IF NOT EXISTS catalog_fts USING fts5(
      document_id UNINDEXED,
      offer_title,
      parties,
      item_titles,
      descriptions,
      technical_details,
      custom_attributes,
      identifiers,
      slugs,
      tokenize = 'unicode61 remove_diacritics 2'
    );
    CREATE INDEX IF NOT EXISTS catalog_roots_stale ON catalog_roots (last_synced_at, sync_state);
    CREATE INDEX IF NOT EXISTS catalog_interests_root ON catalog_interests (root_key);
    CREATE INDEX IF NOT EXISTS catalog_root_records_record ON catalog_root_records (record_key);
    CREATE INDEX IF NOT EXISTS catalog_assets_lookup ON catalog_assets (artifact_id COLLATE NOCASE, platform COLLATE NOCASE);
    CREATE INDEX IF NOT EXISTS catalog_release_apps_lookup ON catalog_release_apps (app_id COLLATE NOCASE, platform COLLATE NOCASE);
    CREATE INDEX IF NOT EXISTS catalog_offer_items_item ON catalog_offer_items (item_namespace, item_id, is_primary DESC);
    CREATE INDEX IF NOT EXISTS catalog_identifiers_lookup ON catalog_identifiers (identifier_lower, priority);
    CREATE INDEX IF NOT EXISTS catalog_search_browse ON catalog_search_documents (title COLLATE NOCASE, namespace, id);
  `)
  const version = database.prepare('PRAGMA user_version').get() as
    | { user_version: number }
    | undefined
  if (version && version.user_version > DATABASE_VERSION) {
    throw new Error('The catalog database was created by a newer app version.')
  }
  database.exec(`PRAGMA user_version = ${DATABASE_VERSION}`)
}
