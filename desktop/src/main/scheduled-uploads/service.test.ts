import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import type { StoredSettings } from '../../shared'
import type { ScheduledUploadSource, ScheduledUploadState } from '../storage'
import { ScheduledUploadService } from './service'

const defaultSettings: StoredSettings = {
  contributionConsent: true,
  automaticUploadsEnabled: true,
  automaticLocalUploadIntervalMinutes: 360,
  automaticCloudUploadIntervalMinutes: 1_440,
  includePathsInDiagnostics: false,
  updateChannel: 'stable',
  automaticallyCheckForUpdates: true,
  automaticallyScanWindowsDrives: true,
  launchAtStartup: false,
}

function memoryState(initial: ScheduledUploadState = { version: 1, lastAttemptAt: {} }) {
  let state = structuredClone(initial)
  return {
    load: vi.fn(async () => structuredClone(state)),
    recordAttempt: vi.fn(async (source: ScheduledUploadSource, attemptedAt: string) => {
      state = {
        version: 1,
        lastAttemptAt: { ...state.lastAttemptAt, [source]: attemptedAt },
      }
    }),
  }
}

describe('ScheduledUploadService', () => {
  beforeEach(() => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date('2026-07-21T10:00:00.000Z'))
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('runs overdue sources serially after the startup grace period with Local first', async () => {
    const active = new Set<ScheduledUploadSource>()
    const order: ScheduledUploadSource[] = []
    let maximumActive = 0
    const service = new ScheduledUploadService({
      stateStorage: memoryState(),
      getSettings: async () => defaultSettings,
      canRun: () => true,
      run: async (source) => {
        active.add(source)
        maximumActive = Math.max(maximumActive, active.size)
        order.push(source)
        await Promise.resolve()
        active.delete(source)
      },
    })

    await service.start()
    expect(order).toEqual([])
    await vi.advanceTimersByTimeAsync(60_000)

    expect(order).toEqual(['local', 'cloud'])
    expect(maximumActive).toBe(1)
    service.dispose()
  })

  it('uses persisted attempts to run the oldest overdue source first', async () => {
    const order: ScheduledUploadSource[] = []
    const service = new ScheduledUploadService({
      stateStorage: memoryState({
        version: 1,
        lastAttemptAt: {
          local: '2026-07-21T03:00:00.000Z',
          cloud: '2026-07-19T10:00:00.000Z',
        },
      }),
      getSettings: async () => defaultSettings,
      canRun: () => true,
      run: async (source) => {
        order.push(source)
      },
      startupGraceMs: 0,
    })

    await service.start()
    expect(order[0]).toBe('cloud')
    service.dispose()
  })

  it('allows Local to run while an overdue signed-out Cloud source stays blocked', async () => {
    const order: ScheduledUploadSource[] = []
    const service = new ScheduledUploadService({
      stateStorage: memoryState(),
      getSettings: async () => defaultSettings,
      canRun: (source) => source === 'local',
      run: async (source) => {
        order.push(source)
      },
      startupGraceMs: 0,
      blockedRetryMs: 300_000,
    })

    await service.start()
    expect(order).toEqual(['local'])
    await vi.advanceTimersByTimeAsync(299_999)
    expect(order).toEqual(['local'])
    service.dispose()
  })

  it('defers busy work without advancing its attempt timestamp', async () => {
    const state = memoryState()
    let available = false
    const run = vi.fn(async () => undefined)
    const service = new ScheduledUploadService({
      stateStorage: state,
      getSettings: async () => defaultSettings,
      canRun: () => available,
      run,
      startupGraceMs: 0,
      blockedRetryMs: 300_000,
    })

    await service.start()
    expect(state.recordAttempt).not.toHaveBeenCalled()
    available = true
    await vi.advanceTimersByTimeAsync(300_000)

    expect(run).toHaveBeenCalled()
    expect(state.recordAttempt).toHaveBeenCalled()
    service.dispose()
  })

  it('keeps schedules dormant without consent', async () => {
    const run = vi.fn(async () => undefined)
    const service = new ScheduledUploadService({
      stateStorage: memoryState(),
      getSettings: async () => ({ ...defaultSettings, contributionConsent: false }),
      canRun: () => true,
      run,
      startupGraceMs: 0,
    })

    await service.start()
    await vi.runAllTimersAsync()
    expect(run).not.toHaveBeenCalled()
    service.dispose()
  })

  it('aborts active scheduled work when cancellation is requested', async () => {
    let activeSignal: AbortSignal | null = null
    const service = new ScheduledUploadService({
      stateStorage: memoryState(),
      getSettings: async () => defaultSettings,
      canRun: (source) => source === 'local',
      run: async (_source, signal) => {
        activeSignal = signal
        await new Promise<void>((resolve) => signal.addEventListener('abort', () => resolve()))
      },
      startupGraceMs: 0,
    })

    const starting = service.start()
    await vi.waitFor(() => expect(activeSignal).not.toBeNull())
    service.cancelActive()
    await starting

    expect((activeSignal as AbortSignal | null)?.aborted).toBe(true)
    service.dispose()
  })
})
