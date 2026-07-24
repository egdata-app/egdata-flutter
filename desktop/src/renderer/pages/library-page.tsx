import { useEffect, useMemo, useState } from 'react'
import { useMutation, useQuery } from '@tanstack/react-query'
import {
  Button,
  Checkbox,
  Dialog,
  Input,
  ListBox,
  ListBoxItem,
  Modal,
  ModalOverlay,
  Popover,
  SearchField,
  Select,
  SelectValue,
} from 'react-aria-components'

import type {
  LibraryCard,
  LibraryDetails,
  LibraryFacetOption,
  LibraryFacets,
  LibraryInstalledFilter,
  LibraryQueryRequest,
  LibrarySortDirection,
  LibrarySortField,
} from '../../shared/contracts'
import { EgdataAppIcon } from '../components/egdata-app-icon'
import { Icon } from '../components/icons'
import { ActionButton, StatePanel } from '../components/ui'
import { errorMessage, getDesktopApi } from '../lib/desktop-api'
import { formatDate } from '../lib/format'
import { queryClient, queryKeys } from '../lib/query'

const PAGE_SIZE = 48

type FacetKey = 'genreIds' | 'featureIds' | 'typeIds' | 'platformIds' | 'subscriptionIds'
type ViewMode = 'grid' | 'list'

const sortOptions: Array<{ id: LibrarySortField; label: string }> = [
  { id: 'title', label: 'Title' },
  { id: 'releaseDate', label: 'Release date' },
  { id: 'lastModified', label: 'Recently updated' },
]

const initialSelections = (): Pick<LibraryQueryRequest, FacetKey> => ({
  genreIds: [],
  featureIds: [],
  typeIds: [],
  platformIds: [],
  subscriptionIds: [],
})

function Artwork({ item, compact = false }: { item: LibraryCard; compact?: boolean }) {
  const [failed, setFailed] = useState(false)
  return (
    <span className={compact ? 'library-artwork library-artwork-compact' : 'library-artwork'}>
      {item.artworkUrl && !failed ? (
        <img src={item.artworkUrl} alt="" loading="lazy" onError={() => setFailed(true)} />
      ) : (
        <span className="library-artwork-fallback" aria-hidden="true">
          <EgdataAppIcon className="library-fallback-icon" />
        </span>
      )}
      {item.addOnCount > 0 ? (
        <span className="library-addon-badge">
          {item.addOnCount} add-on{item.addOnCount === 1 ? '' : 's'}
        </span>
      ) : null}
    </span>
  )
}

function sourceLabel(item: LibraryCard): string {
  if (item.installed && item.epicOwned) return 'Installed · Epic owned'
  if (item.installed) return 'Installed locally'
  return 'Epic owned'
}

function LibraryCardButton({ item, onOpen }: { item: LibraryCard; onOpen: () => void }) {
  return (
    <Button className="library-card" onPress={onOpen} aria-label={`Open ${item.title} details`}>
      <Artwork item={item} />
      <span className="library-card-copy">
        <strong>{item.title}</strong>
        <small>{sourceLabel(item)}</small>
      </span>
    </Button>
  )
}

function LibraryListRow({ item, onOpen }: { item: LibraryCard; onOpen: () => void }) {
  return (
    <Button className="library-list-row" onPress={onOpen} aria-label={`Open ${item.title} details`}>
      <Artwork item={item} compact />
      <span className="library-list-main">
        <strong>{item.title}</strong>
        <small>
          {[item.developer, item.publisher].filter(Boolean).join(' · ') || item.appName}
        </small>
      </span>
      <span className="library-list-meta">
        <span>{item.type ?? 'Game'}</span>
        <small>{item.platforms.join(' · ') || 'Platform not classified'}</small>
      </span>
      <span className="library-source-pill">{sourceLabel(item)}</span>
      <Icon name="chevron" className="size-4" />
    </Button>
  )
}

