import 'package:egdata_flutter/hooks/use_handled_infinite_query.dart';
import 'package:egdata_flutter/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluquery/fluquery.dart';

void main() {
  testWidgets('initial API failure stays in query state and can be retried', (
    tester,
  ) async {
    var fail = true;
    late UseInfiniteQueryResult<int, Object, int> result;
    final client = QueryClient();
    await tester.pumpWidget(
      QueryClientProvider(
        client: client,
        child: MaterialApp(
          home: HookBuilder(
            builder: (context) {
              result = useHandledInfiniteQuery<int, Object, int>(
                queryKey: ['initial-failure'],
                queryFn: (_) async {
                  if (fail) throw ApiException('Search failed', 504);
                  return 42;
                },
                initialPageParam: 1,
                getNextPageParam: (_, _, _, _) => null,
              );
              return Text(result.isError ? 'Search failed' : '${result.pages}');
            },
          ),
        ),
      ),
    );
    await tester.pump();
    expect(result.isError, isTrue);
    expect(result.error, isA<ApiException>());
    expect(find.text('Search failed'), findsOneWidget);
    expect(tester.takeException(), isNull);

    fail = false;
    await result.refetch();
    await tester.pump();
    expect(result.pages, [42]);
    expect(result.isError, isFalse);
  });

  testWidgets('pagination failure preserves loaded pages without escaping', (
    tester,
  ) async {
    late UseInfiniteQueryResult<int, Object, int> result;
    final client = QueryClient();
    await tester.pumpWidget(
      QueryClientProvider(
        client: client,
        child: MaterialApp(
          home: HookBuilder(
            builder: (context) {
              result = useHandledInfiniteQuery<int, Object, int>(
                queryKey: ['pagination-failure'],
                queryFn: (ctx) async {
                  if (ctx.pageParam == 2) {
                    throw ApiException('Network unavailable');
                  }
                  return 1;
                },
                initialPageParam: 1,
                getNextPageParam: (_, _, lastParam, _) => lastParam! + 1,
              );
              return Text('${result.pages}');
            },
          ),
        ),
      ),
    );
    await tester.pump();
    expect(result.pages, [1]);
    await result.fetchNextPage();
    await tester.pump();
    expect(result.pages, [1]);
    expect(result.isError, isTrue);
    expect(result.isFetchingNextPage, isFalse);
    expect(tester.takeException(), isNull);
  });
}
