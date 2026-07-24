const MAX_ERROR_LENGTH = 300

export function queueSafeError(error: unknown): string {
  const raw =
    error instanceof Error
      ? error.message
      : typeof error === 'string'
        ? error
        : 'Queue operation failed.'
  const safe = raw
    .replace(/https?:\/\/[^\s"']+/gi, '[URL redacted]')
    .replace(/\bBearer\s+[^\s,;]+/gi, 'Bearer [redacted]')
    .replace(
      /\b(access_token|refresh_token|authorizationCode|code|signature|sig|token)=([^\s&,;]+)/gi,
      '$1=[redacted]',
    )
    .replace(/[\r\n\t]+/g, ' ')
    .trim()
  return (safe || 'Queue operation failed.').slice(0, MAX_ERROR_LENGTH)
}
