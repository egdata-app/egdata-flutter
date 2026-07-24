import { beforeAll, beforeEach, describe, expect, it, vi } from 'vitest'

import type { DesktopApi } from '../shared/api'
import type { LibraryStatus } from '../shared/contracts'
import { IPC_CHANNELS } from '../shared/ipc'

const electronMock = vi.hoisted(() => {
  const state = {
    exposed: undefined as unknown,
    listeners: new Map<string, (...args: unknown[]) => void>(),
  }
  const invoke = vi.fn()
  const removeListener = vi.fn()
  const on = vi.fn((channel: string, listener: (...args: unknown[]) => void) => {
    state.listeners.set(channel, listener)
  })
  const exposeInMainWorld = vi.fn((_name: string, value: unknown) => {
    state.exposed = value
  })

  return {
    state,
    contextBridge: { exposeInMainWorld },
    ipcRenderer: { invoke, on, removeListener },
  }
})

vi.mock('electron', () => ({
  contextBridge: electronMock.contextBridge,
  ipcRenderer: electronMock.ipcRenderer,
}))

let desktopApi: DesktopApi

function readyStatus(): LibraryStatus {
  return {
    state: 'ready',
    total: 4,
    owned: 3,
    installed: 2,
    partialMetadata: 1,
    signedIn: true,
    localScanState: 'complete',
    lastRefreshedAt: '2026-07-20T10:01:00.000Z',
    taxonomyUpdatedAt: '2026-07-20T10:01:00.000Z',
    warnings: [],
  }
}

const request = {
  text: '',
  page: 1,
  pageSize: 50,
  installed: 'all' as const,
  genreIds: [],
  featureIds: [],
  typeIds: [],
  platformIds: [],
  subscriptionIds: [],
  sortField: 'title' as const,
  sortDirection: 'asc' as const,
}

describe('Library preload bridge', () => {
  beforeAll(async () => {
    await import('./index')
    desktopApi = electronMock.state.exposed as DesktopApi
  })

  beforeEach(() => {
    electronMock.ipcRenderer.invoke.mockReset()
    electronMock.ipcRenderer.removeListener.mockReset()
    electronMock.state.listeners.clear()
  })

  it('rejects an oversized search request before IPC invocation', async () => {
    await expect(desktopApi.library.query({ ...request, pageSize: 101 })).rejects.toThrow()

    expect(electronMock.ipcRenderer.invoke).not.toHaveBeenCalled()
  })

  it('validates search responses from the main process', async () => {
    electronMock.ipcRenderer.invoke.mockResolvedValueOnce({
      items: [],
      total: -1,
      page: 1,
      pageSize: 50,
      hasMore: false,
    })

    await expect(desktopApi.library.query({ ...request, text: 'game' })).rejects.toThrow()

    expect(electronMock.ipcRenderer.invoke).toHaveBeenCalledWith(IPC_CHANNELS.library.query, {
      ...request,
      text: 'game',
    })
  })

  it('drops invalid status events and removes the exact listener', () => {
    const listener = vi.fn()
    const unsubscribe = desktopApi.library.onChanged(listener)
    const handler = electronMock.state.listeners.get(IPC_CHANNELS.library.changedEvent)

    expect(handler).toBeTypeOf('function')
    handler?.({}, { status: { state: 'ready' } })
    expect(listener).not.toHaveBeenCalled()

    const status = readyStatus()
    handler?.({}, { status })
    expect(listener).toHaveBeenCalledWith({ status })

    unsubscribe()
    expect(electronMock.ipcRenderer.removeListener).toHaveBeenCalledWith(
      IPC_CHANNELS.library.changedEvent,
      handler,
    )
  })

  it('validates update installation requests before invoking the main process', async () => {
    await expect(desktopApi.updates.install({ cancelActiveWork: 'yes' } as never)).rejects.toThrow()
    expect(electronMock.ipcRenderer.invoke).not.toHaveBeenCalled()

    electronMock.ipcRenderer.invoke.mockResolvedValueOnce({ outcome: 'confirmation-required' })
    await expect(desktopApi.updates.install({ cancelActiveWork: false })).resolves.toEqual({
      outcome: 'confirmation-required',
    })
    expect(electronMock.ipcRenderer.invoke).toHaveBeenCalledWith(IPC_CHANNELS.updates.install, {
      cancelActiveWork: false,
    })
  })
})
