import { QueryClient } from '@tanstack/react-query'
import type { LibraryDetailsRequest, LibraryQueryRequest } from '../../shared/contracts'

import { getDesktopApi } from './desktop-api'

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 15_000,
      retry: 1,
      refetchOnWindowFocus: false,
    },
    mutations: { retry: 0 },
  },
})

export const queryKeys = {
  settings: ['settings'] as const,
  local: ['local-manifests'] as const,
  libraryTools: ['library-tools'] as const,
  auth: ['epic-auth'] as const,
  cloud: ['cloud-sync'] as const,
  library: ['library'] as const,
  libraryStatus: ['library', 'status'] as const,
  libraryPageRoot: ['library', 'page'] as const,
  libraryPage: (request: LibraryQueryRequest) => ['library', 'page', request] as const,
  libraryDetailsRoot: ['library', 'details'] as const,
  libraryDetails: (request: LibraryDetailsRequest) => ['library', 'details', request] as const,
  updates: ['updates'] as const,
  diagnostics: ['diagnostics'] as const,
  app: ['app-info'] as const,
}

export function subscribeToDesktopEvents(): () => void {
  let api
  try {
    api = getDesktopApi()
  } catch {
    return () => undefined
  }

  const cleanups = [
    api.localManifests.onChanged?.((snapshot) => {
      queryClient.setQueryData(queryKeys.local, snapshot)
    }),
    api.libraryTools.onChanged?.((snapshot) => {
      queryClient.setQueryData(queryKeys.libraryTools, snapshot)
    }),
    api.epicAuth.onChanged?.((status) => {
      queryClient.setQueryData(queryKeys.auth, status)
      void queryClient.invalidateQueries({ queryKey: queryKeys.cloud })
    }),
    api.cloudSync.onChanged?.((snapshot) => {
      queryClient.setQueryData(queryKeys.cloud, snapshot)
    }),
    api.library.onChanged?.((event) => {
      queryClient.setQueryData(queryKeys.libraryStatus, event.status)
      void queryClient.invalidateQueries({ queryKey: queryKeys.libraryPageRoot })
      void queryClient.invalidateQueries({ queryKey: queryKeys.libraryDetailsRoot })
    }),
    api.updates.onChanged?.((status) => {
      queryClient.setQueryData(queryKeys.updates, status)
    }),
  ].filter((cleanup): cleanup is () => void => Boolean(cleanup))

  return () => cleanups.forEach((cleanup) => cleanup())
}
