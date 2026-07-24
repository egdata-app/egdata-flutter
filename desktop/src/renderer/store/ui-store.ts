import { Store } from '@tanstack/store'

import type { QueueState } from '../lib/desktop-api'

export type QueueFilter = 'all' | QueueState

interface UiState {
  queueFilter: QueueFilter
  selectedLocalIds: string[]
  selectedQueueId: string | undefined
}

export const uiStore = new Store<UiState>({
  queueFilter: 'all',
  selectedLocalIds: [],
  selectedQueueId: undefined,
})

export function setQueueFilter(queueFilter: QueueFilter): void {
  uiStore.setState((state) => ({ ...state, queueFilter }))
}

export function setLocalSelected(id: string, selected: boolean): void {
  uiStore.setState((state) => ({
    ...state,
    selectedLocalIds: selected
      ? Array.from(new Set([...state.selectedLocalIds, id]))
      : state.selectedLocalIds.filter((value) => value !== id),
  }))
}

export function setAllLocalSelected(ids: string[]): void {
  uiStore.setState((state) => ({ ...state, selectedLocalIds: ids }))
}

export function clearLocalSelection(): void {
  uiStore.setState((state) => ({ ...state, selectedLocalIds: [] }))
}

export function setSelectedQueueId(selectedQueueId?: string): void {
  uiStore.setState((state) => ({ ...state, selectedQueueId }))
}
