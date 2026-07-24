import { useState } from 'react'
import { useMutation, useQuery } from '@tanstack/react-query'
import { Link } from '@tanstack/react-router'
import { useStore } from '@tanstack/react-store'
import { Button } from 'react-aria-components'

import {
  errorMessage,
  getDesktopApi,
  type CloudQueueItem,
  type QueueState,
} from '../lib/desktop-api'
import { queryClient, queryKeys } from '../lib/query'
import { setQueueFilter, setSelectedQueueId, uiStore, type QueueFilter } from '../store/ui-store'
import { ActionButton, PageHeading, ResultLedger, StatePanel, StatusDot } from '../components/ui'
import { Icon } from '../components/icons'
import { formatDuration } from '../lib/format'
import { getPaginationWindow } from '../lib/pagination'

const queuePageSize = 50

const filters: QueueFilter[] = [
  'all',
  'pending',
  'running',
  'uploaded',
  'alreadyPresent',
  'failed',
  'skipped',
  'cancelled',
]

export function CloudPage() {
  const [requestedPageIndex, setRequestedPageIndex] = useState(0)
  const filter = useStore(uiStore, (state) => state.queueFilter)
  const selectedId = useStore(uiStore, (state) => state.selectedQueueId)
  const auth = useQuery({
    queryKey: queryKeys.auth,
    queryFn: () => getDesktopApi().epicAuth.getStatus(),
  })
  const cloud = useQuery({
    queryKey: queryKeys.cloud,
    queryFn: () => getDesktopApi().cloudSync.getSnapshot(),
    enabled: auth.data?.state === 'signedIn',
  })
  const settings = useQuery({
    queryKey: queryKeys.settings,
    queryFn: () => getDesktopApi().settings.get(),
  })
  const connect = useMutation({
    mutationFn: () => getDesktopApi().epicAuth.connect(),
    onSuccess: (status) => {
      queryClient.setQueryData(queryKeys.auth, status)
      void queryClient.invalidateQueries({ queryKey: queryKeys.cloud })
    },
  })
  const refresh = useMutation({
    mutationFn: () => getDesktopApi().cloudSync.refreshLibrary(),
    onSuccess: (snapshot) => {
      setRequestedPageIndex(0)
      queryClient.setQueryData(queryKeys.cloud, snapshot)
    },
  })
  const disconnect = useMutation({
    mutationFn: () => getDesktopApi().epicAuth.disconnect(),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: queryKeys.auth })
      queryClient.removeQueries({ queryKey: queryKeys.cloud })
    },
  })
  const queueAction = useMutation({
    mutationFn: async (action: 'start' | 'pause' | 'resume' | 'cancel' | 'retry' | 'clear') => {
      const api = getDesktopApi().cloudSync
      if (action === 'start') return api.start()
      if (action === 'pause') return api.pause()
      if (action === 'resume') return api.resume()
      if (action === 'cancel') return api.cancel()
      if (action === 'retry') return api.retry({})
      return api.clearCompleted()
    },
    onSuccess: () => void queryClient.invalidateQueries({ queryKey: queryKeys.cloud }),
  })

  if (auth.isLoading)
    return (
      <StatePanel
        loading
        title="Checking Epic session"
        message="Credentials remain behind the secure desktop bridge."
      />
    )
  if (auth.isError)
    return (
      <StatePanel
        title="Session status unavailable"
        message={errorMessage(auth.error)}
        action={
          <ActionButton
            icon="retry"
            onPress={() => {
              void auth.refetch()
            }}
          >
            Retry
          </ActionButton>
        }
      />
    )

  if (auth.data?.state !== 'signedIn') {
    return (
      <div className="page-stack cloud-signed-out">
        <PageHeading
          eyebrow="SOURCE 02 / EPIC CLOUD"
          title="Cloud manifests"
          description="Contribute builds for games that are not installed on this device."
        />
        <section className="connect-stage">
          <div className="cloud-radar" aria-hidden="true">
            <span />
            <i />
            <b />
          </div>
          <div className="connect-copy">
            <p className="eyebrow">OPTIONAL ACCOUNT CONNECTION</p>
            <h2>
              Your library is the index.
              <br />
              Your credentials stay private.
            </h2>
            <p>
              egdata.app asks Epic for your application library, fetches available launcher
              manifests, and sends only contribution files to egdata.app. Tokens never reach React
              or logs.
            </p>
            {auth.data?.state === 'expired' ? (
              <div className="session-warning" role="alert">
                Your previous session expired. Connect again to continue.
              </div>
            ) : null}
            {connect.isError ? (
              <div className="session-warning" role="alert">
                {errorMessage(connect.error)}
              </div>
            ) : null}
            <ActionButton
              tone="primary"
              icon="external"
              onPress={() => connect.mutate()}
              isDisabled={connect.isPending}
            >
              {connect.isPending ? 'Waiting for Epic…' : 'Connect Epic Games'}
            </ActionButton>
            <small>
              A dedicated Epic sign-in window will open. Connecting is not required for local
              contributions.
            </small>
          </div>
        </section>
        <section className="trust-line" aria-label="Connection privacy">
          <div>
            <span>01</span>
            <strong>Scoped</strong>
            <p>Library and manifest access only</p>
          </div>
          <div>
            <span>02</span>
            <strong>Encrypted</strong>
            <p>Session stored by the operating system</p>
          </div>
          <div>
            <span>03</span>
            <strong>Revocable</strong>
            <p>Clear the session at any time</p>
          </div>
        </section>
      </div>
    )
  }

  if (cloud.isLoading)
    return (
      <StatePanel
        loading
        title="Loading cloud sync"
        message="Reading your saved sync list from the desktop database…"
      />
    )
  if (cloud.isError)
    return (
      <StatePanel
        title="Cloud queue unavailable"
        message={errorMessage(cloud.error)}
        action={
          <ActionButton
            icon="retry"
            onPress={() => {
              void cloud.refetch()
            }}
          >
            Retry
          </ActionButton>
        }
      />
    )

  const snapshot = cloud.data!
  const filtered =
    filter === 'all' ? snapshot.queue : snapshot.queue.filter((item) => item.state === filter)
  const pagination = getPaginationWindow(filtered.length, requestedPageIndex, queuePageSize)
  const visibleItems = filtered.slice(pagination.startIndex, pagination.endIndex)
  const selected = visibleItems.find((item) => item.id === selectedId) ?? visibleItems[0]
  const counts = snapshot.queue.reduce<Partial<Record<QueueState, number>>>((result, item) => {
    result[item.state] = (result[item.state] ?? 0) + 1
    return result
  }, {})
  const isActive = ['running', 'pausing', 'cancelling'].includes(snapshot.state)
  const canRetry = snapshot.queue.some((item) =>
    ['failed', 'skipped', 'cancelled'].includes(item.state),
  )
  const canContribute = settings.data?.contributionConsent === true

  return (
    <div className="page-stack">
      <PageHeading
        eyebrow="SOURCE 02 / EPIC CLOUD"
        title="Cloud sync"
        description={`${auth.data.displayName ?? 'Epic account'} connected · ${snapshot.libraryCount} applications in your sync list`}
        actions={
          <>
            <ActionButton
              icon="refresh"
              onPress={() => refresh.mutate()}
              isDisabled={isActive || refresh.isPending}
            >
              Refresh library
            </ActionButton>
            <ActionButton
              onPress={() => disconnect.mutate()}
              isDisabled={isActive || disconnect.isPending}
            >
              Disconnect
            </ActionButton>
            {snapshot.state === 'paused' ? (
              <ActionButton
                tone="primary"
                icon="play"
                onPress={() => queueAction.mutate('resume')}
                isDisabled={!canContribute}
              >
                Resume
              </ActionButton>
            ) : isActive ? (
              <ActionButton
                tone="primary"
                icon="pause"
                onPress={() => queueAction.mutate('pause')}
                isDisabled={snapshot.state !== 'running'}
              >
                Pause
              </ActionButton>
            ) : (
              <ActionButton
                tone="primary"
                icon="play"
                onPress={() => queueAction.mutate('start')}
                isDisabled={snapshot.queue.length === 0 || !canContribute}
              >
                Sync pending
              </ActionButton>
            )}
          </>
        }
      />

      <ResultLedger summary={snapshot.lastResult} />

      {!settings.isLoading && !canContribute ? (
        <div className="consent-banner" role="status">
          <Icon name="shield" className="size-4" />
          <span>Cloud contribution actions are off until consent is enabled.</span>
          <Link className="action-button action-quiet" to="/settings">
            Review privacy settings
          </Link>
        </div>
      ) : null}

      {queueAction.isError || refresh.isError || disconnect.isError ? (
        <div className="error-banner" role="alert">
          <strong>Cloud action failed.</strong>
          <span>{errorMessage(queueAction.error ?? refresh.error ?? disconnect.error)}</span>
        </div>
      ) : null}

      <section className="queue-command" aria-label="Queue controls">
        <div className="queue-progress">
          <div>
            <StatusDot
              state={
                snapshot.state === 'running'
                  ? 'busy'
                  : snapshot.state === 'paused'
                    ? 'warn'
                    : 'good'
              }
            />
            <strong>{queueLabel(snapshot.state)}</strong>
            <span>
              {snapshot.completed} / {snapshot.queue.length}
            </span>
          </div>
          <div className="progress-track">
            <span
              style={{
                width: snapshot.queue.length
                  ? `${(snapshot.completed / snapshot.queue.length) * 100}%`
                  : '0%',
              }}
            />
          </div>
          <small>{formatDuration(snapshot.elapsedMs)} elapsed</small>
        </div>
        <div className="queue-actions">
          <ActionButton
            icon="retry"
            onPress={() => queueAction.mutate('retry')}
            isDisabled={!canRetry || isActive || !canContribute}
          >
            Retry eligible
          </ActionButton>
          <ActionButton onPress={() => queueAction.mutate('clear')} isDisabled={isActive}>
            Clear completed
          </ActionButton>
          <ActionButton
            tone="danger"
            icon="cancel"
            onPress={() => queueAction.mutate('cancel')}
            isDisabled={!isActive}
          >
            Cancel
          </ActionButton>
        </div>
      </section>

      <div className="queue-layout">
        <section className="queue-table-panel" aria-labelledby="queue-title">
          <header className="queue-filterbar">
            <h2 id="queue-title">Sync list</h2>
            <div role="group" aria-label="Filter queue by status" className="queue-filters">
              {filters.map((value) => (
                <Button
                  key={value}
                  className={`filter-button ${filter === value ? 'filter-active' : ''}`}
                  onPress={() => {
                    setRequestedPageIndex(0)
                    setQueueFilter(value)
                  }}
                >
                  {filterLabel(value)}{' '}
                  {value !== 'all' && counts[value] ? <span>{counts[value]}</span> : null}
                </Button>
              ))}
            </div>
          </header>

          {filtered.length === 0 ? (
            <div className="table-empty">
              <Icon name="archive" className="size-6" />
              <strong>No {filter === 'all' ? '' : filterLabel(filter).toLowerCase()} items</strong>
              <p>Choose another filter or refresh your Epic library.</p>
            </div>
          ) : (
            <>
              <div className="queue-table-scroll">
                <table className="queue-table">
                  <thead>
                    <tr>
                      <th>Application</th>
                      <th>Status</th>
                      <th>Attempts</th>
                      <th>Duration</th>
                    </tr>
                  </thead>
                  <tbody>
                    {visibleItems.map((item) => (
                      <tr
                        key={item.id}
                        className={selected?.id === item.id ? 'queue-row-selected' : ''}
                      >
                        <th scope="row">
                          <Button
                            className="queue-name-button"
                            onPress={() => setSelectedQueueId(item.id)}
                          >
                            <strong>{item.displayName}</strong>
                            <small>{item.appName}</small>
                          </Button>
                        </th>
                        <td>
                          <QueueBadge state={item.state} />
                        </td>
                        <td>{item.attempts}</td>
                        <td>{formatDuration(item.durationMs)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
              <nav className="queue-pagination" aria-label="Sync list pagination">
                <span>
                  {pagination.startIndex + 1}–{pagination.endIndex} of {filtered.length}
                </span>
                <div>
                  <Button
                    className="pagination-button"
                    onPress={() => setRequestedPageIndex(pagination.pageIndex - 1)}
                    isDisabled={pagination.pageIndex === 0}
                  >
                    Previous
                  </Button>
                  <span aria-live="polite">
                    Page {pagination.pageIndex + 1} of {pagination.pageCount}
                  </span>
                  <Button
                    className="pagination-button"
                    onPress={() => setRequestedPageIndex(pagination.pageIndex + 1)}
                    isDisabled={pagination.pageIndex === pagination.pageCount - 1}
                  >
                    Next
                  </Button>
                </div>
              </nav>
            </>
          )}
        </section>
        <QueueDetails
          item={selected}
          onRetry={(id) =>
            getDesktopApi()
              .cloudSync.retry({ ids: [id] })
              .then(() => queryClient.invalidateQueries({ queryKey: queryKeys.cloud }))
          }
          onRemove={(id) =>
            getDesktopApi()
              .cloudSync.remove({ ids: [id] })
              .then(() => {
                setSelectedQueueId()
                return queryClient.invalidateQueries({ queryKey: queryKeys.cloud })
              })
          }
          canContribute={canContribute}
        />
      </div>
    </div>
  )
}

function QueueDetails({
  item,
  onRetry,
  onRemove,
  canContribute,
}: {
  item: CloudQueueItem | undefined
  onRetry: (id: string) => Promise<unknown>
  onRemove: (id: string) => Promise<unknown>
  canContribute: boolean
}) {
  if (!item)
    return (
      <aside className="queue-details queue-details-empty" aria-labelledby="queue-detail-title">
        <div className="queue-detail-empty-icon" aria-hidden="true">
          <Icon name="info" className="size-5" />
        </div>
        <p className="eyebrow">ITEM INSPECTOR</p>
        <h2 id="queue-detail-title">Nothing selected</h2>
        <p>Select a sync-list item to inspect its metadata and safe diagnostic detail.</p>
      </aside>
    )
  return (
    <aside className="queue-details" aria-labelledby="queue-detail-title" aria-live="polite">
      <header className="queue-detail-header">
        <p className="eyebrow">ITEM INSPECTOR</p>
        <h2 id="queue-detail-title">{item.displayName}</h2>
        <QueueBadge state={item.state} />
      </header>

      <section className="queue-detail-identity" aria-labelledby="queue-application-label">
        <span id="queue-application-label">Application ID</span>
        <code title={item.appName}>{item.appName}</code>
      </section>

      <dl className="queue-detail-metrics">
        <div>
          <dt>Attempts</dt>
          <dd>{item.attempts}</dd>
        </div>
        <div>
          <dt>Duration</dt>
          <dd>{formatDuration(item.durationMs)}</dd>
        </div>
      </dl>

      <section className="queue-detail-diagnostics" aria-labelledby="queue-diagnostic-label">
        <div className="queue-detail-section-heading">
          <span id="queue-diagnostic-label">Diagnostic</span>
          <small>{item.error ? 'Attention needed' : 'No issues reported'}</small>
        </div>
        {item.error ? (
          <div className="detail-error">
            <div>
              <Icon name="info" className="size-4" />
              <span>{item.error.code}</span>
            </div>
            <p>{item.error.message}</p>
          </div>
        ) : (
          <p className="detail-note">This item has no diagnostic message.</p>
        )}
      </section>

      <div className="queue-detail-actions">
        {['failed', 'skipped', 'cancelled'].includes(item.state) ? (
          <ActionButton
            className="queue-detail-action"
            tone="primary"
            icon="retry"
            onPress={() => void onRetry(item.id)}
            isDisabled={!canContribute}
          >
            Retry item
          </ActionButton>
        ) : null}
        {item.state !== 'running' ? (
          <ActionButton
            className="queue-detail-action"
            tone="danger"
            onPress={() => void onRemove(item.id)}
          >
            Remove from sync list
          </ActionButton>
        ) : null}
        {item.state !== 'running' ? (
          <p>Removal only affects this sync list. It does not change your Epic library.</p>
        ) : null}
      </div>
    </aside>
  )
}

function QueueBadge({ state }: { state: QueueState }) {
  return (
    <span className={`queue-badge queue-${state}`}>
      <i />
      {filterLabel(state)}
    </span>
  )
}

function filterLabel(value: QueueFilter): string {
  if (value === 'alreadyPresent') return 'Already present'
  return value.charAt(0).toUpperCase() + value.slice(1)
}

function queueLabel(state: string): string {
  const labels: Record<string, string> = {
    idle: 'Sync list ready',
    complete: 'Sync complete',
    fetching: 'Fetching library',
    running: 'Contributing',
    pausing: 'Finishing active items',
    paused: 'Queue paused',
    cancelling: 'Cancelling work',
  }
  return labels[state] ?? state
}
