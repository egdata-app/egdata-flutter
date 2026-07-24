import {
  createHashHistory,
  createRootRoute,
  createRoute,
  createRouter,
  redirect,
} from '@tanstack/react-router'

import { RootLayout } from '../components/app-shell'
import { OnboardingPage } from '../pages/onboarding-page'
import { LocalPage } from '../pages/local-page'
import { LibraryToolsPage } from '../pages/library-tools-page'
import { CloudPage } from '../pages/cloud-page'
import { LibraryPage } from '../pages/library-page'
import { SettingsPage } from '../pages/settings-page'
import { AboutPage } from '../pages/about-page'
import { EntryPage, NotFoundPage } from '../pages/system-pages'

const rootRoute = createRootRoute({ component: RootLayout, notFoundComponent: NotFoundPage })

const indexRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/',
  component: EntryPage,
})
const onboardingRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/onboarding',
  component: OnboardingPage,
})
const localRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/contributions/local',
  component: LocalPage,
})
const cloudRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/contributions/cloud',
  component: CloudPage,
})
const libraryRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/library',
  component: LibraryPage,
})
const catalogRedirectRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/catalog',
  beforeLoad: () => {
    throw redirect({ to: '/library', replace: true })
  },
})
const libraryToolsRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/library-tools',
  component: LibraryToolsPage,
})
const settingsRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/settings',
  component: SettingsPage,
})
const aboutRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/about',
  component: AboutPage,
})

const routeTree = rootRoute.addChildren([
  indexRoute,
  onboardingRoute,
  localRoute,
  cloudRoute,
  libraryRoute,
  catalogRedirectRoute,
  libraryToolsRoute,
  settingsRoute,
  aboutRoute,
])

export const router = createRouter({
  routeTree,
  history: createHashHistory(),
  defaultPreload: 'intent',
})

declare module '@tanstack/react-router' {
  interface Register {
    router: typeof router
  }
}
