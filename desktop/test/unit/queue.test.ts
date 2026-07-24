import { describe, expect, it, vi } from 'vitest'

import { InMemoryQueue, type QueueTaskResult } from '../../src/main/queue'

function deferred<T>() {
  let resolve!: (value: T) => void
  let reject!: (error: unknown) => void
  const promise = new Promise<T>((resolvePromise, rejectPromise) => {
    resolve = resolvePromise
    reject = rejectPromise
  })
  return { promise, resolve, reject }
}

const inputs = (count: number) =>
  Array.from({ length: count }, (_, index) => ({
    id: `item-${index}`,
    value: index,
    title: `Item ${index}`,
  }))

describe('InMemoryQueue', () => {
  it('enforces default concurrency five and emits immutable snapshots', async () => {
    const active = new Map<number, ReturnType<typeof deferred<QueueTaskResult>>>()
    let maximum = 0
    const queue = new InMemoryQueue<number>({
      process: async (value) => {
        const operation = deferred<QueueTaskResult>()
        active.set(value, operation)
        maximum = Math.max(maximum, active.size)
        const result = await operation.promise
        active.delete(value)
        return result
      },
    })
    queue.add(inputs(6))
    const run = queue.start()
    await vi.waitFor(() => expect(active.size).toBe(5))

    expect(queue.snapshot.progress.running).toBe(5)
    expect(queue.snapshot.progress.pending).toBe(1)
    expect(Object.isFrozen(queue.snapshot.items)).toBe(true)
    active.get(0)!.resolve({ state: 'uploaded' })
    await vi.waitFor(() => expect(active.has(5)).toBe(true))
    for (const operation of active.values()) operation.resolve({ state: 'uploaded' })
    await run

    expect(maximum).toBe(5)
    expect(queue.snapshot.state).toBe('completed')
    expect(queue.snapshot.progress.uploaded).toBe(6)
  })

  it('supports a one-worker override for scheduled starts and retries', async () => {
    const attempts = new Map<number, number>()
    const active = new Map<number, ReturnType<typeof deferred<QueueTaskResult>>>()
    let maximum = 0
    const queue = new InMemoryQueue<number>({
      process: async (value) => {
        const attempt = (attempts.get(value) ?? 0) + 1
        attempts.set(value, attempt)
        if (attempt === 1) throw new Error('retry later')
        const operation = deferred<QueueTaskResult>()
        active.set(value, operation)
        maximum = Math.max(maximum, active.size)
        const result = await operation.promise
        active.delete(value)
        return result
      },
    })
    queue.add(inputs(3))
    await queue.start({ concurrency: 1 })
    expect(queue.snapshot.items.every((item) => item.state === 'failed')).toBe(true)

    const retry = queue.retry(undefined, { concurrency: 1 })
    await vi.waitFor(() => expect(active.size).toBe(1))
    while (queue.snapshot.progress.terminal < 3) {
      active.values().next().value?.resolve({ state: 'uploaded' })
      await vi.waitFor(() =>
        expect(active.size === 1 || queue.snapshot.progress.terminal === 3).toBe(true),
      )
    }
    await retry

    expect(maximum).toBe(1)
    expect(queue.snapshot.concurrency).toBe(1)
    expect(queue.snapshot.progress.uploaded).toBe(3)
  })

  it('pauses after active work and resumes pending work', async () => {
    const first = deferred<QueueTaskResult>()
    const queue = new InMemoryQueue<number>({
      concurrency: 1,
      process: (value) =>
        value === 0 ? first.promise : Promise.resolve({ state: 'alreadyUploaded' }),
    })
    queue.add(inputs(2))
    const run = queue.start()
    await vi.waitFor(() => expect(queue.snapshot.items[0]!.state).toBe('running'))

    queue.pause()
    expect(queue.snapshot.state).toBe('pausing')
    first.resolve({ state: 'uploaded' })
    await run

    expect(queue.snapshot.state).toBe('paused')
    expect(queue.snapshot.items.map((item) => item.state)).toEqual(['uploaded', 'pending'])
    await queue.resume()
    expect(queue.snapshot.items.map((item) => item.state)).toEqual(['uploaded', 'alreadyUploaded'])
  })

  it('actively aborts running work and cancels pending work', async () => {
    let activeSignal: AbortSignal | null = null
    const queue = new InMemoryQueue<number>({
      concurrency: 1,
      process: async (_value, { signal }) => {
        activeSignal = signal
        await new Promise<void>((_resolve, reject) => {
          signal.addEventListener(
            'abort',
            () => reject(new DOMException('Aborted', 'AbortError')),
            { once: true },
          )
        })
        return { state: 'uploaded' }
      },
    })
    queue.add(inputs(3))
    void queue.start()
    await vi.waitFor(() => expect(activeSignal).not.toBeNull())

    await queue.cancel()

    expect((activeSignal as AbortSignal | null)?.aborted).toBe(true)
    expect(queue.snapshot.state).toBe('cancelled')
    expect(queue.snapshot.items.map((item) => item.state)).toEqual([
      'cancelled',
      'cancelled',
      'cancelled',
    ])
  })

  it('retries selected eligible entries while preserving attempts', async () => {
    const calls = new Map<number, number>()
    const queue = new InMemoryQueue<number>({
      process: (value) => {
        const call = (calls.get(value) ?? 0) + 1
        calls.set(value, call)
        if (call > 1) return Promise.resolve({ state: 'uploaded' })
        if (value === 0) return Promise.reject(new Error('temporary failure'))
        return Promise.resolve({ state: 'skipped', message: 'No cloud manifest' })
      },
    })
    queue.add(inputs(2))
    await queue.start()
    expect(queue.snapshot.items.map((item) => item.state)).toEqual(['failed', 'skipped'])

    await queue.retry(new Set(['item-0']))

    expect(queue.snapshot.items.map((item) => item.state)).toEqual(['uploaded', 'skipped'])
    expect(queue.snapshot.items.map((item) => item.attempts)).toEqual([2, 1])
  })

  it('restores durable item state and makes interrupted work pending', async () => {
    const processed: number[] = []
    const queue = new InMemoryQueue<number>({
      process: (value) => {
        processed.push(value)
        return Promise.resolve({ state: 'uploaded' })
      },
    })
    queue.restore([
      {
        id: 'complete',
        value: 1,
        title: 'Complete',
        state: 'uploaded',
        attempts: 1,
        createdAt: '2026-01-01T00:00:00.000Z',
        startedAt: '2026-01-01T00:00:01.000Z',
        finishedAt: '2026-01-01T00:00:02.000Z',
        error: null,
        message: 'Uploaded',
      },
      {
        id: 'interrupted',
        value: 2,
        title: 'Interrupted',
        state: 'running',
        attempts: 2,
        createdAt: '2026-01-01T00:00:00.000Z',
        startedAt: '2026-01-01T00:00:03.000Z',
        finishedAt: null,
        error: null,
        message: null,
      },
    ])

    expect(queue.snapshot.items.map((item) => item.state)).toEqual(['uploaded', 'pending'])
    expect(queue.snapshot.items.map((item) => item.attempts)).toEqual([1, 2])
    await queue.start()
    expect(processed).toEqual([2])
    expect(queue.snapshot.items.map((item) => item.state)).toEqual(['uploaded', 'uploaded'])
  })

  it('removes only non-running entries and clears terminal entries', async () => {
    const running = deferred<QueueTaskResult>()
    const queue = new InMemoryQueue<number>({
      concurrency: 1,
      process: (value) => (value === 0 ? running.promise : Promise.resolve({ state: 'uploaded' })),
    })
    queue.add(inputs(2))
    const run = queue.start()
    await vi.waitFor(() => expect(queue.snapshot.items[0]!.state).toBe('running'))
    queue.remove(new Set(['item-0', 'item-1']))
    expect(queue.snapshot.items.map((item) => item.state)).toEqual(['running', 'removed'])
    running.resolve({ state: 'uploaded' })
    await run

    queue.clearCompleted()
    expect(queue.snapshot.items).toHaveLength(0)
    expect(queue.snapshot.state).toBe('idle')
  })

  it('caps event history at 200 and redacts unsafe errors', async () => {
    const queue = new InMemoryQueue<number>({
      process: () =>
        Promise.reject(
          new Error('failed https://signed.invalid/file?signature=secret Bearer private-token'),
        ),
    })
    queue.add(inputs(205))
    await queue.start()

    expect(queue.snapshot.events).toHaveLength(200)
    expect(queue.snapshot.items[0]!.error).not.toContain('signed.invalid')
    expect(queue.snapshot.items[0]!.error).not.toContain('private-token')
  })
})
