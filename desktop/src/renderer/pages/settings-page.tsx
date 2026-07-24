import { useMutation, useQuery } from '@tanstack/react-query'
import {
  Button,
  ListBox,
  ListBoxItem,
  Popover,
  Select,
  SelectValue,
  Switch,
} from 'react-aria-components'

import { errorMessage, getDesktopApi, type ContributionSettings } from '../lib/desktop-api'
import { queryClient, queryKeys } from '../lib/query'
import { ActionButton, PageHeading, StatePanel } from '../components/ui'
import { Icon } from '../components/icons'

type UploadInterval = ContributionSettings['automaticLocalUploadIntervalMinutes']
type UpdateChannel = ContributionSettings['updateChannel']

const uploadIntervals: Array<{ id: UploadInterval; label: string }> = [
  { id: 60, label: 'Every hour' },
  { id: 180, label: 'Every 3 hours' },
  { id: 360, label: 'Every 6 hours' },
  { id: 720, label: 'Every 12 hours' },
  { id: 1_440, label: 'Every 24 hours' },
  { id: 4_320, label: 'Every 3 days' },
  { id: 10_080, label: 'Every 7 days' },
]

const updateChannels: Array<{ id: UpdateChannel; label: string }> = [
  { id: 'stable', label: 'Stable' },
  { id: 'beta', label: 'Beta' },
]

