import { describe, expect, it } from 'vitest'

import { redactString, redactValue } from './redaction'

describe('diagnostic redaction', () => {
  it('redacts nested secrets based on their keys', () => {
    expect(
      redactValue({
        accountId: 'safe-id',
        refreshToken: 'secret-token',
        nested: { authorization: 'Bearer abc' },
      }),
    ).toEqual({
      accountId: 'safe-id',
      refreshToken: '[REDACTED]',
      nested: { authorization: '[REDACTED]' },
    })
  })

  it('redacts credentials and signatures embedded in text', () => {
    const value = redactString(
      'Bearer abc.def_123 https://example.test/file?X-Amz-Signature=secret&code=auth-code',
    )
    expect(value).not.toContain('abc.def_123')
    expect(value).not.toContain('secret')
    expect(value).not.toContain('auth-code')
  })

  it('redacts cookie headers and serialized token payloads', () => {
    expect(redactString('Cookie: session=secret; account=123')).toBe('[REDACTED_COOKIE]')
    expect(redactString('{"access_token":"secret-value"}')).not.toContain('secret-value')
  })

  it('redacts complete user paths unless explicitly retained', () => {
    expect(redactString('Opened C:\\Users\\person\\manifest.item')).toBe('Opened [REDACTED_PATH]')
    expect(
      redactString('Opened C:\\Users\\person\\manifest.item', { includePaths: true }),
    ).toContain('C:\\Users\\person')
    expect(redactString('Opened /Users/person/manifest.item')).toBe('Opened [REDACTED_PATH]')
  })
})
