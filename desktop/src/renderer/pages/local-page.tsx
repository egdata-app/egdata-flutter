import { useEffect, useEffectEvent } from 'react'
import { useMutation, useQuery } from '@tanstack/react-query'
import { Link } from '@tanstack/react-router'
import { useStore } from '@tanstack/react-store'
import { Checkbox } from 'react-aria-components'

import { errorMessage, getDesktopApi, type LocalManifest } from '../lib/desktop-api'
import { queryClient, queryKeys } from '../lib/query'
import {
  clearLocalSelection,
  setAllLocalSelected,
  setLocalSelected,
  uiStore,
} from '../store/ui-store'
import { ActionButton, PageHeading, ResultLedger, StatePanel, StatusDot } from '../components/ui'
import { Icon } from '../components/icons'
import { formatDate } from '../lib/format'

export function LocalPage() {
  const selectedIds = useStore(uiStore, (state) => state.selectedLocalIds)
  const local = useQuery({
    queryKey: queryKeys.local,
    queryFn: () => getDesktopApi().localManifests.getSnapshot(),
  })
  const settings = useQuery({
    queryKey: queryKeys.settings,
    queryFn: () => getDesktopApi().settings.get(),
  })
  const scan = useMutation({
    mutationFn: () => getDesktopApi().localManifests.scan(),
    onSuccess: (snapshot) => {
      queryClient.setQueryData(queryKeys.local, snapshot)
      clearLocalSelection()
    },
  })
  const upload = useMutation({
    mutationFn: (ids: string[]) => getDesktopApi().localManifests.upload({ ids }),
    onSuccess: () => {
      clearLocalSelection()
      void queryClient.invalidateQueries({ queryKey: queryKeys.local })
    },
  })
  const requestInitialScan = useEffectEvent(() => {
    if (!scan.isPending) scan.mutate()
  })

  useEffect(() => {
    if (local.data && !local.data.scannedAt) requestInitialScan()
  }, [local.data])

  if (local.isLoading)
    return (
      <StatePanel
        loading
        title="Reading launcher records"
        message="Checking the standard Epic manifest directory…"
      />
    )
  if (local.isError) {
    return (
      <StatePanel
        title="Local source unavailable"
        message={errorMessage(local.error)}
        action={
          <ActionButton
            icon="retry"
            onPress={() => {
              void local.refetch()
            }}
          >
            Retry
          </ActionButton>
        }
      />
    )
  }

  const snapshot = local.data!
  const manifests = snapshot.groups
    .flatMap((group) => [group.base, ...group.addons])
    .filter((item): item is LocalManifest => Boolean(item))
  const uploadable = manifests.filter((item) => item.manifestAvailable && !item.issue)
  const selection = selectedIds.filter((id) => uploadable.some((item) => item.id === id))
  const allSelected = uploadable.length > 0 && selection.length === uploadable.length
  const working = scan.isPending || upload.isPending
  const canContribute = settings.data?.contributionConsent === true

  return (
    <div className="page-stack local-page">
      <PageHeading
        eyebrow="SOURCE 01 / THIS DEVICE"
        title="Local manifests"
        description="Review grouped launcher records. Add-ons stay individually selectable and are always included in Upload all."
        actions={
          <>
            <ActionButton icon="refresh" onPress={() => scan.mutate()} isDisabled={working}>
              Scan again
            </ActionButton>
            <ActionButton
              tone="primary"
              icon="upload"
              onPress={() => upload.mutate(selection)}
              isDisabled={selection.length === 0 || working || !canContribute}
            >
              Upload selected <span className="button-count">{selection.length}</span>
            </ActionButton>
          </>
        }
      />

      <ResultLedger summary={snapshot.lastResult} />

      {!settings.isLoading && !canContribute ? (
        <div className="consent-banner" role="status">
          <Icon name="shield" className="size-4" />
          <span>Manifest upload is off until contribution consent is enabled.</span>
          <Link className="action-button action-quiet" to="/settings">
            Review privacy settings
          </Link>
        </div>
      ) : null}

      {scan.isError || upload.isError ? (
        <div className="error-banner" role="alert">
          <strong>{scan.isError ? 'Scan failed.' : 'Upload stopped.'}</strong>
          <span>{errorMessage(scan.error ?? upload.error)}</span>
          <ActionButton
            icon="retry"
            onPress={() => (scan.isError ? scan.mutate() : upload.mutate(selection))}
          >
            Try again
          </ActionButton>
        </div>
      ) : null}

      <section className="source-status" aria-label="Local source status">
        <div>
          <StatusDot
            state={
              snapshot.health === 'healthy'
                ? 'good'
                : snapshot.health === 'scanning'
                  ? 'busy'
                  : 'warn'
            }
          />
          <span>
            <strong>
              {snapshot.health === 'healthy' ? 'Source healthy' : 'Source needs attention'}
            </strong>
            <small>{snapshot.sourceLabel}</small>
          </span>
        </div>
        <dl>
          <div>
            <dt>Records</dt>
            <dd>{manifests.length}</dd>
          </div>
          <div>
            <dt>Ready</dt>
            <dd>{uploadable.length}</dd>
          </div>
          <div>
            <dt>Last scan</dt>
            <dd>{formatDate(snapshot.scannedAt)}</dd>
          </div>
        </dl>
      </section>

      {snapshot.groups.length === 0 && snapshot.issues.length === 0 ? (
        <StatePanel
          title="No launcher manifests found"
          message="Install or update a game in Epic Games Launcher, then scan again. egdata.app only checks expected launcher folders."
          action={
            <ActionButton icon="refresh" onPress={() => scan.mutate()}>
              Scan again
            </ActionButton>
          }
        />
      ) : (
        <section className="manifest-workbench" aria-labelledby="manifest-list-title">
          <header className="workbench-header">
            <Checkbox
              className="table-check"
              isSelected={allSelected}
              isIndeterminate={selection.length > 0 && !allSelected}
              onChange={(selected) =>
                setAllLocalSelected(selected ? uploadable.map((item) => item.id) : [])
              }
              aria-label="Select all uploadable manifests"
            >
              <span className="checkbox-box" aria-hidden="true">
                {selection.length > 0 ? (allSelected ? '✓' : '−') : ''}
              </span>
            </Checkbox>
            <div>
              <h2 id="manifest-list-title">Discovered records</h2>
              <p>
                {selection.length} selected of {uploadable.length} ready
              </p>
            </div>
            <ActionButton
              onPress={() => upload.mutate(uploadable.map((item) => item.id))}
              isDisabled={uploadable.length === 0 || working || !canContribute}
              icon="upload"
            >
              Upload all {uploadable.length}
            </ActionButton>
          </header>

          <div className="manifest-groups">
            {snapshot.groups.map((group) => {
              const groupItems = [group.base, ...group.addons].filter(
                (item): item is LocalManifest => Boolean(item),
              )
              return (
                <section
                  className="manifest-group"
                  key={group.id}
                  aria-labelledby={`group-${group.id}`}
                >
                  <header>
                    <span className="group-rule" />
                    <h3 id={`group-${group.id}`}>{group.displayName}</h3>
                    <span>
                      {group.addons.length
                        ? `${group.addons.length} add-on${group.addons.length === 1 ? '' : 's'}`
                        : 'Base game'}
                    </span>
                  </header>
                  {groupItems.map((item) => (
                    <ManifestRow
                      key={item.id}
                      item={item}
                      selected={selection.includes(item.id)}
                      onSelected={(selected) => setLocalSelected(item.id, selected)}
                    />
                  ))}
                </section>
              )
            })}
          </div>
        </section>
      )}

      {snapshot.issues.length > 0 ? (
        <section className="issues-panel" aria-labelledby="issues-title">
          <header>
            <h2 id="issues-title">Discovery issues</h2>
            <span>{snapshot.issues.length} need attention</span>
          </header>
          {snapshot.issues.map((issue) => (
            <div className="issue-row" key={issue.id}>
              <span className="issue-code">{issue.code}</span>
              <strong>{issue.fileName}</strong>
              <p>{issue.message}</p>
            </div>
          ))}
        </section>
      ) : null}
    </div>
  )
}

