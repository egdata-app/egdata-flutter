import { describe, expect, it } from 'vitest'

import { getPaginationWindow } from '../../src/renderer/lib/pagination'

describe('getPaginationWindow', () => {
  it('limits a large list to the requested page size', () => {
    expect(getPaginationWindow(125, 0, 50)).toEqual({
      pageIndex: 0,
      pageCount: 3,
      startIndex: 0,
      endIndex: 50,
    })
    expect(getPaginationWindow(125, 2, 50)).toEqual({
      pageIndex: 2,
      pageCount: 3,
      startIndex: 100,
      endIndex: 125,
    })
  })

  it('clamps the page after filtering or removing items', () => {
    expect(getPaginationWindow(12, 4, 50)).toEqual({
      pageIndex: 0,
      pageCount: 1,
      startIndex: 0,
      endIndex: 12,
    })
  })

  it('returns a stable empty page', () => {
    expect(getPaginationWindow(0, 0, 50)).toEqual({
      pageIndex: 0,
      pageCount: 1,
      startIndex: 0,
      endIndex: 0,
    })
  })
})
