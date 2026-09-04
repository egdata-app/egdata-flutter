import 'dart:async';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluquery/fluquery.dart';

/// Keeps query failures in fluquery's error state without leaving an unhandled
/// future from its automatic initial fetch or a UI pagination callback.
UseInfiniteQueryResult<TData, TError, TPageParam>
useHandledInfiniteQuery<TData, TError, TPageParam>({
  required QueryKey queryKey,
  required Future<TData> Function(QueryFnContext) queryFn,
  required TPageParam? initialPageParam,
  required GetNextPageParamFn<TData, TPageParam> getNextPageParam,
  StaleTime staleTime = StaleTime.zero,
}) {
  final client = useQueryClient();
  final result = useInfiniteQuery<TData, TError, TPageParam>(
    queryKey: queryKey,
    queryFn: queryFn,
    initialPageParam: initialPageParam,
    getNextPageParam: getNextPageParam,
    staleTime: staleTime,
    // fluquery 1.3.3 starts query.fetch() without handling its returned future.
    // Start the same fetch below, retaining the package's cache and error state.
    enabled: false,
  );
  final query = client.getOrCreateInfiniteQuery<TData, TError, TPageParam>(
    queryKey: queryKey,
    initialPageParam: initialPageParam,
  );

  Future<List<TData>> handle(Future<List<TData>> Function() fetch) async {
    try {
      return await fetch();
    } catch (_) {
      // InfiniteQuery has already stored the error and notified its observers.
      return query.state.pages;
    }
  }

  useEffect(() {
    if ((!query.state.hasData || query.isStale) && !query.state.isFetching) {
      unawaited(handle(query.fetch));
    }
    return null;
  }, [query]);

  return UseInfiniteQueryResult.fromState(
    query.state,
    fetchNextPage: () => handle(result.fetchNextPage),
    fetchPreviousPage: () => handle(result.fetchPreviousPage),
    refetch: () => handle(result.refetch),
  );
}
