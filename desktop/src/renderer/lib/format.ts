export function formatDate(value?: string): string {
  if (!value) return 'Not yet'
  return new Intl.DateTimeFormat(undefined, {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(value))
}

export function formatDuration(value?: number): string {
  if (value === undefined) return '—'
  if (value < 1_000) return `${value} ms`
  const seconds = Math.round(value / 100) / 10
  return seconds < 60 ? `${seconds}s` : `${Math.floor(seconds / 60)}m ${Math.round(seconds % 60)}s`
}