export function SettingsPage() {
  const settings = useQuery({
    queryKey: queryKeys.settings,
    queryFn: () => getDesktopApi().settings.get(),
  })
  const diagnostics = useQuery({
    queryKey: queryKeys.diagnostics,
    queryFn: () => getDesktopApi().diagnostics.getInfo(),
  })
  const updates = useQuery({
    queryKey: queryKeys.updates,
    queryFn: () => getDesktopApi().updates.getStatus(),
  })
  const update = useMutation({
    mutationFn: (patch: Partial<ContributionSettings>) => getDesktopApi().settings.update(patch),
    onSuccess: (value) => queryClient.setQueryData(queryKeys.settings, value),
  })
  const clearSession = useMutation({
    mutationFn: () => getDesktopApi().settings.clearEpicSession(),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: queryKeys.auth })
      void queryClient.invalidateQueries({ queryKey: queryKeys.cloud })
    },
  })
  const exportLogs = useMutation({
    mutationFn: () =>
      getDesktopApi().diagnostics.export({
        includePaths: settings.data?.shareDiagnosticPaths ?? false,
      }),
  })

  if (settings.isLoading)
    return (
      <StatePanel
        loading
        title="Loading preferences"
        message="Reading the local settings document…"
      />
    )
  if (settings.isError)
    return (
      <StatePanel
        title="Settings unavailable"
        message={errorMessage(settings.error)}
        action={
          <ActionButton
            icon="retry"
            onPress={() => {
              void settings.refetch()
            }}
          >
            Retry
          </ActionButton>
        }
      />
    )

  return (
    <div className="page-stack settings-page">
      <PageHeading
        eyebrow="APPLICATION / CONTROL"
        title="Settings"
        description="Manage contribution consent, startup behavior, Windows library discovery, updates, and local diagnostics."
      />
      {update.isError || clearSession.isError || exportLogs.isError ? (
        <div className="error-banner" role="alert">
          <strong>Action failed.</strong>
          <span>{errorMessage(update.error ?? clearSession.error ?? exportLogs.error)}</span>
        </div>
      ) : null}

      <section className="settings-section" aria-labelledby="contribution-settings">
        <header>
          <span>01</span>
          <div>
            <h2 id="contribution-settings">Contribution & privacy</h2>
            <p>The renderer never reads files or credentials directly.</p>
          </div>
        </header>
        <SettingSwitch
          label="Allow manifest contributions"
          description="Enables local and cloud upload actions. Discovery can still run while disabled."
          selected={settings.data!.contributionConsent}
          onChange={(value) => update.mutate({ contributionConsent: value })}
        />
        <SettingSwitch
          label="Include complete paths in diagnostic exports"
          description="Off by default. Exported logs otherwise redact user directory prefixes."
          selected={settings.data!.shareDiagnosticPaths}
          onChange={(value) => update.mutate({ shareDiagnosticPaths: value })}
        />
      </section>

      <section className="settings-section" aria-labelledby="automatic-upload-settings">
        <header>
          <span>02</span>
          <div>
            <h2 id="automatic-upload-settings">Automatic uploads</h2>
            <p>Low-impact scheduled contribution while egdata.app is running in the tray.</p>
          </div>
        </header>
        <SettingSwitch
          label="Upload manifests automatically"
          description="Requires contribution consent. Cloud uploads also wait for an Epic connection; launch-at-startup remains a separate setting."
          selected={settings.data!.automaticUploadsEnabled}
          onChange={(value) => update.mutate({ automaticUploadsEnabled: value })}
        />
        <SettingSelect
          label="Local manifests"
          description="Rescans the standard Epic manifest directory and uploads valid new content one item at a time."
          value={settings.data!.automaticLocalUploadIntervalMinutes}
          isDisabled={!settings.data!.automaticUploadsEnabled}
          onChange={(value) => update.mutate({ automaticLocalUploadIntervalMinutes: value })}
        />
        <SettingSelect
          label="Cloud manifests"
          description="Refreshes the connected Epic library, then uploads pending or retryable builds one item at a time."
          value={settings.data!.automaticCloudUploadIntervalMinutes}
          isDisabled={!settings.data!.automaticUploadsEnabled}
          onChange={(value) => update.mutate({ automaticCloudUploadIntervalMinutes: value })}
        />
      </section>

      <section className="settings-section" aria-labelledby="library-settings">
        <header>
          <span>03</span>
          <div>
            <h2 id="library-settings">Windows library discovery</h2>
            <p>Recovery candidates always require review and confirmation.</p>
          </div>
        </header>
        <SettingSwitch
          label="Automatically scan Windows drives"
          description="Scans shortly after startup, when a drive appears, and once a day while egdata.app is open."
          selected={settings.data!.automaticallyScanWindowsDrives}
          onChange={(value) => update.mutate({ automaticallyScanWindowsDrives: value })}
        />
      </section>

      <section className="settings-section" aria-labelledby="startup-settings">
        <header>
          <span>04</span>
          <div>
            <h2 id="startup-settings">Startup</h2>
            <p>Keep background discovery and sync services available after sign-in.</p>
          </div>
        </header>
        <SettingSwitch
          label="Launch egdata.app at startup"
          description={
            settings.data!.launchAtStartupAvailable
              ? 'Starts in the system tray without creating an application window.'
              : 'Available in installed Windows and macOS builds. AppX is not supported.'
          }
          selected={settings.data!.launchAtStartup}
          isDisabled={!settings.data!.launchAtStartupAvailable}
          onChange={(value) => update.mutate({ launchAtStartup: value })}
        />
      </section>

      <section className="settings-section" aria-labelledby="update-settings">
        <header>
          <span>05</span>
          <div>
            <h2 id="update-settings">Updates</h2>
            <p>Update installation is never started while manifest work is active.</p>
          </div>
        </header>
        <SettingSwitch
          label="Check for updates automatically"
          description={
            updates.data?.delivery === 'store'
              ? 'Microsoft Store manages updates for this installation.'
              : 'Checks GitHub release metadata once at startup. Windows downloads are verified automatically; you choose when to install.'
          }
          selected={settings.data!.automaticUpdateChecks}
          isDisabled={updates.data?.delivery === 'store'}
          onChange={(value) => update.mutate({ automaticUpdateChecks: value })}
        />
        <UpdateChannelSelect
          value={settings.data!.updateChannel}
          isDisabled={updates.data?.delivery === 'store'}
          onChange={(value) => update.mutate({ updateChannel: value })}
        />
      </section>

      <section className="settings-section" aria-labelledby="diagnostic-settings">
        <header>
          <span>06</span>
          <div>
            <h2 id="diagnostic-settings">Diagnostics</h2>
            <p>Logs exclude tokens, authorization codes, cookies, and signed URLs.</p>
          </div>
        </header>
        <div className="setting-action-row">
          <Icon name="folder" className="size-5" />
          <div>
            <strong>Diagnostic log location</strong>
            <small>
              {diagnostics.isLoading
                ? 'Loading…'
                : (diagnostics.data?.logLocationLabel ?? 'Unavailable')}{' '}
              · {diagnostics.data?.retentionDays ?? '—'} day retention
            </small>
          </div>
          <ActionButton
            onPress={() => {
              void getDesktopApi().diagnostics.openLogLocation()
            }}
          >
            Open location
          </ActionButton>
          <ActionButton
            icon="upload"
            onPress={() => exportLogs.mutate()}
            isDisabled={exportLogs.isPending}
          >
            {exportLogs.isPending ? 'Exporting…' : 'Export logs'}
          </ActionButton>
        </div>
        {exportLogs.data ? (
          <p className="setting-feedback" role="status">
            {exportLogs.data.cancelled
              ? 'Export cancelled.'
              : `Diagnostics exported${exportLogs.data.savedTo ? ` to ${exportLogs.data.savedTo}` : '.'}`}
          </p>
        ) : null}
      </section>

      <section className="settings-section danger-section" aria-labelledby="session-settings">
        <header>
          <span>07</span>
          <div>
            <h2 id="session-settings">Epic session</h2>
            <p>Remove encrypted tokens and Epic authentication cookies from this device.</p>
          </div>
        </header>
        <div className="setting-action-row">
          <Icon name="shield" className="size-5" />
          <div>
            <strong>Clear connected account</strong>
            <small>Local manifests and contribution settings are not affected.</small>
          </div>
          <ActionButton
            tone="danger"
            onPress={() => clearSession.mutate()}
            isDisabled={clearSession.isPending}
          >
            {clearSession.isPending ? 'Clearing…' : 'Clear session'}
          </ActionButton>
        </div>
        {clearSession.isSuccess ? (
          <p className="setting-feedback" role="status">
            Epic session cleared.
          </p>
        ) : null}
      </section>
    </div>
  )
}

