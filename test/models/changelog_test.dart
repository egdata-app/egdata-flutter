import 'package:flutter_test/flutter_test.dart';
import 'package:egdata_flutter/models/api/changelog.dart';

void main() {
  group('Change', () {
    group('fieldLabel', () {
      test('converts camelCase to Title Case', () {
        final change = Change(changeType: 'update', field: 'effectiveDate');
        expect(change.fieldLabel, 'Effective Date');
      });

      test('handles single word', () {
        final change = Change(changeType: 'update', field: 'title');
        expect(change.fieldLabel, 'Title');
      });

      test('handles empty field', () {
        final change = Change(changeType: 'update', field: '');
        expect(change.fieldLabel, '');
      });

      test('handles multiple uppercase letters', () {
        final change = Change(changeType: 'update', field: 'keyImages');
        expect(change.fieldLabel, 'Key Images');
      });
    });

    group('changeTypeLabel', () {
      test('returns Added for insert', () {
        final change = Change(changeType: 'insert', field: 'title');
        expect(change.changeTypeLabel, 'Added');
      });

      test('returns Removed for delete', () {
        final change = Change(changeType: 'delete', field: 'title');
        expect(change.changeTypeLabel, 'Removed');
      });

      test('returns Updated for update', () {
        final change = Change(changeType: 'update', field: 'title');
        expect(change.changeTypeLabel, 'Updated');
      });

      test('returns Updated for unknown type', () {
        final change = Change(changeType: 'unknown', field: 'title');
        expect(change.changeTypeLabel, 'Updated');
      });
    });

    group('changeTypeColor', () {
      test('returns green for insert', () {
        final change = Change(changeType: 'insert', field: 'title');
        expect(change.changeTypeColor, 0xFF10B981);
      });

      test('returns red for delete', () {
        final change = Change(changeType: 'delete', field: 'title');
        expect(change.changeTypeColor, 0xFFEF4444);
      });

      test('returns blue for update', () {
        final change = Change(changeType: 'update', field: 'title');
        expect(change.changeTypeColor, 0xFF3B82F6);
      });
    });

    group('changeText', () {
      test('formats insert with new value', () {
        final change = Change(
          changeType: 'insert',
          field: 'title',
          newValue: 'New Game',
        );
        expect(change.changeText, 'New Game');
      });

      test('formats delete with old value', () {
        final change = Change(
          changeType: 'delete',
          field: 'title',
          oldValue: 'Old Game',
        );
        expect(change.changeText, 'Old Game');
      });

      test('formats update with arrow', () {
        final change = Change(
          changeType: 'update',
          field: 'title',
          oldValue: 'Old Title',
          newValue: 'New Title',
        );
        expect(change.changeText, 'Old Title → New Title');
      });

      test('formats price field from cents to dollars', () {
        final change = Change(
          changeType: 'update',
          field: 'discountPrice',
          oldValue: 5999,
          newValue: 2999,
        );
        expect(change.changeText, '\$59.99 → \$29.99');
      });

      test('formats date field', () {
        final change = Change(
          changeType: 'update',
          field: 'releaseDate',
          oldValue: '2024-01-15T00:00:00.000Z',
          newValue: '2024-06-20T00:00:00.000Z',
        );
        expect(change.changeText, 'Jan 15, 2024 → Jun 20, 2024');
      });

      test('formats size field in bytes', () {
        final change = Change(
          changeType: 'update',
          field: 'installSize',
          oldValue: 512,
          newValue: 1024,
        );
        expect(change.changeText, '512 B → 1.0 KB');
      });

      test('formats size field in KB', () {
        final change = Change(
          changeType: 'update',
          field: 'fileSize',
          oldValue: 1024 * 500,
          newValue: 1024 * 1024,
        );
        expect(change.changeText, '500.0 KB → 1.0 MB');
      });

      test('formats size field in MB', () {
        final change = Change(
          changeType: 'update',
          field: 'downloadSize',
          oldValue: 1024 * 1024 * 100,
          newValue: 1024 * 1024 * 500,
        );
        expect(change.changeText, '100.0 MB → 500.0 MB');
      });

      test('formats size field in GB', () {
        final change = Change(
          changeType: 'update',
          field: 'totalBytes',
          oldValue: 1024 * 1024 * 1024 * 2,
          newValue: 1024 * 1024 * 1024 * 5,
        );
        expect(change.changeText, '2.00 GB → 5.00 GB');
      });

      test('formats boolean values', () {
        final change = Change(
          changeType: 'update',
          field: 'isCodeRedemptionOnly',
          oldValue: false,
          newValue: true,
        );
        expect(change.changeText, 'No → Yes');
      });

      test('formats list values', () {
        final change = Change(
          changeType: 'update',
          field: 'tags',
          oldValue: ['a', 'b'],
          newValue: ['a', 'b', 'c', 'd'],
        );
        expect(change.changeText, '2 items → 4 items');
      });

      test('formats image map with type', () {
        final change = Change(
          changeType: 'insert',
          field: 'keyImages',
          newValue: {'type': 'DieselGameBox', 'url': 'http://example.com'},
        );
        expect(change.changeText, 'DieselGameBox');
      });

      test('formats tag map with name', () {
        final change = Change(
          changeType: 'insert',
          field: 'tags',
          newValue: {'id': '123', 'name': 'Action'},
        );
        expect(change.changeText, 'Action');
      });

      test('handles null values', () {
        final change = Change(
          changeType: 'update',
          field: 'title',
          oldValue: null,
          newValue: 'New Title',
        );
        expect(change.changeText, 'New Title');
      });

      test('handles both null values', () {
        final change = Change(
          changeType: 'update',
          field: 'title',
          oldValue: null,
          newValue: null,
        );
        expect(change.changeText, '');
      });
    });

    group('fromJson', () {
      test('parses complete JSON', () {
        final json = {
          'changeType': 'update',
          'field': 'title',
          'oldValue': 'Old',
          'newValue': 'New',
        };
        final change = Change.fromJson(json);
        expect(change.changeType, 'update');
        expect(change.field, 'title');
        expect(change.oldValue, 'Old');
        expect(change.newValue, 'New');
      });

      test('handles missing fields with defaults', () {
        final json = <String, dynamic>{};
        final change = Change.fromJson(json);
        expect(change.changeType, 'update');
        expect(change.field, '');
      });
    });
  });

  group('ChangelogItem', () {
    group('relativeTime', () {
      test('returns Just now for less than 1 minute', () {
        final item = ChangelogItem(
          id: '1',
          timestamp: DateTime.now().subtract(const Duration(seconds: 30)),
          metadata: ChangelogMetadata(
            contextType: '',
            contextId: '',
            changes: [],
          ),
        );
        expect(item.relativeTime, 'Just now');
      });

      test('returns singular minute', () {
        final item = ChangelogItem(
          id: '1',
          timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
          metadata: ChangelogMetadata(
            contextType: '',
            contextId: '',
            changes: [],
          ),
        );
        expect(item.relativeTime, '1 minute ago');
      });

      test('returns plural minutes', () {
        final item = ChangelogItem(
          id: '1',
          timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
          metadata: ChangelogMetadata(
            contextType: '',
            contextId: '',
            changes: [],
          ),
        );
        expect(item.relativeTime, '45 minutes ago');
      });

      test('returns singular hour', () {
        final item = ChangelogItem(
          id: '1',
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          metadata: ChangelogMetadata(
            contextType: '',
            contextId: '',
            changes: [],
          ),
        );
        expect(item.relativeTime, '1 hour ago');
      });

      test('returns plural hours', () {
        final item = ChangelogItem(
          id: '1',
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
          metadata: ChangelogMetadata(
            contextType: '',
            contextId: '',
            changes: [],
          ),
        );
        expect(item.relativeTime, '5 hours ago');
      });

      test('returns singular day', () {
        final item = ChangelogItem(
          id: '1',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          metadata: ChangelogMetadata(
            contextType: '',
            contextId: '',
            changes: [],
          ),
        );
        expect(item.relativeTime, '1 day ago');
      });

      test('returns plural days', () {
        final item = ChangelogItem(
          id: '1',
          timestamp: DateTime.now().subtract(const Duration(days: 15)),
          metadata: ChangelogMetadata(
            contextType: '',
            contextId: '',
            changes: [],
          ),
        );
        expect(item.relativeTime, '15 days ago');
      });

      test('returns singular month', () {
        final item = ChangelogItem(
          id: '1',
          timestamp: DateTime.now().subtract(const Duration(days: 35)),
          metadata: ChangelogMetadata(
            contextType: '',
            contextId: '',
            changes: [],
          ),
        );
        expect(item.relativeTime, '1 month ago');
      });

      test('returns plural months', () {
        final item = ChangelogItem(
          id: '1',
          timestamp: DateTime.now().subtract(const Duration(days: 180)),
          metadata: ChangelogMetadata(
            contextType: '',
            contextId: '',
            changes: [],
          ),
        );
        expect(item.relativeTime, '6 months ago');
      });

      test('returns singular year', () {
        final item = ChangelogItem(
          id: '1',
          timestamp: DateTime.now().subtract(const Duration(days: 400)),
          metadata: ChangelogMetadata(
            contextType: '',
            contextId: '',
            changes: [],
          ),
        );
        expect(item.relativeTime, '1 year ago');
      });

      test('returns plural years', () {
        final item = ChangelogItem(
          id: '1',
          timestamp: DateTime.now().subtract(const Duration(days: 800)),
          metadata: ChangelogMetadata(
            contextType: '',
            contextId: '',
            changes: [],
          ),
        );
        expect(item.relativeTime, '2 years ago');
      });
    });

    group('formattedDate', () {
      test('formats date correctly', () {
        final item = ChangelogItem(
          id: '1',
          timestamp: DateTime(2024, 12, 25),
          metadata: ChangelogMetadata(
            contextType: '',
            contextId: '',
            changes: [],
          ),
        );
        expect(item.formattedDate, 'Dec 25, 2024');
      });

      test('formats January correctly', () {
        final item = ChangelogItem(
          id: '1',
          timestamp: DateTime(2025, 1, 1),
          metadata: ChangelogMetadata(
            contextType: '',
            contextId: '',
            changes: [],
          ),
        );
        expect(item.formattedDate, 'Jan 1, 2025');
      });
    });
  });
}
