import type { CatalogSearchResultKind } from './types'

export interface OfferRow {
  namespace: string
  id: string
  title: string
  description: string
  long_description: string
  offer_type: string | null
  developer: string | null
  publisher: string | null
  image_url: string | null
  product_slug: string | null
  url_slug: string | null
  raw_json: string
}

export interface ItemRow {
  namespace: string
  id: string
  title: string
  description: string
  long_description: string
  technical_details: string
  primary_offer_namespace: string | null
  primary_offer_id: string | null
  raw_json: string
}

export interface AssetRow {
  namespace: string
  artifact_id: string
  platform: string
  item_namespace: string
  item_id: string
  raw_json: string
}

export interface ReleaseAppRow {
  namespace: string
  app_id: string
  platform: string
  item_namespace: string
  item_id: string
  raw_json: string
}

export interface OfferItemRow {
  offer_namespace: string
  offer_id: string
  item_namespace: string
  item_id: string
  sources_json: string
  is_primary: number
}

export interface SearchDocumentRow {
  kind: CatalogSearchResultKind
  namespace: string
  id: string
  title: string
  description: string
  offer_type: string | null
  developer: string | null
  publisher: string | null
  image_url: string | null
  platforms_json: string
  item_count: number
}
