export interface PaginationWindow {
  pageIndex: number
  pageCount: number
  startIndex: number
  endIndex: number
}

export function getPaginationWindow(
  itemCount: number,
  requestedPageIndex: number,
  pageSize: number,
): PaginationWindow {
  const pageCount = Math.max(1, Math.ceil(itemCount / pageSize))
  const pageIndex = Math.min(Math.max(0, requestedPageIndex), pageCount - 1)
  const startIndex = pageIndex * pageSize

  return {
    pageIndex,
    pageCount,
    startIndex,
    endIndex: Math.min(startIndex + pageSize, itemCount),
  }
}
