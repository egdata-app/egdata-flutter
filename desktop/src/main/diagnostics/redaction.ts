const SECRET_KEY_PATTERN =
  /(?:access|refresh|id)?_?token|authorization|cookie|secret|password|authorization_?code|client_?secret|signature|x-amz-/i
const AUTHORIZATION_PATTERN = /\b(?:Bearer|Basic)\s+[A-Za-z0-9._~+/=-]+/gi
const COOKIE_HEADER_PATTERN = /\b(?:set-cookie|cookie)\s*:\s*[^\r\n]+/gi
const JWT_PATTERN = /\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b/g
const SENSITIVE_QUERY_PATTERN =
  /([?&#](?:access_token|refresh_token|token|code|authorization|signature|policy|key-pair-id|x-amz-[^=&#]+)=)[^&#\s]*/gi
const SENSITIVE_JSON_PATTERN =
  /(["'](?:access_token|refresh_token|authorization_code|code|token|cookie|authorization|signature)["']\s*:\s*["'])[^"']*/gi
const WINDOWS_PATH_PATTERN = /(?:[A-Za-z]:\\|\\\\)[^\s"'<>|]+/g
const USER_POSIX_PATH_PATTERN = /\/(?:Users|home|private|var\/folders|tmp)\/[^\s"'<>]+/g

const MAX_DEPTH = 6
const MAX_ARRAY_ITEMS = 100
const MAX_OBJECT_KEYS = 100
const MAX_STRING_LENGTH = 4_096

export interface RedactionOptions {
  readonly includePaths?: boolean
}

export function redactValue(value: unknown, options: RedactionOptions = {}, depth = 0): unknown {
  if (depth > MAX_DEPTH) return '[TRUNCATED_DEPTH]'
  if (typeof value === 'string') return redactString(value, options)
  if (typeof value === 'number' || typeof value === 'boolean' || value === null) return value
  if (value instanceof Error) {
    return {
      name: value.name,
      message: redactString(value.message, options),
    }
  }
  if (Array.isArray(value)) {
    const redacted = value
      .slice(0, MAX_ARRAY_ITEMS)
      .map((item) => redactValue(item, options, depth + 1))
    if (value.length > MAX_ARRAY_ITEMS)
      redacted.push(`[TRUNCATED_${value.length - MAX_ARRAY_ITEMS}_ITEMS]`)
    return redacted
  }
  if (typeof value === 'object' && value !== null) {
    const entries = Object.entries(value).slice(0, MAX_OBJECT_KEYS)
    const redacted: Record<string, unknown> = {}
    for (const [key, item] of entries) {
      redacted[key] = SECRET_KEY_PATTERN.test(key)
        ? '[REDACTED]'
        : redactValue(item, options, depth + 1)
    }
    if (Object.keys(value).length > MAX_OBJECT_KEYS) redacted._truncated = true
    return redacted
  }
  if (typeof value === 'bigint') return value.toString()
  if (typeof value === 'symbol') return `[SYMBOL:${value.description ?? ''}]`
  if (typeof value === 'function') return `[FUNCTION:${value.name || 'anonymous'}]`
  return '[UNDEFINED]'
}

export function redactString(value: string, options: RedactionOptions = {}): string {
  let redacted = value
    .replace(AUTHORIZATION_PATTERN, '[REDACTED_AUTHORIZATION]')
    .replace(COOKIE_HEADER_PATTERN, '[REDACTED_COOKIE]')
    .replace(JWT_PATTERN, '[REDACTED_TOKEN]')
    .replace(SENSITIVE_QUERY_PATTERN, '$1[REDACTED]')
    .replace(SENSITIVE_JSON_PATTERN, '$1[REDACTED]')

  if (!options.includePaths) {
    redacted = redacted
      .replace(WINDOWS_PATH_PATTERN, '[REDACTED_PATH]')
      .replace(USER_POSIX_PATH_PATTERN, '[REDACTED_PATH]')
  }

  return redacted.length > MAX_STRING_LENGTH
    ? `${redacted.slice(0, MAX_STRING_LENGTH)}[TRUNCATED]`
    : redacted
}
