import 'package:flutter_test/flutter_test.dart';
import 'package:egdata_flutter/models/playtime_stats.dart';

void main() {
  group('PlaytimeStats', () {
    group('formattedTotalPlaytime', () {
      test('formats zero minutes', () {
        final stats = PlaytimeStats(
          totalWeeklyPlaytime: Duration.zero,
          gamesPlayedThisWeek: 0,
          playtimeByGame: {},
        );
        expect(stats.formattedTotalPlaytime, '0m');
      });

      test('formats minutes only (under 1 hour)', () {
        final stats = PlaytimeStats(
          totalWeeklyPlaytime: const Duration(minutes: 30),
          gamesPlayedThisWeek: 1,
          playtimeByGame: {},
        );
        expect(stats.formattedTotalPlaytime, '30m');
      });

      test('formats 59 minutes', () {
        final stats = PlaytimeStats(
          totalWeeklyPlaytime: const Duration(minutes: 59),
          gamesPlayedThisWeek: 1,
          playtimeByGame: {},
        );
        expect(stats.formattedTotalPlaytime, '59m');
      });

      test('formats exactly 1 hour', () {
        final stats = PlaytimeStats(
          totalWeeklyPlaytime: const Duration(hours: 1),
          gamesPlayedThisWeek: 1,
          playtimeByGame: {},
        );
        expect(stats.formattedTotalPlaytime, '1h 0m');
      });

      test('formats hours and minutes', () {
        final stats = PlaytimeStats(
          totalWeeklyPlaytime: const Duration(hours: 1, minutes: 30),
          gamesPlayedThisWeek: 1,
          playtimeByGame: {},
        );
        expect(stats.formattedTotalPlaytime, '1h 30m');
      });

      test('formats many hours', () {
        final stats = PlaytimeStats(
          totalWeeklyPlaytime: const Duration(hours: 72, minutes: 15),
          gamesPlayedThisWeek: 5,
          playtimeByGame: {},
        );
        expect(stats.formattedTotalPlaytime, '72h 15m');
      });

      test('formats hours with 0 minutes', () {
        final stats = PlaytimeStats(
          totalWeeklyPlaytime: const Duration(hours: 5),
          gamesPlayedThisWeek: 2,
          playtimeByGame: {},
        );
        expect(stats.formattedTotalPlaytime, '5h 0m');
      });
    });

    group('hasPlaytime', () {
      test('returns false for zero playtime', () {
        final stats = PlaytimeStats(
          totalWeeklyPlaytime: Duration.zero,
          gamesPlayedThisWeek: 0,
          playtimeByGame: {},
        );
        expect(stats.hasPlaytime, isFalse);
      });

      test('returns true for any playtime', () {
        final stats = PlaytimeStats(
          totalWeeklyPlaytime: const Duration(minutes: 1),
          gamesPlayedThisWeek: 1,
          playtimeByGame: {},
        );
        expect(stats.hasPlaytime, isTrue);
      });

      test('returns false for seconds only (under 1 minute)', () {
        final stats = PlaytimeStats(
          totalWeeklyPlaytime: const Duration(seconds: 59),
          gamesPlayedThisWeek: 1,
          playtimeByGame: {},
        );
        expect(stats.hasPlaytime, isFalse);
      });
    });

    group('empty factory', () {
      test('creates empty stats', () {
        final stats = PlaytimeStats.empty();
        expect(stats.totalWeeklyPlaytime, Duration.zero);
        expect(stats.gamesPlayedThisWeek, 0);
        expect(stats.playtimeByGame, isEmpty);
        expect(stats.mostPlayedGame, isNull);
      });
    });
  });

  group('GamePlaytimeSummary', () {
    group('formattedPlaytime', () {
      test('formats zero minutes', () {
        final summary = GamePlaytimeSummary(
          gameId: 'game1',
          gameName: 'Test Game',
          totalPlaytime: Duration.zero,
        );
        expect(summary.formattedPlaytime, '0m');
      });

      test('formats minutes only', () {
        final summary = GamePlaytimeSummary(
          gameId: 'game1',
          gameName: 'Test Game',
          totalPlaytime: const Duration(minutes: 45),
        );
        expect(summary.formattedPlaytime, '45m');
      });

      test('formats hours and minutes', () {
        final summary = GamePlaytimeSummary(
          gameId: 'game1',
          gameName: 'Test Game',
          totalPlaytime: const Duration(hours: 2, minutes: 30),
        );
        expect(summary.formattedPlaytime, '2h 30m');
      });
    });

    group('shortFormattedPlaytime', () {
      test('formats hours only when hours > 0', () {
        final summary = GamePlaytimeSummary(
          gameId: 'game1',
          gameName: 'Test Game',
          totalPlaytime: const Duration(hours: 5, minutes: 30),
        );
        expect(summary.shortFormattedPlaytime, '5h');
      });

      test('formats minutes when under 1 hour', () {
        final summary = GamePlaytimeSummary(
          gameId: 'game1',
          gameName: 'Test Game',
          totalPlaytime: const Duration(minutes: 45),
        );
        expect(summary.shortFormattedPlaytime, '45m');
      });

      test('formats zero minutes', () {
        final summary = GamePlaytimeSummary(
          gameId: 'game1',
          gameName: 'Test Game',
          totalPlaytime: Duration.zero,
        );
        expect(summary.shortFormattedPlaytime, '0m');
      });
    });
  });
}
