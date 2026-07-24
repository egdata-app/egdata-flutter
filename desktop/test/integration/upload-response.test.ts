import { describe, expect, it } from 'vitest'

import { classifyUploadResponse } from '../../src/main/uploads/index'

describe('upload response classification', () => {
  for (const alias of ['uploaded', 'success', 'created', 'ok']) {
    it(`classifies ${alias} as uploaded`, () => {
      expect(classifyUploadResponse('item', 200, JSON.stringify({ status: alias })).state).toBe(
        'uploaded',
      )
    })
  }

  for (const alias of ['already_uploaded', 'exists', 'duplicate']) {
    it(`classifies ${alias} as already uploaded`, () => {
      expect(classifyUploadResponse('item', 201, JSON.stringify({ status: alias })).state).toBe(
        'already-uploaded',
      )
    })
  }

  for (const alias of ['failed', 'error']) {
    it(`classifies ${alias} as failed`, () => {
      const result = classifyUploadResponse(
        'item',
        200,
        JSON.stringify({ status: alias, message: 'Rejected' }),
      )
      expect(result.state).toBe('failed')
      expect(result.errorCode).toBe('UPLOAD_REJECTED')
    })
  }

  it('classifies 409 independently of its body', () => {
    expect(classifyUploadResponse('item', 409, '<not-json>').state).toBe('already-uploaded')
  })

  it('rejects malformed or unknown successful responses without message guessing', () => {
    expect(classifyUploadResponse('item', 200, '<html>').errorCode).toBe('UPLOAD_RESPONSE_INVALID')
    expect(
      classifyUploadResponse(
        'item',
        200,
        JSON.stringify({ status: 'unknown', message: 'uploaded successfully' }),
      ).state,
    ).toBe('failed')
  })

  it('only returns bounded, redacted details from rejected JSON responses', () => {
    const result = classifyUploadResponse(
      'item',
      500,
      JSON.stringify({
        status: 'error',
        message: 'access_token=secret https://service.example/path?signature=secret',
      }),
    )
    expect(result.safeDetail).not.toContain('secret')
    expect(result.safeDetail).not.toContain('https://')
  })
})
