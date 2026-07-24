import { useState } from 'react'
import { useMutation, useQuery } from '@tanstack/react-query'
import { Checkbox, Dialog, Heading, Modal, ModalOverlay } from 'react-aria-components'

import { Icon } from '../components/icons'
import { ActionButton, PageHeading, StatePanel } from '../components/ui'
import { errorMessage, getDesktopApi } from '../lib/desktop-api'
import { formatDate } from '../lib/format'
import { queryClient, queryKeys } from '../lib/query'

function formatBytes(bytes: number): string {
  if (bytes <= 0) return 'Size unavailable'
  const units = ['B', 'KB', 'MB', 'GB', 'TB']
  const exponent = Math.min(Math.floor(Math.log(bytes) / Math.log(1024)), units.length - 1)
  return `${(bytes / 1024 ** exponent).toFixed(exponent > 2 ? 1 : 0)} ${units[exponent]}`
}

function formatProgressBytes(bytes: number): string {
  return bytes === 0 ? '0 B' : formatBytes(bytes)
}

function formatCount(value: number): string {
  return new Intl.NumberFormat('en-US').format(value)
}

function moveStateLabel(
  state:
    | 'prepared'
    | 'copying'
    | 'updating-launcher'
    | 'deleting-source'
    | 'complete'
    | 'cancelled'
    | 'failed',
): string {
  const labels: Record<string, string> = {
    prepared: 'Ready to move',
    copying: 'Copying files',
    'updating-launcher': 'Updating launcher',
    'deleting-source': 'Cleaning up',
    complete: 'Move complete',
    cancelled: 'Cancelled',
    failed: 'Move failed',
  }
  return labels[state] ?? state.replaceAll('-', ' ')
}

type LauncherProtectedAction =
  | { type: 'prepare-move'; gameId: string }
  | { type: 'recover'; candidateIds: string[] }
  | { type: 'start-move'; operationId: string }