function UpdateChannelSelect({
  value,
  isDisabled,
  onChange,
}: {
  value: UpdateChannel
  isDisabled: boolean
  onChange: (value: UpdateChannel) => void
}) {
  return (
    <div className="setting-select-row">
      <span>
        <strong>Release channel</strong>
        <small>Beta includes stable releases and GitHub prereleases.</small>
      </span>
      <Select
        aria-label="Update release channel"
        className="setting-interval-select"
        selectedKey={value}
        isDisabled={isDisabled}
        onSelectionChange={(key) => onChange(String(key) as UpdateChannel)}
      >
        <Button>
          <SelectValue />
          <Icon name="chevron" className="size-3" />
        </Button>
        <Popover className="setting-interval-popover">
          <ListBox items={updateChannels}>
            {(item) => <ListBoxItem id={item.id}>{item.label}</ListBoxItem>}
          </ListBox>
        </Popover>
      </Select>
    </div>
  )
}

function SettingSelect({
  label,
  description,
  value,
  isDisabled,
  onChange,
}: {
  label: string
  description: string
  value: UploadInterval
  isDisabled: boolean
  onChange: (value: UploadInterval) => void
}) {
  return (
    <div className="setting-select-row">
      <span>
        <strong>{label}</strong>
        <small>{description}</small>
      </span>
      <Select
        aria-label={`${label} automatic upload interval`}
        className="setting-interval-select"
        selectedKey={value}
        isDisabled={isDisabled}
        onSelectionChange={(key) => onChange(Number(key) as UploadInterval)}
      >
        <Button>
          <SelectValue />
          <Icon name="chevron" className="size-3" />
        </Button>
        <Popover className="setting-interval-popover">
          <ListBox items={uploadIntervals}>
            {(item) => <ListBoxItem id={item.id}>{item.label}</ListBoxItem>}
          </ListBox>
        </Popover>
      </Select>
    </div>
  )
}

function SettingSwitch({
  label,
  description,
  selected,
  isDisabled = false,
  onChange,
}: {
  label: string
  description: string
  selected: boolean
  isDisabled?: boolean
  onChange: (value: boolean) => void
}) {
  return (
    <Switch
      className="setting-switch"
      isSelected={selected}
      isDisabled={isDisabled}
      onChange={onChange}
    >
      <span className="inline-flex gap-2 justify-center items-center">
        <strong>{label}</strong>
        <small>{description}</small>
      </span>
      <span className="switch-track" aria-hidden="true">
        <i />
      </span>
    </Switch>
  )
}
