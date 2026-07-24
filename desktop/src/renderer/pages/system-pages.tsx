import { useQuery } from '@tanstack/react-query'
import { Link, Navigate } from '@tanstack/react-router'

import { StatePanel } from '../components/ui'
import { getDesktopApi } from '../lib/desktop-api'
import { queryKeys } from '../lib/query'

export function EntryPage() {
  const settings = useQuery({
    queryKey: queryKeys.settings,
    queryFn: () => getDesktopApi().settings.get(),
  })
  if (settings.isLoading)
    return (
      <StatePanel
        loading
        title="Starting egdata.app"
        message="Preparing your contribution workspace…"
      />
    )
  if (settings.isError) return <Navigate to="/onboarding" replace />
  return (
    <Navigate
      to={settings.data!.onboardingComplete ? '/contributions/local' : '/onboarding'}
      replace
    />
  )
}

export function NotFoundPage() {
  return (
    <StatePanel
      title="Page not found"
      message="This destination is not part of the contribution console."
      action={
        <Link className="action-button action-primary" to="/contributions/local">
          Return to local manifests
        </Link>
      }
    />
  )
}
