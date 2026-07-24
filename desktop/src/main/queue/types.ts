export type QueueItemState =
  | 'pending'
  | 'running'
  | 'uploaded'
  | 'alreadyUploaded'
  | 'failed'
  | 'skipped'
  | 'cancelled'
  | 'removed'

export type QueueRunState = 'idle' | 'running' | 'pausing' | 'paused' | 'completed' | 'cancelled'

export type QueueSuccessfulResultState = 'uploaded' | 'alreadyUploaded' | 'skipped'

export interface QueueTaskResult {
  state: QueueSuccessfulResultState
  message?: string
}

export interface QueueInput<T> {
  id: string
  value: T
  title?: string
}

export interface QueueRestoreInput<T> extends QueueInput<T> {
  state: QueueItemState
  attempts: number
  createdAt: string
  startedAt: string | null
  finishedAt: string | null
  error: string | null
  message: string | null
}

export interface QueueItemSnapshot<T> {
  id: string
  value: T
  title: string
  state: QueueItemState
  attempts: number
  createdAt: string
  startedAt: string | null
  finishedAt: string | null
  error: string | null
  message: string | null
}

export type QueueEventType =
  | 'added'
  | 'started'
  | 'finished'
  | 'failed'
  | 'pauseRequested'
  | 'paused'
  | 'resumed'
  | 'cancelled'
  | 'retried'
  | 'removed'
  | 'cleared'
  | 'completed'

export interface QueueEventSnapshot {
  sequence: number
  timestamp: string
  type: QueueEventType
  itemId: string | null
  message: string | null
}

export interface QueueProgressSnapshot {
  total: number
  pending: number
  running: number
  uploaded: number
  alreadyUploaded: number
  failed: number
  skipped: number
  cancelled: number
  removed: number
  terminal: number
  elapsedMs: number
}

export interface QueueSnapshot<T> {
  state: QueueRunState
  concurrency: number
  startedAt: string | null
  finishedAt: string | null
  items: ReadonlyArray<QueueItemSnapshot<T>>
  progress: QueueProgressSnapshot
  events: ReadonlyArray<QueueEventSnapshot>
}

export interface QueueRunOptions {
  concurrency?: number
}

export type QueueProcessor<T> = (
  value: T,
  context: {
    id: string
    attempt: number
    signal: AbortSignal
  },
) => Promise<QueueTaskResult>

export interface InMemoryQueueOptions<T> {
  process: QueueProcessor<T>
  concurrency?: number
  maxEvents?: number
  now?: () => number
  sanitizeError?: (error: unknown) => string
}