function FacetSection({
  title,
  options,
  selected,
  onToggle,
}: {
  title: string
  options: LibraryFacetOption[]
  selected: string[]
  onToggle: (id: string) => void
}) {
  const [open, setOpen] = useState(selected.length > 0)
  if (options.length === 0) return null
  return (
    <section className="library-filter-section">
      <Button
        className="library-filter-heading"
        onPress={() => setOpen((value) => !value)}
        aria-expanded={open}
      >
        <span>
          {title}
          {selected.length > 0 ? <i>{selected.length}</i> : null}
        </span>
        <Icon name="chevron" className={open ? 'size-3 filter-caret-open' : 'size-3'} />
      </Button>
      {open ? (
        <div className="library-filter-options">
          {options.map((option) => (
            <Checkbox
              key={option.id}
              isSelected={selected.includes(option.id)}
              onChange={() => onToggle(option.id)}
              className="library-filter-option"
            >
              <span className="library-checkbox" aria-hidden="true">
                <Icon name="check" className="size-3" />
              </span>
              <span>{option.label}</span>
              <small>{option.count}</small>
            </Checkbox>
          ))}
        </div>
      ) : null}
    </section>
  )
}

function InstalledFilter({
  value,
  onChange,
}: {
  value: LibraryInstalledFilter
  onChange: (value: LibraryInstalledFilter) => void
}) {
  const options: Array<{ id: LibraryInstalledFilter; label: string }> = [
    { id: 'all', label: 'All games' },
    { id: 'installed', label: 'Installed' },
    { id: 'not-installed', label: 'Not installed' },
  ]
  return (
    <section className="library-filter-section library-installed-filter">
      <h2>Install state</h2>
      <div>
        {options.map((option) => (
          <Button
            key={option.id}
            className={
              value === option.id ? 'library-state-choice is-selected' : 'library-state-choice'
            }
            onPress={() => onChange(option.id)}
            aria-pressed={value === option.id}
          >
            {option.label}
          </Button>
        ))}
      </div>
    </section>
  )
}

function FilterPanel({
  open,
  draftText,
  installed,
  selections,
  facets,
  activeCount,
  onText,
  onInstalled,
  onToggle,
  onReset,
  onClose,
}: {
  open: boolean
  draftText: string
  installed: LibraryInstalledFilter
  selections: Pick<LibraryQueryRequest, FacetKey>
  facets: ReturnType<typeof emptyFacets>
  activeCount: number
  onText: (value: string) => void
  onInstalled: (value: LibraryInstalledFilter) => void
  onToggle: (key: FacetKey, id: string) => void
  onReset: () => void
  onClose: () => void
}) {
  return (
    <>
      {open ? (
        <Button className="library-filter-backdrop" aria-label="Close filters" onPress={onClose} />
      ) : null}
      <aside
        className={open ? 'library-filters is-open' : 'library-filters'}
        aria-label="Library filters"
      >
        <header>
          <div>
            <h2>Filters</h2>
            {activeCount > 0 ? <span>{activeCount}</span> : null}
          </div>
          <Button className="library-filter-close" aria-label="Close filters" onPress={onClose}>
            <Icon name="cancel" className="size-4" />
          </Button>
          <Button
            className="library-reset"
            onPress={onReset}
            isDisabled={activeCount === 0 && !draftText}
          >
            Reset
          </Button>
        </header>
        <SearchField
          className="library-search"
          value={draftText}
          onChange={onText}
          aria-label="Search Library by title"
        >
          <Icon name="search" className="size-4" />
          <Input placeholder="Search title, studio, or tag" />
          <Button aria-label="Clear search">
            <Icon name="cancel" className="size-3" />
          </Button>
        </SearchField>
        <InstalledFilter value={installed} onChange={onInstalled} />
        <FacetSection
          title="Genre"
          options={facets.genres}
          selected={selections.genreIds}
          onToggle={(id) => onToggle('genreIds', id)}
        />
        <FacetSection
          title="Features"
          options={facets.features}
          selected={selections.featureIds}
          onToggle={(id) => onToggle('featureIds', id)}
        />
        <FacetSection
          title="Type"
          options={facets.types}
          selected={selections.typeIds}
          onToggle={(id) => onToggle('typeIds', id)}
        />
        <FacetSection
          title="Platform"
          options={facets.platforms}
          selected={selections.platformIds}
          onToggle={(id) => onToggle('platformIds', id)}
        />
        <FacetSection
          title="Subscriptions"
          options={facets.subscriptions}
          selected={selections.subscriptionIds}
          onToggle={(id) => onToggle('subscriptionIds', id)}
        />
      </aside>
    </>
  )
}

function emptyFacets(): LibraryFacets {
  return { genres: [], features: [], types: [], platforms: [], subscriptions: [] }
}

