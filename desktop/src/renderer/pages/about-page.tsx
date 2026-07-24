import { useState } from 'react'
import { useMutation, useQuery } from '@tanstack/react-query'
import { Button, Dialog, Heading, Modal, ModalOverlay } from 'react-aria-components'

import { errorMessage, getDesktopApi } from '../lib/desktop-api'
import { queryClient, queryKeys } from '../lib/query'
import { EgdataAppIcon } from '../components/egdata-app-icon'
import { ActionButton, PageHeading, StatePanel, StatusDot } from '../components/ui'
import { Icon } from '../components/icons'

const links = [
  [
    'Release notes',
    'What changed in this version',
    'https://github.com/egdata-app/egdata-flutter/releases',
  ],
  ['Privacy policy', 'How contribution and account data are handled', 'https://egdata.app/privacy'],
  [
    'Open-source licenses',
    'Libraries that make egdata.app possible',
    'https://egdata.app/licenses',
  ],
] as const

export function AboutPage() {
  const [confirmInstall, setConfirmInstall] = useState(false)
  const app = useQuery({ queryKey: queryKeys.app, queryFn: () => getDesktopApi().app.getInfo() })
  const updates = useQuery({
    queryKey: queryKeys.updates,
    queryFn: () => getDesktopApi().updates.getStatus(),
  })
  const check = useMutation({
    mutationFn: () => getDesktopApi().updates.check(),
    onSuccess: (value) => queryClient.setQueryData(queryKeys.updates, value),
  })
  const download = useMutation({
    mutationFn: () => getDesktopApi().updates.download(),
    onSuccess: (value) => queryClient.setQueryData(queryKeys.updates, value),
  })
  const install = useMutation({
    mutationFn: (cancelActiveWork: boolean) =>
      getDesktopApi().updates.install({ cancelActiveWork }),
    onSuccess: (result) => {
      if (result.outcome === 'confirmation-required') setConfirmInstall(true)
      else setConfirmInstall(false)
    },
  })

  if (app.isLoading || updates.isLoading)
    return (
      <StatePanel
        loading
        title="Reading application details"
        message="Checking the installed version and update channel…"
      />
    )
  if (app.isError || updates.isError)
    return (
      <StatePanel
        title="Application details unavailable"
        message={errorMessage(app.error ?? updates.error)}
        action={
          <ActionButton
            icon="retry"
            onPress={() => {
              void app.refetch()
              void updates.refetch()
            }}
          >
            Retry
          </ActionButton>
        }
      />
    )

  const update = updates.data!
  const releaseNotesUrl = update.releaseNotesUrl
  const updateOperationActive = ['checking', 'downloading', 'installing'].includes(update.state)
  const actionPending =
    check.isPending || download.isPending || install.isPending || updateOperationActive
  return (
    <div className="page-stack about-page">
      <PageHeading
        eyebrow="APPLICATION / IDENTITY"
        title="About egdata.app"
        description="A focused desktop tool for preserving Epic game build history."
      />
      <section className="about-hero">
        <EgdataAppIcon className="about-app-icon" />
        <div>
          <p className="eyebrow">egdata.app DESKTOP</p>
          <h2>Manifest Contributor</h2>
          <p>
            Version {app.data!.version} · {app.data!.platform}
          </p>
        </div>
        <div className="build-stamp">
          <span>BUILD</span>
          <strong>{app.data!.version}</strong>
        </div>
      </section>

      <section className="update-panel" aria-labelledby="update-title">
        <div>
          <StatusDot
            state={
              update.state === 'error'
                ? 'bad'
                : ['available', 'downloading', 'downloaded'].includes(update.state)
                  ? 'warn'
                  : update.state === 'checking' || update.state === 'installing'
                    ? 'busy'
                    : 'good'
            }
          />
          <span>
            <strong id="update-title">{updateTitle(update.state)}</strong>
            <small>
              {update.message ??
                (update.availableVersion
                  ? `Version ${update.availableVersion} is ready`
                  : `Version ${update.currentVersion} is installed`)}
            </small>
            <small className="update-channel-label">
              {update.channel === 'beta' ? 'Beta channel' : 'Stable channel'}
            </small>
          </span>
        </div>
        {update.state === 'downloading' ? (
          <div
            className="update-progress"
            role="progressbar"
            aria-label={`Downloading egdata.app ${update.availableVersion ?? 'update'}`}
            aria-valuemin={0}
            aria-valuemax={100}
            aria-valuenow={update.progressPercent ?? 0}
          >
            <i style={{ width: `${update.progressPercent ?? 0}%` }} />
            <span>{update.progressPercent ?? 0}%</span>
          </div>
        ) : null}
        <div className="update-actions">
          {releaseNotesUrl ? (
            <ActionButton
              icon="external"
              onPress={() => void getDesktopApi().app.openExternal(releaseNotesUrl)}
            >
              Open release
            </ActionButton>
          ) : null}
          {update.delivery === 'managed' && update.state === 'downloaded' ? (
            <ActionButton
              tone="primary"
              onPress={() => install.mutate(false)}
              isDisabled={actionPending}
            >
              {install.isPending ? 'Preparing…' : 'Install update'}
            </ActionButton>
          ) : null}
          {update.delivery === 'managed' && update.state === 'error' && update.availableVersion ? (
            <ActionButton icon="retry" onPress={() => download.mutate()} isDisabled={actionPending}>
              {download.isPending ? 'Downloading…' : 'Retry download'}
            </ActionButton>
          ) : null}
          {update.delivery !== 'store' ? (
            <ActionButton icon="refresh" onPress={() => check.mutate()} isDisabled={actionPending}>
              {check.isPending ? 'Checking…' : 'Check for updates'}
            </ActionButton>
          ) : null}
        </div>
      </section>

      {check.isError || download.isError || install.isError ? (
        <div className="error-banner" role="alert">
          <strong>Update action failed.</strong>
          <span>{errorMessage(check.error ?? download.error ?? install.error)}</span>
        </div>
      ) : null}

      <ModalOverlay
        className="library-modal-overlay"
        isOpen={confirmInstall}
        isDismissable={!install.isPending}
        onOpenChange={(open) => setConfirmInstall(open)}
      >
        <Modal className="library-modal">
          <Dialog className="library-dialog" role="alertdialog">
            <span className="dialog-kicker">UPDATE READY</span>
            <Heading slot="title">Cancel active work and install?</Heading>
            <p>
              egdata.app will stop active scans, uploads, sync work, and game moves before opening
              the verified installer.
            </p>
            <p className="dialog-detail">
              Completed contribution results stay saved. Interrupted items remain retryable after
              the update.
            </p>
            {install.isError ? (
              <p className="dialog-warning" role="alert">
                {errorMessage(install.error)}
              </p>
            ) : null}
            <div className="dialog-actions">
              <ActionButton onPress={() => setConfirmInstall(false)} isDisabled={install.isPending}>
                Keep working
              </ActionButton>
              <ActionButton
                tone="primary"
                onPress={() => install.mutate(true)}
                isDisabled={install.isPending}
              >
                {install.isPending ? 'Stopping work…' : 'Cancel work and install'}
              </ActionButton>
            </div>
          </Dialog>
        </Modal>
      </ModalOverlay>

      <section className="about-links" aria-label="Product information">
        {links.map(([title, description, url], index) => (
          <Button
            className="about-link"
            key={url}
            onPress={() => void getDesktopApi().app.openExternal(url)}
          >
            <span>0{index + 1}</span>
            <div>
              <strong>{title}</strong>
              <small>{description}</small>
            </div>
            <Icon name="external" className="size-4" />
          </Button>
        ))}
      </section>

      <footer className="about-footer">
        <Icon name="shield" className="size-4" />
        <span>
          Built to keep credentials out of the renderer and personal game files on your device.
        </span>
      </footer>
    </div>
  )
}

function updateTitle(state: string): string {
  const labels: Record<string, string> = {
    idle: 'Ready to check',
    checking: 'Checking GitHub releases',
    'not-available': 'egdata.app is up to date',
    available: 'Update available',
    downloading: 'Downloading update',
    downloaded: 'Update ready to install',
    installing: 'Preparing installation',
    error: 'Update status unavailable',
  }
  return labels[state] ?? 'Update status'
}