export function LibraryToolsPage() {
  const [selectedCandidates, setSelectedCandidates] = useState<string[]>([])
  const [confirmRecovery, setConfirmRecovery] = useState(false)
  const [launcherAction, setLauncherAction] = useState<LauncherProtectedAction | null>(null)
  const [launcherMessage, setLauncherMessage] = useState<string | null>(null)
  const tools = useQuery({
    queryKey: queryKeys.libraryTools,
    queryFn: () => getDesktopApi().libraryTools.getSnapshot(),
  })
  const storeSnapshot = (snapshot: NonNullable<typeof tools.data>) => {
    queryClient.setQueryData(queryKeys.libraryTools, snapshot)
  }
  const scan = useMutation({
    mutationFn: () => getDesktopApi().libraryTools.scan(),
    onSuccess: storeSnapshot,
  })
  const cancelScan = useMutation({
    mutationFn: () => getDesktopApi().libraryTools.cancelScan(),
    onSuccess: storeSnapshot,
  })
  const recover = useMutation({
    mutationFn: (candidateIds: string[]) => getDesktopApi().libraryTools.recover({ candidateIds }),
    onSuccess: (snapshot) => {
      storeSnapshot(snapshot)
      setSelectedCandidates([])
      setConfirmRecovery(false)
    },
  })
  const prepareMove = useMutation({
    mutationFn: (gameId: string) => getDesktopApi().libraryTools.prepareMove({ gameId }),
    onSuccess: (result) => {
      if (!result.cancelled && result.move && tools.data) {
        storeSnapshot({ ...tools.data, move: result.move })
      }
    },
  })
  const startMove = useMutation({
    mutationFn: (operationId: string) => getDesktopApi().libraryTools.startMove({ operationId }),
    onSuccess: storeSnapshot,
  })
  const cancelMove = useMutation({
    mutationFn: (operationId: string) => getDesktopApi().libraryTools.cancelMove({ operationId }),
    onSuccess: storeSnapshot,
  })
  const launcherCheck = useMutation({
    mutationFn: async (action: LauncherProtectedAction) => {
      const scanSnapshot =
        tools.data?.state === 'scanning'
          ? await getDesktopApi().libraryTools.cancelScan()
          : undefined
      return {
        action,
        status: await getDesktopApi().libraryTools.getLauncherStatus(),
        scanSnapshot,
      }
    },
    onSuccess: ({ action, status, scanSnapshot }) => {
      if (scanSnapshot) storeSnapshot(scanSnapshot)
      if (status.running) {
        setLauncherMessage(null)
        setLauncherAction(action)
      } else {
        setLauncherAction(null)
        executeProtectedAction(action)
      }
    },
  })
  const closeLauncher = useMutation({
    mutationFn: () => getDesktopApi().libraryTools.tryCloseLauncher(),
    onSuccess: (status) => {
      if (status.running) {
        setLauncherMessage(
          'Epic Games Launcher is still open. Use Exit from its system-tray menu, then check again.',
        )
      } else if (launcherAction) {
        const action = launcherAction
        setLauncherAction(null)
        setLauncherMessage(null)
        executeProtectedAction(action)
      }
    },
  })

  function executeProtectedAction(action: LauncherProtectedAction): void {
    if (action.type === 'prepare-move') prepareMove.mutate(action.gameId)
    else if (action.type === 'recover') recover.mutate(action.candidateIds)
    else startMove.mutate(action.operationId)
  }

  if (tools.isLoading) {
    return (
      <StatePanel loading title="Loading library tools" message="Reading Epic launcher records…" />
    )
  }
  if (tools.isError) {
    return (
      <StatePanel
        title="Library tools unavailable"
        message={errorMessage(tools.error)}
        action={<ActionButton onPress={() => void tools.refetch()}>Retry</ActionButton>}
      />
    )
  }

  const snapshot = tools.data!
  if (!snapshot.available) {
    return (
      <StatePanel
        title="Available on Windows"
        message="Game moving and drive recovery are Windows-only in this release."
      />
    )
  }
  const working = snapshot.state !== 'idle' || scan.isPending || recover.isPending
  const blockingWork = working && snapshot.state !== 'scanning'
  const move = snapshot.move
  const scanProgress = snapshot.scanProgress
  const moving = Boolean(
    move && !['prepared', 'complete', 'cancelled', 'failed'].includes(move.state),
  )
  const movePercent = move?.totalBytes
    ? Math.min(100, Math.round((move.copiedBytes / move.totalBytes) * 100))
    : 0
  const recoverableIds = snapshot.candidates
    .filter((candidate) => candidate.recoverable)
    .map((candidate) => candidate.id)
  const selection = selectedCandidates.filter((id) => recoverableIds.includes(id))
  const currentError =
    scan.error ??
    cancelScan.error ??
    recover.error ??
    prepareMove.error ??
    startMove.error ??
    cancelMove.error ??
    launcherCheck.error ??
    closeLauncher.error

  return (
    <div className="page-stack library-tools-page">
      <PageHeading
        eyebrow="WINDOWS / LIBRARY"
        title="Library tools"
        description="Move registered games or recover installations found on local Windows drives. Epic Games Launcher must be closed before changes are made."
        actions={
          <ActionButton
            icon={snapshot.state === 'scanning' ? 'cancel' : 'refresh'}
            onPress={() => (snapshot.state === 'scanning' ? cancelScan.mutate() : scan.mutate())}
            isDisabled={blockingWork || moving || cancelScan.isPending}
          >
            {cancelScan.isPending
              ? 'Stopping…'
              : snapshot.state === 'scanning'
                ? 'Cancel scan'
                : 'Scan drives'}
          </ActionButton>
        }
      />

      {snapshot.state === 'scanning' ? (
        <section
          className="drive-scan-activity"
          aria-labelledby="drive-scan-title"
          aria-live="polite"
        >
          <div className="scan-activity-mark" aria-hidden="true">
            <span />
            <i />
          </div>
          <div className="scan-activity-copy">
            <span className="dialog-kicker">DRIVE DISCOVERY IN PROGRESS</span>
            <h2 id="drive-scan-title">
              {scanProgress?.phase === 'parsing'
                ? 'Reading Epic manifests'
                : scanProgress?.phase === 'resolving'
                  ? 'Matching recovered games'
                  : `Searching ${scanProgress?.currentDrive ?? 'Windows drives'}`}
            </h2>
            <p>
              {scanProgress?.phase === 'discovering'
                ? scanProgress.currentDrive?.toLowerCase() === 'c:\\'
                  ? 'The system drive is limited to Program Files and known Epic installation folders.'
                  : 'Using a low-overhead Windows filesystem pass. Reparse points and protected system folders are skipped.'
                : 'Validating discovered records before anything is offered for recovery.'}
            </p>
            <div
              className={`scan-meter ${scanProgress?.phase === 'discovering' ? 'scan-meter-active' : ''}`}
              aria-hidden="true"
            >
              <span
                style={{
                  width: `${scanProgress?.totalDrives ? (scanProgress.drivesCompleted / scanProgress.totalDrives) * 100 : 0}%`,
                }}
              />
            </div>
          </div>
          <dl className="scan-activity-stats">
            <div>
              <dt>Drives</dt>
              <dd>
                {scanProgress?.drivesCompleted ?? 0}/{scanProgress?.totalDrives ?? 0}
              </dd>
            </div>
            <div>
              <dt>Folders checked</dt>
              <dd>{(scanProgress?.directoriesChecked ?? 0).toLocaleString()}</dd>
            </div>
            <div>
              <dt>Installations</dt>
              <dd>{scanProgress?.manifestDirectories ?? 0}</dd>
            </div>
          </dl>
        </section>
      ) : null}

      <ModalOverlay
        className="library-modal-overlay"
        isOpen={launcherAction !== null}
        isDismissable={!closeLauncher.isPending && !launcherCheck.isPending}
        onOpenChange={(open) => {
          if (!open) {
            setLauncherAction(null)
            setLauncherMessage(null)
          }
        }}
      >
        <Modal className="library-modal">
          <Dialog className="library-dialog" role="alertdialog">
            <span className="dialog-kicker">LAUNCHER IS RUNNING</span>
            <Heading slot="title">Close Epic Games Launcher</Heading>
            <p>
              Epic Games Launcher must be fully closed before egdata.app can update its library
              files.
            </p>
            <p className="dialog-detail">
              “Try to close it” requests a normal Windows close. egdata.app will never force-stop
              the launcher or a game process.
            </p>
            {launcherMessage ? (
              <p className="dialog-warning" role="status">
                {launcherMessage}
              </p>
            ) : null}
            <div className="dialog-actions">
              <ActionButton
                onPress={() => {
                  setLauncherAction(null)
                  setLauncherMessage(null)
                }}
                isDisabled={closeLauncher.isPending || launcherCheck.isPending}
              >
                Cancel
              </ActionButton>
              <ActionButton
                onPress={() => {
                  if (launcherAction) launcherCheck.mutate(launcherAction)
                }}
                isDisabled={closeLauncher.isPending || launcherCheck.isPending}
              >
                {launcherCheck.isPending ? 'Checking…' : 'I closed it — check again'}
              </ActionButton>
              <ActionButton
                tone="primary"
                onPress={() => closeLauncher.mutate()}
                isDisabled={closeLauncher.isPending || launcherCheck.isPending}
              >
                {closeLauncher.isPending ? 'Closing…' : 'Try to close it'}
              </ActionButton>
            </div>
          </Dialog>
        </Modal>
      </ModalOverlay>

      {currentError ? (
        <div className="error-banner" role="alert">
          <strong>Library operation stopped.</strong>
          <span>{errorMessage(currentError)}</span>
        </div>
      ) : null}

      {move ? (
        <section
          className={`library-section move-panel move-state-${move.state}`}
          aria-labelledby="move-progress-title"
        >
          <header className="move-panel-header">
            <div>
              <p className="eyebrow">GAME MOVE</p>
              <h2 id="move-progress-title">{move.displayName}</h2>
            </div>
            <span className={`library-status status-${move.state}`}>
              {moveStateLabel(move.state)}
            </span>
          </header>

          <div className="move-route" aria-label="Installation move locations">
            <div className="move-route-point">
              <span className="move-route-icon" aria-hidden="true">
                <Icon name="folder" className="size-5" />
              </span>
              <div>
                <small>Current location</small>
                <strong title={move.sourceLocation}>{move.sourceLocation}</strong>
              </div>
            </div>
            <Icon name="arrow-right" className="move-route-arrow size-5" />
            <div className="move-route-point move-route-destination">
              <span className="move-route-icon" aria-hidden="true">
                <Icon name="drive" className="size-5" />
              </span>
              <div>
                <small>New location</small>
                <strong title={move.destinationLocation}>{move.destinationLocation}</strong>
              </div>
            </div>
          </div>

          <div className="move-transfer">
            <div className="move-progress-heading">
              <span>{move.state === 'prepared' ? 'Ready to transfer' : 'Transfer progress'}</span>
              <strong>{movePercent}%</strong>
            </div>
            <div
              className="progress-track move-progress-track"
              aria-label={`${move.copiedFiles} of ${move.totalFiles} files copied`}
              aria-valuemin={0}
              aria-valuemax={100}
              aria-valuenow={movePercent}
              role="progressbar"
            >
              <span style={{ width: `${movePercent}%` }} />
            </div>
            <dl className="move-facts">
              <div>
                <dt>Total size</dt>
                <dd>{formatBytes(move.totalBytes)}</dd>
              </div>
              <div>
                <dt>Files</dt>
                <dd>{formatCount(move.totalFiles)}</dd>
              </div>
              <div>
                <dt>Transferred</dt>
                <dd>
                  {formatProgressBytes(move.copiedBytes)} · {formatCount(move.copiedFiles)} files
                </dd>
              </div>
            </dl>
          </div>

          {move.state === 'prepared' ? (
            <footer className="move-confirmation" role="group" aria-labelledby="move-confirm-title">
              <div className="move-confirm-copy">
                <Icon name="info" className="size-5" />
                <div>
                  <strong id="move-confirm-title">Ready to move this installation?</strong>
                  <span>All launcher records that share this game folder will move together.</span>
                </div>
              </div>
              <div className="move-confirm-actions">
                <ActionButton onPress={() => cancelMove.mutate(move.operationId)}>
                  Cancel
                </ActionButton>
                <ActionButton
                  icon="play"
                  tone="primary"
                  onPress={() =>
                    launcherCheck.mutate({ type: 'start-move', operationId: move.operationId })
                  }
                  isDisabled={launcherCheck.isPending}
                >
                  Start move
                </ActionButton>
              </div>
            </footer>
          ) : moving ? (
            <div className="move-panel-actions">
              <ActionButton
                tone="danger"
                onPress={() => cancelMove.mutate(move.operationId)}
                isDisabled={cancelMove.isPending}
              >
                Cancel move
              </ActionButton>
            </div>
          ) : null}
          {move.restartLauncher ? (
            <p className="restart-notice" role="status">
              <strong>Move complete.</strong> Restart Epic Games Launcher to use the new location.
            </p>
          ) : null}
          {move.warning ? (
            <p className="warning-note" role="status">
              {move.warning}
            </p>
          ) : null}
          {move.error ? (
            <p className="warning-note" role="alert">
              {move.error.message}
            </p>
          ) : null}
        </section>
      ) : null}

      <section className="library-section" aria-labelledby="registered-title">
        <header>
          <div>
            <p className="eyebrow">REGISTERED GAMES</p>
            <h2 id="registered-title">Launcher installations</h2>
          </div>
          <span>{snapshot.registeredGames.length} folders</span>
        </header>
        {snapshot.registeredGames.length === 0 ? (
          <p className="library-empty">No movable launcher installations were found.</p>
        ) : (
          <div className="library-list">
            {snapshot.registeredGames.map((game) => (
              <div className="library-row" key={game.id}>
                <div>
                  <strong>{game.displayName}</strong>
                  <small>{game.installLocation}</small>
                </div>
                <span>
                  {game.recordCount} record{game.recordCount === 1 ? '' : 's'} ·{' '}
                  {formatBytes(game.installSize)}
                </span>
                <ActionButton
                  icon="folder"
                  onPress={() => launcherCheck.mutate({ type: 'prepare-move', gameId: game.id })}
                  isDisabled={
                    !game.movable ||
                    blockingWork ||
                    moving ||
                    prepareMove.isPending ||
                    launcherCheck.isPending
                  }
                >
                  Choose destination
                </ActionButton>
              </div>
            ))}
          </div>
        )}
      </section>

      <section className="library-section" aria-labelledby="discovery-title">
        <header>
          <div>
            <p className="eyebrow">DRIVE DISCOVERY</p>
            <h2 id="discovery-title">Recovery review</h2>
          </div>
          <span>Last scan {formatDate(snapshot.scannedAt)}</span>
        </header>
        {snapshot.candidates.length === 0 ? (
          <p className="library-empty">No unregistered installations are waiting for review.</p>
        ) : (
          <div className="library-list">
            {snapshot.candidates.map((candidate) => {
              const selected = selection.includes(candidate.id)
              return (
                <div
                  className={`library-row recovery-row ${candidate.recoverable ? '' : 'row-disabled'}`}
                  key={candidate.id}
                >
                  <Checkbox
                    className="table-check"
                    isSelected={selected}
                    isDisabled={!candidate.recoverable || blockingWork}
                    onChange={(checked) =>
                      setSelectedCandidates((current) =>
                        checked
                          ? [...current, candidate.id]
                          : current.filter((id) => id !== candidate.id),
                      )
                    }
                    aria-label={`Select ${candidate.displayName} for recovery`}
                  >
                    <span className="checkbox-box" aria-hidden="true">
                      {selected ? '✓' : ''}
                    </span>
                  </Checkbox>
                  <div>
                    <strong>{candidate.displayName}</strong>
                    <small>
                      {candidate.installLocation} · {candidate.version || 'Version unknown'}
                    </small>
                  </div>
                  <span>
                    {candidate.recordCount} record{candidate.recordCount === 1 ? '' : 's'} ·{' '}
                    {candidate.status}
                  </span>
                  <small className="candidate-issue">
                    {candidate.issue ??
                      (candidate.recoverable ? 'Ready to register' : 'Review required')}
                  </small>
                </div>
              )
            })}
          </div>
        )}
        <div className="recovery-actions">
          <span>
            {selection.length} selected of {recoverableIds.length} recoverable
          </span>
          <ActionButton
            tone="primary"
            onPress={() => setConfirmRecovery(true)}
            isDisabled={selection.length === 0 || blockingWork || moving}
          >
            Recover selected
          </ActionButton>
        </div>
        {confirmRecovery ? (
          <div
            className="confirmation-panel"
            role="alertdialog"
            aria-labelledby="recovery-confirm-title"
          >
            <div>
              <strong id="recovery-confirm-title">
                Register {selection.length} installation{selection.length === 1 ? '' : 's'}?
              </strong>
              <span>
                Close Epic Games Launcher first. egdata.app will back up and verify every affected
                launcher file.
              </span>
            </div>
            <ActionButton onPress={() => setConfirmRecovery(false)}>Cancel</ActionButton>
            <ActionButton
              tone="primary"
              onPress={() => launcherCheck.mutate({ type: 'recover', candidateIds: selection })}
              isDisabled={recover.isPending || launcherCheck.isPending}
            >
              Confirm recovery
            </ActionButton>
          </div>
        ) : null}
        {recover.isSuccess ? (
          <p className="restart-notice" role="status">
            <strong>Recovery complete.</strong> Restart Epic Games Launcher to load the recovered
            games.
          </p>
        ) : null}
      </section>

      {snapshot.issues.length > 0 ? (
        <section className="issues-panel" aria-labelledby="library-issues-title">
          <header>
            <h2 id="library-issues-title">Discovery issues</h2>
            <span>{snapshot.issues.length}</span>
          </header>
          {snapshot.issues.map((issue, index) => (
            <div className="issue-row" key={`${issue}-${index}`}>
              <p>{issue}</p>
            </div>
          ))}
        </section>
      ) : null}
    </div>
  )
}
