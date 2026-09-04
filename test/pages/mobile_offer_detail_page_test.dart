import 'dart:async';
import 'dart:convert';

import 'package:egdata_flutter/models/followed_game.dart';
import 'package:egdata_flutter/pages/mobile_offer_detail_page.dart';
import 'package:egdata_flutter/services/api_service.dart';
import 'package:egdata_flutter/services/follow_service.dart';
import 'package:egdata_flutter/widgets/follow_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  Future<_PendingFollowService> showOffer(
    WidgetTester tester, {
    bool following = false,
  }) async {
    final follow = _PendingFollowService(following);
    final api = ApiService(
      client: MockClient((request) async {
        if (request.url.path == '/offers/offer') {
          return http.Response(
            jsonEncode({
              'id': 'offer',
              'namespace': 'test',
              'title': 'Test game',
              'offerType': 'BASE_GAME',
            }),
            200,
          );
        }
        return http.Response('{}', 404);
      }),
    );
    addTearDown(api.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MobileOfferDetailPage(
          offerId: 'offer',
          followService: follow,
          apiService: api,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    tester.widget<FollowButton>(find.byType(FollowButton)).onToggle();
    await tester.pump();
    return follow;
  }

  for (final following in [false, true]) {
    testWidgets(
      '${following ? 'unfollow' : 'follow'} completes safely after leaving the page',
      (tester) async {
        final follow = await showOffer(tester, following: following);
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        follow.completion.complete();
        await tester.pump();
        expect(follow.following, !following);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('failed follow shows feedback and releases the loading state', (
    tester,
  ) async {
    final follow = await showOffer(tester);
    follow.completion.completeError(StateError('Database unavailable'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(
      find.text('Could not update follow status. Please try again.'),
      findsOneWidget,
    );
    final button = tester.widget<FollowButton>(find.byType(FollowButton));
    expect(button.isLoading, isFalse);
    expect(button.isFollowing, isFalse);
  });
}

class _PendingFollowService implements FollowService {
  bool following;
  final completion = Completer<void>();
  _PendingFollowService(this.following);
  @override
  bool isFollowing(String offerId) => following;
  @override
  Future<List<String>> getNotificationTopics(String offerId) async => [];
  @override
  Future<void> followGame(FollowedGame game) async {
    await completion.future;
    following = true;
  }

  @override
  Future<void> unfollowGame(String offerId) async {
    await completion.future;
    following = false;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
