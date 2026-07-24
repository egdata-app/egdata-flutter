import { useEffect } from 'react'
import { Link, Outlet, useRouterState } from '@tanstack/react-router'

import { subscribeToDesktopEvents } from '../lib/query'
import { EgdataAppIcon } from './egdata-app-icon'
import { Icon } from './icons'

const taskLinks = [
  { to: '/contributions/local', label: 'Local', detail: 'On this device', icon: 'archive' },
  { to: '/contributions/cloud', label: 'Cloud', detail: 'Epic library', icon: 'cloud' },
  { to: '/library-tools', label: 'Library tools', detail: 'Move & recover', icon: 'folder' },
  { to: '/library', label: 'Library', detail: 'Owned & installed', icon: 'files' },
] as const

const utilityLinks = [
  { to: '/settings', label: 'Settings', icon: 'settings' },
  { to: '/about', label: 'About', icon: 'info' },
] as const

export function RootLayout() {
  const pathname = useRouterState({ select: (state) => state.location.pathname })
  const isAboutPage = pathname === '/about'

  useEffect(() => subscribeToDesktopEvents(), [])

  if (pathname === '/onboarding') {
    return (
      <div className="window-shell">
        <div className="window-titlebar" aria-hidden="true" />
        <div className="window-content">
          <Outlet />
        </div>
      </div>
    )
  }

  return (
    <div className="window-shell">
      <div className="window-titlebar" aria-hidden="true" />
      <div className="window-content">
        <div className="app-frame">
          <aside className="source-rail">
            <Link
              to="/contributions/local"
              className="brand app-interactive"
              aria-label="egdata.app contributions"
            >
              <EgdataAppIcon className="brand-icon" />
              <span className="brand-copy">
                <strong>egdata.app</strong>
                <small>CONTRIBUTOR</small>
              </span>
            </Link>

            <div className="rail-context">
              <span>Workspace</span>
              <i />
            </div>

            <nav aria-label="Contribution sources" className="task-nav">
              {taskLinks.map((item, index) => (
                <Link
                  key={item.to}
                  to={item.to}
                  className="task-link app-interactive"
                  activeProps={{ className: 'task-link task-link-active app-interactive' }}
                >
                  <span className="task-index">0{index + 1}</span>
                  <Icon name={item.icon} className="size-5" />
                  <span>
                    <strong>{item.label}</strong>
                    <small>{item.detail}</small>
                  </span>
                </Link>
              ))}
            </nav>

            <nav aria-label="Application" className="utility-nav">
              {utilityLinks.map((item) => (
                <Link
                  key={item.to}
                  to={item.to}
                  className="utility-link app-interactive"
                  activeProps={{ className: 'utility-link utility-link-active app-interactive' }}
                >
                  <Icon name={item.icon} className="size-4" />
                  <span>{item.label}</span>
                </Link>
              ))}
            </nav>
          </aside>

          <div className={isAboutPage ? 'workspace workspace-about' : 'workspace'}>
            {isAboutPage ? null : (
              <div className="title-strip">
                <span>MANIFEST CONTRIBUTION CONSOLE</span>
                <span className="title-health">
                  <i /> Secure bridge
                </span>
              </div>
            )}
            <main
              id="main-content"
              className={
                pathname === '/contributions/local' || pathname === '/library'
                  ? 'page-scroll page-scroll-contained'
                  : 'page-scroll'
              }
            >
              <Outlet />
            </main>
          </div>
        </div>
      </div>
    </div>
  )
}
