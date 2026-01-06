import 'package:flutter_test/flutter_test.dart';
import 'package:egdata_flutter/models/api/free_game.dart';

void main() {
  group('Giveaway', () {
    group('isActive', () {
      test('returns true when now is between start and end', () {
        final giveaway = Giveaway(
          startDate: DateTime.now().subtract(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 1)),
        );
        expect(giveaway.isActive, isTrue);
      });

      test('returns false when now is before start', () {
        final giveaway = Giveaway(
          startDate: DateTime.now().add(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 2)),
        );
        expect(giveaway.isActive, isFalse);
      });

      test('returns false when now is after end', () {
        final giveaway = Giveaway(
          startDate: DateTime.now().subtract(const Duration(days: 2)),
          endDate: DateTime.now().subtract(const Duration(days: 1)),
        );
        expect(giveaway.isActive, isFalse);
      });

      test('returns false when start time is in future by 1 second', () {
        // Use a small future offset to avoid race conditions
        final giveaway = Giveaway(
          startDate: DateTime.now().add(const Duration(seconds: 1)),
          endDate: DateTime.now().add(const Duration(days: 1)),
        );
        expect(giveaway.isActive, isFalse);
      });

      test('returns false when end time is in past by 1 second', () {
        // Use a small past offset to avoid race conditions
        final giveaway = Giveaway(
          startDate: DateTime.now().subtract(const Duration(days: 1)),
          endDate: DateTime.now().subtract(const Duration(seconds: 1)),
        );
        expect(giveaway.isActive, isFalse);
      });
    });

    group('isPast', () {
      test('returns true when end date is in the past', () {
        final giveaway = Giveaway(
          startDate: DateTime.now().subtract(const Duration(days: 2)),
          endDate: DateTime.now().subtract(const Duration(days: 1)),
        );
        expect(giveaway.isPast, isTrue);
      });

      test('returns false when end date is in the future', () {
        final giveaway = Giveaway(
          startDate: DateTime.now().subtract(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 1)),
        );
        expect(giveaway.isPast, isFalse);
      });

      test('returns false when end time is in future by 1 second', () {
        final giveaway = Giveaway(
          startDate: DateTime.now().subtract(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(seconds: 1)),
        );
        expect(giveaway.isPast, isFalse);
      });
    });

    group('isFuture', () {
      test('returns true when start date is in the future', () {
        final giveaway = Giveaway(
          startDate: DateTime.now().add(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 2)),
        );
        expect(giveaway.isFuture, isTrue);
      });

      test('returns false when start date is in the past', () {
        final giveaway = Giveaway(
          startDate: DateTime.now().subtract(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 1)),
        );
        expect(giveaway.isFuture, isFalse);
      });

      test('returns false when start time is in past by 1 second', () {
        final giveaway = Giveaway(
          startDate: DateTime.now().subtract(const Duration(seconds: 1)),
          endDate: DateTime.now().add(const Duration(days: 1)),
        );
        expect(giveaway.isFuture, isFalse);
      });
    });

    group('dateRange', () {
      test('formats date range correctly', () {
        final giveaway = Giveaway(
          startDate: DateTime(2024, 12, 25),
          endDate: DateTime(2025, 1, 1),
        );
        expect(giveaway.dateRange, 'Dec 25, 2024 - Jan 1, 2025');
      });

      test('formats same month dates', () {
        final giveaway = Giveaway(
          startDate: DateTime(2024, 6, 15),
          endDate: DateTime(2024, 6, 22),
        );
        expect(giveaway.dateRange, 'Jun 15, 2024 - Jun 22, 2024');
      });
    });

    group('compactDate', () {
      test('returns formatted start date', () {
        final giveaway = Giveaway(
          startDate: DateTime(2024, 3, 10),
          endDate: DateTime(2024, 3, 17),
        );
        expect(giveaway.compactDate, 'Mar 10, 2024');
      });
    });

    group('fromJson', () {
      test('parses JSON correctly', () {
        final json = {
          'id': 'giveaway-123',
          'namespace': 'epic',
          'startDate': '2024-12-25T00:00:00.000Z',
          'endDate': '2025-01-01T00:00:00.000Z',
          'title': 'Holiday Giveaway',
        };
        final giveaway = Giveaway.fromJson(json);
        expect(giveaway.id, 'giveaway-123');
        expect(giveaway.namespace, 'epic');
        expect(giveaway.startDate.year, 2024);
        expect(giveaway.startDate.month, 12);
        expect(giveaway.startDate.day, 25);
        expect(giveaway.title, 'Holiday Giveaway');
      });
    });

    group('toJson', () {
      test('serializes correctly', () {
        final giveaway = Giveaway(
          id: 'test-id',
          namespace: 'test-ns',
          startDate: DateTime.utc(2024, 1, 1),
          endDate: DateTime.utc(2024, 1, 8),
          title: 'Test Giveaway',
        );
        final json = giveaway.toJson();
        expect(json['id'], 'test-id');
        expect(json['namespace'], 'test-ns');
        expect(json['startDate'], '2024-01-01T00:00:00.000Z');
        expect(json['endDate'], '2024-01-08T00:00:00.000Z');
        expect(json['title'], 'Test Giveaway');
      });
    });
  });
}
