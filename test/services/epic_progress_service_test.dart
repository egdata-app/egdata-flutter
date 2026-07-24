import 'dart:convert';

import 'package:egdata_flutter/models/epic_progress.dart';
import 'package:egdata_flutter/services/epic_auth_service.dart';
import 'package:egdata_flutter/services/epic_progress_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('EpicProgressService', () {
    test('requires Epic login before proof can run', () async {
      SharedPreferences.setMockInitialValues({});

      final service = EpicProgressService(authService: EpicAuthService());
      final result = await service.verifyOfficialProgressAccess();

      expect(result.status, EpicProgressProofStatus.unauthenticated);
      expect(result.needsLogin, isTrue);
    });

    test(
      'blocks authenticated users until a product achievement probe runs',
      () async {
        SharedPreferences.setMockInitialValues({
          'epic_access_token': 'test-token',
          'epic_account_id': 'test-account',
        });

        final service = EpicProgressService(
          authService: EpicAuthService(),
          client: MockClient((request) async {
            expect(request.method, 'GET');
            expect(request.url.path, endsWith('/test-account/all'));
            return http.Response('[]', 200);
          }),
        );
        final result = await service.verifyOfficialProgressAccess();

        expect(result.status, EpicProgressProofStatus.blocked);
        expect(result.isBlocked, isTrue);
        expect(result.message, contains('product-specific'));
        expect(result.evidence, isNotEmpty);
      },
    );

    test('loads official playtime and player achievement progress', () async {
      SharedPreferences.setMockInitialValues({
        'epic_access_token': 'test-token',
        'epic_account_id': 'test-account',
      });

      final service = EpicProgressService(
        authService: EpicAuthService(),
        client: MockClient((request) async {
          if (request.method == 'GET') {
            return http.Response(
              jsonEncode([
                {
                  'accountId': 'test-account',
                  'artifactId': 'Fortnite',
                  'totalTime': 7200,
                },
              ]),
              200,
            );
          }

          expect(request.method, 'POST');
          expect(request.url.toString(), 'https://store.epicgames.com/graphql');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['variables'], {
            'epicAccountId': 'test-account',
            'productId': 'prod-fn',
          });
          return http.Response(
            jsonEncode({
              'data': {
                'PlayerProfile': {
                  'playerProfile': {
                    'productAchievements': {
                      '__typename': 'PlayerProductAchievementsResponseSuccess',
                      'data': {
                        'epicAccountId': 'test-account',
                        'sandboxId': 'fn',
                        'totalXP': 100,
                        'totalUnlocked': 1,
                        'achievementSets': [],
                        'playerAwards': [],
                        'playerAchievements': [
                          {
                            'playerAchievement': {
                              'achievementName': 'First drop',
                              'epicAccountId': 'test-account',
                              'progress': 100,
                              'sandboxId': 'fn',
                              'unlocked': true,
                              'unlockDate': '2026-01-01T00:00:00Z',
                              'XP': 100,
                              'achievementSetId': 'base',
                              'isBase': true,
                            },
                          },
                          {
                            'playerAchievement': {
                              'achievementName': 'Second drop',
                              'epicAccountId': 'test-account',
                              'progress': 0,
                              'sandboxId': 'fn',
                              'unlocked': false,
                              'unlockDate': null,
                              'XP': 0,
                              'achievementSetId': 'base',
                              'isBase': true,
                            },
                          },
                        ],
                      },
                    },
                  },
                },
              },
            }),
            200,
          );
        }),
      );

      final snapshot = await service.loadProgressSnapshot(
        ['catalog-1'],
        artifactIdByCatalogItemId: const {'catalog-1': 'Fortnite'},
        productIdByCatalogItemId: const {'catalog-1': 'prod-fn'},
      );

      expect(snapshot.proof.status, EpicProgressProofStatus.available);
      final progress = snapshot.gamesByCatalogItemId['catalog-1'];
      expect(progress, isNotNull);
      expect(progress!.officialPlaytime, const Duration(hours: 2));
      expect(progress.unlockedAchievements, 1);
      expect(progress.totalAchievements, 2);
      expect(progress.achievementPercent, 0.5);
    });

    test('reuses a fresh progress snapshot without refetching', () async {
      SharedPreferences.setMockInitialValues({
        'epic_access_token': 'test-token',
        'epic_account_id': 'test-account',
      });

      var requestCount = 0;
      final service = EpicProgressService(
        authService: EpicAuthService(),
        client: MockClient((request) async {
          requestCount++;
          if (request.method == 'GET') {
            return http.Response(
              jsonEncode([
                {
                  'accountId': 'test-account',
                  'artifactId': 'Fortnite',
                  'totalTime': 7200,
                },
              ]),
              200,
            );
          }

          return http.Response(
            jsonEncode({
              'data': {
                'PlayerProfile': {
                  'playerProfile': {
                    'productAchievements': {
                      '__typename': 'PlayerProductAchievementsResponseSuccess',
                      'data': {
                        'epicAccountId': 'test-account',
                        'sandboxId': 'fn',
                        'totalUnlocked': 1,
                        'achievementSets': [],
                        'playerAwards': [],
                        'playerAchievements': [
                          {
                            'playerAchievement': {
                              'achievementName': 'First drop',
                              'epicAccountId': 'test-account',
                              'progress': 100,
                              'sandboxId': 'fn',
                              'unlocked': true,
                              'unlockDate': '2026-01-01T00:00:00Z',
                              'XP': 100,
                              'achievementSetId': 'base',
                              'isBase': true,
                            },
                          },
                        ],
                      },
                    },
                  },
                },
              },
            }),
            200,
          );
        }),
      );

      final first = await service.loadProgressSnapshot(
        ['catalog-1'],
        artifactIdByCatalogItemId: const {'catalog-1': 'Fortnite'},
        productIdByCatalogItemId: const {'catalog-1': 'prod-fn'},
      );
      final second = await service.loadProgressSnapshot(
        ['catalog-1'],
        artifactIdByCatalogItemId: const {'catalog-1': 'Fortnite'},
        productIdByCatalogItemId: const {'catalog-1': 'prod-fn'},
      );

      expect(first.proof.status, EpicProgressProofStatus.available);
      expect(second.proof.status, EpicProgressProofStatus.available);
      expect(second.gamesByCatalogItemId['catalog-1'], isNotNull);
      expect(requestCount, 2);
    });

    test('uses injected proof probe for future official integration', () async {
      SharedPreferences.setMockInitialValues({
        'epic_access_token': 'test-token',
        'epic_account_id': 'test-account',
      });

      final service = EpicProgressService(
        authService: EpicAuthService(),
        proofProbe: (_) async => EpicProgressProofResult(
          status: EpicProgressProofStatus.available,
          title: 'Ready',
          message: 'Official progress is available',
          checkedAt: DateTime.utc(2026),
        ),
      );

      final result = await service.verifyOfficialProgressAccess();

      expect(result.status, EpicProgressProofStatus.available);
      expect(result.isAvailable, isTrue);
    });
  });
}
