import { describe, expect, it } from 'vitest'

import { queryKeys } from './query'

const request = {
  text: 'game',
  page: 1,
  pageSize: 48,
  installed: 'all' as const,
  genreIds: [],
  featureIds: [],
  typeIds: [],
  platformIds: [],
  subscriptionIds: [],
  sortField: 'title' as const,
  sortDirection: 'asc' as const,
}

describe('Library renderer query keys', () => {
  it('isolates pages and filters while sharing the Library prefix', () => {
    const first = queryKeys.libraryPage(request)
    const second = queryKeys.libraryPage({
      ...request,
      page: 2,
      installed: 'installed',
      platformIds: ['windows'],
    })

    expect(first.slice(0, 2)).toEqual(['library', 'page'])
    expect(second.slice(0, 2)).toEqual(['library', 'page'])
    expect(first).not.toEqual(second)
  })

  it('keys details by opaque identifier', () => {
    const first = queryKeys.libraryDetails({ id: 'record-one' })
    const second = queryKeys.libraryDetails({ id: 'record-two' })

    expect(first).not.toEqual(second)
    expect(first).toEqual(['library', 'details', { id: 'record-one' }])
  })
})