function LibraryDrawer({ id, onClose }: { id: string | null; onClose: () => void }) {
  const details = useQuery({
    queryKey: id ? queryKeys.libraryDetails({ id }) : ['library', 'details', 'none'],
    queryFn: () => {
      if (!id) throw new Error('Select a Library game first.')
      return getDesktopApi().library.getDetails({ id })
    },
    enabled: id !== null,
  })
  return (
    <ModalOverlay
      className="library-drawer-overlay"
      isOpen={id !== null}
      onOpenChange={(open) => !open && onClose()}
      isDismissable
    >
      <Modal className="library-drawer-modal">
        <Dialog
          className="library-drawer"
          aria-label={details.data ? `${details.data.title} details` : 'Library game details'}
        >
          {({ close }) => (
            <>
              <Button className="library-drawer-close" aria-label="Close details" onPress={close}>
                <Icon name="cancel" className="size-5" />
              </Button>
              {details.isLoading ? (
                <div className="library-drawer-state" aria-busy="true">
                  <span className="state-orbit animate-spin" aria-hidden="true" />
                  <strong>Loading details</strong>
                </div>
              ) : details.isError || !details.data ? (
                <div className="library-drawer-state">
                  <strong>Details unavailable</strong>
                  <p>{errorMessage(details.error)}</p>
                  <ActionButton onPress={() => void details.refetch()}>Retry</ActionButton>
                </div>
              ) : (
                <DrawerContent details={details.data} />
              )}
            </>
          )}
        </Dialog>
      </Modal>
    </ModalOverlay>
  )
}

function DrawerContent({ details }: { details: LibraryDetails }) {
  return (
    <div className="library-drawer-content">
      <Artwork item={details} />
      <p className="eyebrow">{details.type ?? 'LIBRARY GAME'}</p>
      <h2>{details.title}</h2>
      <p className="library-drawer-source">{sourceLabel(details)}</p>
      <p className="library-drawer-description">
        {details.description || details.longDescription || 'No description is available yet.'}
      </p>
      <dl className="library-detail-grid">
        <div>
          <dt>Developer</dt>
          <dd>{details.developer ?? 'Not classified'}</dd>
        </div>
        <div>
          <dt>Publisher</dt>
          <dd>{details.publisher ?? 'Not classified'}</dd>
        </div>
        <div>
          <dt>Release</dt>
          <dd>{details.releaseDate ? formatDate(details.releaseDate) : 'Unknown'}</dd>
        </div>
        <div>
          <dt>Platform</dt>
          <dd>{details.platforms.join(', ') || 'Not classified'}</dd>
        </div>
      </dl>
      <DetailTags title="Genres" values={details.genres} />
      <DetailTags title="Features" values={details.features} />
      <DetailTags title="Subscriptions" values={details.subscriptions} />
      {details.addOns.length > 0 ? (
        <section className="library-detail-section">
          <h3>
            Add-ons <span>{details.addOns.length}</span>
          </h3>
          <div className="library-addon-list">
            {details.addOns.map((addOn) => (
              <div key={addOn.id}>
                <strong>{addOn.title}</strong>
                <small>
                  {addOn.installed ? 'Installed' : addOn.epicOwned ? 'Epic owned' : 'Discovered'}
                </small>
              </div>
            ))}
          </div>
        </section>
      ) : null}
    </div>
  )
}

function DetailTags({ title, values }: { title: string; values: string[] }) {
  if (values.length === 0) return null
  return (
    <section className="library-detail-section">
      <h3>{title}</h3>
      <div className="library-detail-tags">
        {values.map((value) => (
          <span key={value}>{value}</span>
        ))}
      </div>
    </section>
  )
}