function ManifestRow({
  item,
  selected,
  onSelected,
}: {
  item: LocalManifest
  selected: boolean
  onSelected: (selected: boolean) => void
}) {
  const unavailable = !item.manifestAvailable || Boolean(item.issue)
  return (
    <div className={`manifest-row ${unavailable ? 'manifest-unavailable' : ''}`}>
      <Checkbox
        className="table-check"
        isSelected={selected}
        onChange={onSelected}
        isDisabled={unavailable}
        aria-label={`Select ${item.displayName}`}
      >
        <span className="checkbox-box" aria-hidden="true">
          {selected ? '✓' : ''}
        </span>
      </Checkbox>
      <span className={`kind-marker kind-${item.kind}`}>
        <Icon name={item.kind === 'base' ? 'archive' : 'chevron'} className="size-4" />
      </span>
      <span className="manifest-identity">
        <strong>{item.displayName}</strong>
        <small>
          {item.appName} · {item.sourceFile}
        </small>
      </span>
      <span className="manifest-kind">{item.kind === 'base' ? 'BASE' : 'ADD-ON'}</span>
      <span className="manifest-version">{item.version ?? 'Version unknown'}</span>
      <span className={`readiness ${unavailable ? 'readiness-bad' : ''}`}>
        <i />
        {unavailable ? (item.issue?.message ?? 'Binary missing') : 'Ready'}
      </span>
    </div>
  )
}
