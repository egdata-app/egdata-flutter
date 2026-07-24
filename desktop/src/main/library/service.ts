import type {
  LibraryDetails,
  LibraryPage,
  LibraryQueryRequest,
  LibraryStatus,
  LocalManifest,
} from '../../shared/contracts'
import type { CatalogLibraryMetadata, CatalogTaxonomySnapshot } from '../catalog'
import type { EpicLibraryItem } from '../cloud'
import {
  buildLibraryProjection,
  queryLibraryProjection,
  type LibraryProjection,
} from './projection'

export interface LibraryServiceOptions {
  resolveMetadata: (input: {
    namespace?: string
    catalogItemId?: string
    artifactId?: string
    appName?: string
    platform?: string
  }) => CatalogLibraryMetadata | null
  getTaxonomy: () => CatalogTaxonomySnapshot
}

export class LibraryService {
  readonly #resolveMetadata: LibraryServiceOptions['resolveMetadata']
  readonly #getTaxonomy: LibraryServiceOptions['getTaxonomy']
  #owned: readonly EpicLibraryItem[] = []
  #local: readonly LocalManifest[] = []
  #signedIn = false
  #localScanState: LibraryStatus['localScanState'] = 'idle'
  #refreshing = false
  #lastRefreshedAt: string | null = null
  #warnings: string[] = []
  #projection: LibraryProjection | null = null

  constructor(options: LibraryServiceOptions) {
    this.#resolveMetadata = options.resolveMetadata
    this.#getTaxonomy = options.getTaxonomy
  }

  setSources(options: {
    owned: readonly EpicLibraryItem[]
    local: readonly LocalManifest[]
    signedIn: boolean
    localScanState: LibraryStatus['localScanState']
  }): void {
    this.#owned = options.owned
    this.#local = options.local
    this.#signedIn = options.signedIn
    this.#localScanState = options.localScanState
    this.invalidate()
  }

  setRefreshing(refreshing: boolean): void {
    this.#refreshing = refreshing
    this.invalidate()
  }

  markRefreshed(warnings: readonly string[]): void {
    this.#refreshing = false
    this.#lastRefreshedAt = new Date().toISOString()
    this.#warnings = [...warnings].slice(0, 20)
    this.invalidate()
  }

  invalidate(): void {
    this.#projection = null
  }

  getStatus(): LibraryStatus {
    return { ...this.#current().status, warnings: [...this.#current().status.warnings] }
  }

  query(request: LibraryQueryRequest): LibraryPage {
    return queryLibraryProjection(this.#current(), request)
  }

  getDetails(id: string): LibraryDetails | null {
    return this.#current().details.get(id) ?? null
  }

  #current(): LibraryProjection {
    this.#projection ??= buildLibraryProjection({
      owned: this.#signedIn ? this.#owned : [],
      local: this.#local,
      taxonomy: this.#getTaxonomy(),
      resolveMetadata: this.#resolveMetadata,
      signedIn: this.#signedIn,
      localScanState: this.#localScanState,
      refreshing: this.#refreshing,
      lastRefreshedAt: this.#lastRefreshedAt,
      warnings: this.#warnings,
    })
    return this.#projection
  }
}