export function LibraryPage() {
  const [draftText, setDraftText] = useState('')
  const [text, setText] = useState('')
  const [installed, setInstalled] = useState<LibraryInstalledFilter>('all')
  const [selections, setSelections] = useState(initialSelections)
  const [sortField, setSortField] = useState<LibrarySortField>('title')
  const [sortDirection, setSortDirection] = useState<LibrarySortDirection>('asc')
  const [view, setView] = useState<ViewMode>('grid')
  const [page, setPage] = useState(1)
  const [filtersOpen, setFiltersOpen] = useState(false)
  const [selectedId, setSelectedId] = useState<string | null>(null)

  useEffect(() => {
    const timer = window.setTimeout(() => {
      setText(draftText)
      setPage(1)
    }, 220)
    return () => window.clearTimeout(timer)
  }, [draftText])

  const request = useMemo<LibraryQueryRequest>(
    () => ({ text, page, pageSize: PAGE_SIZE, installed, ...selections, sortField, sortDirection }),
    [installed, page, selections, sortDirection, sortField, text],
  )
  const library = useQuery({
    queryKey: queryKeys.libraryPage(request),
    queryFn: () => getDesktopApi().library.query(request),
    placeholderData: (previous) => previous,
  })
  const status = useQuery({
    queryKey: queryKeys.libraryStatus,
    queryFn: () => getDesktopApi().library.getStatus(),
  })
  const refresh = useMutation({
    mutationFn: () => getDesktopApi().library.refresh(),
    onSuccess: (result) => {
      queryClient.setQueryData(queryKeys.libraryStatus, result.status)
      void queryClient.invalidateQueries({ queryKey: queryKeys.libraryPageRoot })
      void queryClient.invalidateQueries({ queryKey: queryKeys.libraryDetailsRoot })
    },
  })
  const activeCount =
    Object.values(selections).reduce((sum, values) => sum + values.length, 0) +
    (installed === 'all' ? 0 : 1)
  const changeFilter = () => setPage(1)
  const toggleFacet = (key: FacetKey, id: string) => {
    setSelections((current) => ({
      ...current,
      [key]: current[key].includes(id)
        ? current[key].filter((value) => value !== id)
        : [...current[key], id],
    }))
    changeFilter()
  }
  const reset = () => {
    setDraftText('')
    setText('')
    setInstalled('all')
    setSelections(initialSelections())
    setPage(1)
  }

  if (library.isLoading && !library.data) return <LibrarySkeleton />
  if (library.isError || !library.data) {
    return (
      <StatePanel
        title="Library unavailable"
        message={errorMessage(library.error)}
        action={<ActionButton onPress={() => void library.refetch()}>Retry</ActionButton>}
      />
    )
  }
  const data = library.data
  const currentStatus = status.data ?? data.status
  const totalPages = Math.max(1, Math.ceil(data.total / data.pageSize))
  const hasFilters = activeCount > 0 || text.length > 0

  return (
    <div className="library-page">
      <header className="library-heading">
        <div>
          <p className="eyebrow">OWNED + DISCOVERED</p>
          <h1>Library</h1>
          <p>{currentStatus.total} games across Epic ownership and this device.</p>
        </div>
        <ActionButton
          icon="refresh"
          onPress={() => refresh.mutate()}
          isDisabled={refresh.isPending}
        >
          {refresh.isPending ? 'Refreshing…' : 'Refresh'}
        </ActionButton>
      </header>

      {currentStatus.warnings.length > 0 || refresh.error ? (
        <div className="library-banner" role="status">
          <strong>Using saved Library data</strong>
          <span>{currentStatus.warnings[0] ?? errorMessage(refresh.error)}</span>
        </div>
      ) : currentStatus.partialMetadata > 0 ? (
        <div className="library-banner library-banner-neutral" role="status">
          <strong>{currentStatus.partialMetadata} games are still being enriched</strong>
          <span>
            Titles remain searchable while egdata.app fills in artwork and classifications.
          </span>
        </div>
      ) : null}

      <div className="library-toolbar">
        <div className="library-sort-group">
          <span>Sort by</span>
          <Select
            selectedKey={sortField}
            onSelectionChange={(key) => {
              setSortField(String(key) as LibrarySortField)
              setPage(1)
            }}
            aria-label="Sort Library"
            className="library-sort-select"
          >
            <Button>
              <SelectValue /> <Icon name="chevron" className="size-3" />
            </Button>
            <Popover className="library-sort-popover">
              <ListBox>
                {sortOptions.map((option) => (
                  <ListBoxItem id={option.id} key={option.id}>
                    {option.label}
                  </ListBoxItem>
                ))}
              </ListBox>
            </Popover>
          </Select>
          <Button
            className="library-icon-button"
            onPress={() => {
              setSortDirection((value) => (value === 'asc' ? 'desc' : 'asc'))
              setPage(1)
            }}
            aria-label={`Sort ${sortDirection === 'asc' ? 'descending' : 'ascending'}`}
          >
            <Icon name={sortDirection === 'asc' ? 'sort-asc' : 'sort-desc'} className="size-5" />
          </Button>
        </div>
        <span className="library-result-count">
          {data.total} result{data.total === 1 ? '' : 's'}
        </span>
        <div className="library-view-controls" aria-label="Library view">
          <Button
            className={view === 'grid' ? 'library-icon-button is-active' : 'library-icon-button'}
            onPress={() => setView('grid')}
            aria-label="Grid view"
            aria-pressed={view === 'grid'}
          >
            <Icon name="grid" className="size-5" />
          </Button>
          <Button
            className={view === 'list' ? 'library-icon-button is-active' : 'library-icon-button'}
            onPress={() => setView('list')}
            aria-label="List view"
            aria-pressed={view === 'list'}
          >
            <Icon name="list" className="size-5" />
          </Button>
          <Button
            className="library-icon-button library-mobile-filter"
            onPress={() => setFiltersOpen(true)}
            aria-label="Open filters"
          >
            <Icon name="filters" className="size-5" />
            {activeCount > 0 ? <i>{activeCount}</i> : null}
          </Button>
        </div>
      </div>

      <div className="library-workspace">
        <main className="library-results" aria-busy={library.isFetching}>
          {data.items.length > 0 ? (
            view === 'grid' ? (
              <div className="library-grid">
                {data.items.map((item) => (
                  <LibraryCardButton
                    key={item.id}
                    item={item}
                    onOpen={() => setSelectedId(item.id)}
                  />
                ))}
              </div>
            ) : (
              <div className="library-list">
                {data.items.map((item) => (
                  <LibraryListRow key={item.id} item={item} onOpen={() => setSelectedId(item.id)} />
                ))}
              </div>
            )
          ) : currentStatus.total === 0 ? (
            <LibraryEmpty
              signedIn={currentStatus.signedIn}
              onRefresh={() => refresh.mutate()}
              refreshing={refresh.isPending}
            />
          ) : (
            <section className="library-no-results">
              <Icon name="search" className="size-7" />
              <h2>No games match these filters</h2>
              <p>Clear the search and filters to return to your complete Library.</p>
              <ActionButton onPress={reset} isDisabled={!hasFilters}>
                Reset filters
              </ActionButton>
            </section>
          )}
          {data.total > data.pageSize ? (
            <footer className="library-pagination">
              <ActionButton
                onPress={() => setPage((value) => Math.max(1, value - 1))}
                isDisabled={page <= 1}
              >
                Previous
              </ActionButton>
              <span>
                Page {page} of {totalPages}
              </span>
              <ActionButton
                onPress={() => setPage((value) => value + 1)}
                isDisabled={!data.hasMore}
              >
                Next
              </ActionButton>
            </footer>
          ) : null}
        </main>
        <FilterPanel
          open={filtersOpen}
          draftText={draftText}
          installed={installed}
          selections={selections}
          facets={data.facets}
          activeCount={activeCount}
          onText={setDraftText}
          onInstalled={(value) => {
            setInstalled(value)
            changeFilter()
          }}
          onToggle={toggleFacet}
          onReset={reset}
          onClose={() => setFiltersOpen(false)}
        />
      </div>
      <LibraryDrawer id={selectedId} onClose={() => setSelectedId(null)} />
    </div>
  )
}

function LibrarySkeleton() {
  return (
    <div className="library-page library-skeleton" aria-busy="true">
      <div className="skeleton-line skeleton-title" />
      <div className="skeleton-line skeleton-toolbar" />
      <div className="library-grid">
        {Array.from({ length: 8 }, (_, index) => (
          <div className="library-card-skeleton" key={index}>
            <span />
            <i />
            <i />
          </div>
        ))}
      </div>
    </div>
  )
}

function LibraryEmpty({
  signedIn,
  onRefresh,
  refreshing,
}: {
  signedIn: boolean
  onRefresh: () => void
  refreshing: boolean
}) {
  return (
    <section className="library-empty">
      <EgdataAppIcon className="library-empty-icon" />
      <p className="eyebrow">YOUR GAMES, TOGETHER</p>
      <h2>Your Library is ready to be discovered</h2>
      <p>
        {signedIn
          ? 'Refresh Epic ownership and scan this device for installed games.'
          : 'Connect Epic from Cloud, or scan this device to begin building your Library.'}
      </p>
      <ActionButton tone="primary" icon="refresh" onPress={onRefresh} isDisabled={refreshing}>
        {refreshing ? 'Refreshing…' : 'Scan this device'}
      </ActionButton>
    </section>
  )
}
