import 'package:flutter_test/flutter_test.dart';
import 'package:egdata_flutter/models/widget_data.dart';

void main() {
  group('WidgetFreeGame', () {
    group('fromJson', () {
      test('parses complete JSON', () {
        final json = {
          'id': 'game-123',
          'title': 'Test Game',
          'thumbnailUrl': 'https://example.com/thumb.jpg',
          'endDate': '2025-01-15T00:00:00.000Z',
        };
        final game = WidgetFreeGame.fromJson(json);
        expect(game.id, 'game-123');
        expect(game.title, 'Test Game');
        expect(game.thumbnailUrl, 'https://example.com/thumb.jpg');
        expect(game.endDate.year, 2025);
        expect(game.endDate.month, 1);
        expect(game.endDate.day, 15);
      });

      test('handles null thumbnail', () {
        final json = {
          'id': 'game-123',
          'title': 'Test Game',
          'thumbnailUrl': null,
          'endDate': '2025-01-15T00:00:00.000Z',
        };
        final game = WidgetFreeGame.fromJson(json);
        expect(game.thumbnailUrl, isNull);
      });
    });

    group('toJson', () {
      test('serializes correctly', () {
        final game = WidgetFreeGame(
          id: 'game-456',
          title: 'Another Game',
          thumbnailUrl: 'https://example.com/img.png',
          endDate: DateTime.utc(2025, 6, 30),
        );
        final json = game.toJson();
        expect(json['id'], 'game-456');
        expect(json['title'], 'Another Game');
        expect(json['thumbnailUrl'], 'https://example.com/img.png');
        expect(json['endDate'], '2025-06-30T00:00:00.000Z');
      });

      test('handles null thumbnail in serialization', () {
        final game = WidgetFreeGame(
          id: 'game-789',
          title: 'No Thumb Game',
          thumbnailUrl: null,
          endDate: DateTime.utc(2025, 3, 15),
        );
        final json = game.toJson();
        expect(json['thumbnailUrl'], isNull);
      });
    });

    group('round-trip serialization', () {
      test('survives JSON round-trip', () {
        final original = WidgetFreeGame(
          id: 'round-trip-id',
          title: 'Round Trip Game',
          thumbnailUrl: 'https://example.com/roundtrip.jpg',
          endDate: DateTime.utc(2025, 12, 25, 10, 30),
        );
        final json = original.toJson();
        final restored = WidgetFreeGame.fromJson(json);
        expect(restored.id, original.id);
        expect(restored.title, original.title);
        expect(restored.thumbnailUrl, original.thumbnailUrl);
        expect(restored.endDate, original.endDate);
      });
    });
  });

  group('WidgetData', () {
    group('isStale', () {
      test('returns false when less than 6 hours old', () {
        final data = WidgetData(
          games: [],
          lastUpdate: DateTime.now().subtract(const Duration(hours: 5, minutes: 59)),
        );
        expect(data.isStale, isFalse);
      });

      test('returns true when exactly 6 hours old', () {
        final data = WidgetData(
          games: [],
          lastUpdate: DateTime.now().subtract(const Duration(hours: 6)),
        );
        expect(data.isStale, isTrue);
      });

      test('returns true when more than 6 hours old', () {
        final data = WidgetData(
          games: [],
          lastUpdate: DateTime.now().subtract(const Duration(hours: 12)),
        );
        expect(data.isStale, isTrue);
      });

      test('returns false when just updated', () {
        final data = WidgetData(
          games: [],
          lastUpdate: DateTime.now(),
        );
        expect(data.isStale, isFalse);
      });

      test('returns true when 1 day old', () {
        final data = WidgetData(
          games: [],
          lastUpdate: DateTime.now().subtract(const Duration(days: 1)),
        );
        expect(data.isStale, isTrue);
      });
    });

    group('isEmpty', () {
      test('returns true when games list is empty', () {
        final data = WidgetData(
          games: [],
          lastUpdate: DateTime.now(),
        );
        expect(data.isEmpty, isTrue);
      });

      test('returns false when games list has items', () {
        final data = WidgetData(
          games: [
            WidgetFreeGame(
              id: 'game1',
              title: 'Game 1',
              endDate: DateTime.now(),
            ),
          ],
          lastUpdate: DateTime.now(),
        );
        expect(data.isEmpty, isFalse);
      });
    });

    group('JSON serialization', () {
      test('toJson serializes correctly', () {
        final data = WidgetData(
          games: [
            WidgetFreeGame(
              id: 'game1',
              title: 'Game 1',
              thumbnailUrl: 'https://example.com/1.jpg',
              endDate: DateTime.utc(2025, 1, 15),
            ),
            WidgetFreeGame(
              id: 'game2',
              title: 'Game 2',
              endDate: DateTime.utc(2025, 1, 22),
            ),
          ],
          lastUpdate: DateTime.utc(2025, 1, 10, 12, 0),
        );
        final json = data.toJson();
        expect(json['games'], isList);
        expect((json['games'] as List).length, 2);
        expect(json['lastUpdate'], '2025-01-10T12:00:00.000Z');
      });

      test('fromJson parses correctly', () {
        final json = {
          'games': [
            {
              'id': 'game1',
              'title': 'Game 1',
              'thumbnailUrl': 'https://example.com/1.jpg',
              'endDate': '2025-01-15T00:00:00.000Z',
            },
          ],
          'lastUpdate': '2025-01-10T12:00:00.000Z',
        };
        final data = WidgetData.fromJson(json);
        expect(data.games.length, 1);
        expect(data.games[0].id, 'game1');
        expect(data.lastUpdate.year, 2025);
        expect(data.lastUpdate.month, 1);
        expect(data.lastUpdate.day, 10);
      });

      test('toJsonString and fromJsonString round-trip', () {
        final original = WidgetData(
          games: [
            WidgetFreeGame(
              id: 'game1',
              title: 'Test Game',
              thumbnailUrl: 'https://example.com/test.jpg',
              endDate: DateTime.utc(2025, 6, 15),
            ),
          ],
          lastUpdate: DateTime.utc(2025, 6, 1, 8, 30),
        );
        final jsonString = original.toJsonString();
        final restored = WidgetData.fromJsonString(jsonString);
        expect(restored.games.length, original.games.length);
        expect(restored.games[0].id, original.games[0].id);
        expect(restored.games[0].title, original.games[0].title);
        expect(restored.lastUpdate, original.lastUpdate);
      });
    });

    group('empty data', () {
      test('serializes and deserializes empty games list', () {
        final original = WidgetData(
          games: [],
          lastUpdate: DateTime.utc(2025, 1, 1),
        );
        final jsonString = original.toJsonString();
        final restored = WidgetData.fromJsonString(jsonString);
        expect(restored.games, isEmpty);
        expect(restored.isEmpty, isTrue);
      });
    });
  });
}
