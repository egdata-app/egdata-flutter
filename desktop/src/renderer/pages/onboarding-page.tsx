import { useMutation, useQuery } from '@tanstack/react-query'
import { useNavigate } from '@tanstack/react-router'
import { Checkbox } from 'react-aria-components'

import { getDesktopApi, errorMessage } from '../lib/desktop-api'
import { queryClient, queryKeys } from '../lib/query'
import { EgdataAppIcon } from '../components/egdata-app-icon'
import { ActionButton, StatePanel } from '../components/ui'
import { Icon } from '../components/icons'

export function OnboardingPage() {
  const navigate = useNavigate()
  const settings = useQuery({
    queryKey: queryKeys.settings,
    queryFn: () => getDesktopApi().settings.get(),
  })
  const complete = useMutation({
    mutationFn: (consent: boolean) =>
      getDesktopApi().settings.update({ onboardingComplete: true, contributionConsent: consent }),
    onSuccess: async (value) => {
      queryClient.setQueryData(queryKeys.settings, value)
      await navigate({ to: '/contributions/local' })
    },
  })

  if (settings.isLoading) {
    return (
      <div className="onboarding">
        <StatePanel
          loading
          title="Preparing egdata.app"
          message="Reading your private contribution settings…"
        />
      </div>
    )
  }

  if (settings.isError) {
    return (
      <div className="onboarding">
        <StatePanel
          title="egdata.app could not start"
          message={errorMessage(settings.error)}
          action={
            <ActionButton
              icon="retry"
              onPress={() => {
                void settings.refetch()
              }}
            >
              Try again
            </ActionButton>
          }
        />
      </div>
    )
  }

  const consent = settings.data?.contributionConsent ?? false

  return (
    <main className="onboarding">
      <div className="onboarding-orbit" aria-hidden="true" />
      <header className="onboarding-brand">
        <EgdataAppIcon className="brand-icon" />
        <span>
          <strong>egdata.app</strong>
          <small>CONTRIBUTOR</small>
        </span>
      </header>

      <section className="onboarding-copy">
        <p className="eyebrow">A SMALL FILE. A BETTER CATALOG.</p>
        <h1>
          Contribute what Epic
          <br />
          doesn’t publish.
        </h1>
        <p className="onboarding-lead">
          Manifests describe game builds. Sharing them helps egdata.app track versions and history
          without uploading your games, saves, or personal files.
        </p>
      </section>

      <section className="onboarding-modes" aria-label="Contribution modes">
        <article>
          <span className="mode-number">01</span>
          <Icon name="archive" className="size-6" />
          <h2>Local source</h2>
          <p>
            Reads Epic Launcher <code>.item</code> records and their matching binary manifests from
            expected folders.
          </p>
        </article>
        <article>
          <span className="mode-number">02</span>
          <Icon name="cloud" className="size-6" />
          <h2>Cloud source</h2>
          <p>
            Optionally connect Epic to find manifests for your complete library. Credentials never
            enter this page.
          </p>
        </article>
        <article>
          <span className="mode-number">03</span>
          <Icon name="shield" className="size-6" />
          <h2>You decide</h2>
          <p>
            Review discoveries before upload. Only manifest metadata and binary manifest files are
            contributed.
          </p>
        </article>
      </section>

      <footer className="onboarding-consent">
        <Checkbox
          isSelected={consent}
          onChange={(value) =>
            queryClient.setQueryData(queryKeys.settings, {
              ...settings.data!,
              contributionConsent: value,
            })
          }
          className="consent-check"
        >
          <span className="checkbox-box" aria-hidden="true">
            {consent ? '✓' : ''}
          </span>
          <span>
            I understand and allow manifest contributions. This can be changed in Settings.
          </span>
        </Checkbox>
        <div className="onboarding-actions">
          {complete.isError ? (
            <span className="inline-error">{errorMessage(complete.error)}</span>
          ) : null}
          <ActionButton
            tone="quiet"
            onPress={() => complete.mutate(false)}
            isDisabled={complete.isPending}
          >
            Continue without consent
          </ActionButton>
          <ActionButton
            tone="primary"
            icon="chevron"
            onPress={() => complete.mutate(true)}
            isDisabled={!consent || complete.isPending}
          >
            {complete.isPending ? 'Saving…' : 'Start contributing'}
          </ActionButton>
        </div>
      </footer>
    </main>
  )
}
