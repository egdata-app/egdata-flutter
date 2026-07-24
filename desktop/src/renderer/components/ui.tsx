import type { ReactNode } from 'react'
import { Button, type ButtonProps } from 'react-aria-components'

import { Icon, type IconName } from './icons'
import type { ResultSummary } from '../lib/desktop-api'
import { formatDate } from '../lib/format'

export function ActionButton({
  children,
  icon,
  tone = 'quiet',
  className = '',
  ...props
}: Omit<ButtonProps, 'children' | 'className'> & {
  children: ReactNode
  icon?: IconName
  tone?: 'primary' | 'quiet' | 'danger'
  className?: string
}) {
  return (
    <Button className={`action-button action-${tone} ${className}`} {...props}>
      {icon ? <Icon name={icon} className="size-4" /> : null}
      {children}
    </Button>
  )
}

export function PageHeading({
  eyebrow,
  title,
  description,
  actions,
}: {
  eyebrow: string
  title: string
  description: string
  actions?: ReactNode
}) {
  return (
    <header className="page-heading">
      <div className="min-w-0">
        <p className="eyebrow">{eyebrow}</p>
        <h1>{title}</h1>
        <p className="page-description">{description}</p>
      </div>
      {actions ? <div className="heading-actions">{actions}</div> : null}
    </header>
  )
}

export function StatePanel({
  title,
  message,
  action,
  loading = false,
}: {
  title: string
  message: string
  action?: ReactNode
  loading?: boolean
}) {
  return (
    <section className="state-panel" aria-live="polite" aria-busy={loading}>
      <span className={loading ? 'state-orbit animate-spin' : 'state-orbit'} aria-hidden="true" />
      <div>
        <h2>{title}</h2>
        <p>{message}</p>
      </div>
      {action}
    </section>
  )
}

export function ResultLedger({ summary }: { summary: ResultSummary | undefined }) {
  const cells = [
    ['Uploaded', summary?.uploaded ?? 0, 'success'],
    ['Already present', summary?.alreadyPresent ?? 0, 'neutral'],
    ['Skipped', summary?.skipped ?? 0, 'warning'],
    ['Failed', summary?.failed ?? 0, 'danger'],
  ] as const

  return (
    <section className="result-ledger" aria-label="Latest contribution result">
      <div className="ledger-label">
        <span>Latest result</span>
        <small>{summary?.finishedAt ? formatDate(summary.finishedAt) : 'No run yet'}</small>
      </div>
      {cells.map(([label, value, tone]) => (
        <div className={`ledger-cell ledger-${tone}`} key={label}>
          <strong>{value}</strong>
          <span>{label}</span>
        </div>
      ))}
    </section>
  )
}

export function StatusDot({ state }: { state: 'good' | 'busy' | 'warn' | 'bad' }) {
  return <span className={`status-dot status-${state}`} aria-hidden="true" />
}
