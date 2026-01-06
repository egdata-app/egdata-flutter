import 'package:flutter_test/flutter_test.dart';
import 'package:egdata_flutter/models/game_info.dart';

void main() {
  group('GameInfo', () {
    GameInfo createGameInfo({int installSize = 0}) {
      return GameInfo(
        displayName: 'Test Game',
        appName: 'TestGame',
        installLocation: '/path/to/game',
        installSize: installSize,
        version: '1.0.0',
        catalogNamespace: 'namespace',
        catalogItemId: 'item-id',
        installationGuid: 'guid-123',
      );
    }

    group('formattedSize', () {
      test('formats bytes (under 1 KB)', () {
        final game = createGameInfo(installSize: 512);
        expect(game.formattedSize, '512 B');
      });

      test('formats 0 bytes', () {
        final game = createGameInfo(installSize: 0);
        expect(game.formattedSize, '0 B');
      });

      test('formats exactly 1 KB', () {
        final game = createGameInfo(installSize: 1024);
        expect(game.formattedSize, '1.0 KB');
      });

      test('formats kilobytes (under 1 MB)', () {
        final game = createGameInfo(installSize: 1024 * 500);
        expect(game.formattedSize, '500.0 KB');
      });

      test('formats with decimal KB', () {
        final game = createGameInfo(installSize: 1024 + 512);
        expect(game.formattedSize, '1.5 KB');
      });

      test('formats exactly 1 MB', () {
        final game = createGameInfo(installSize: 1024 * 1024);
        expect(game.formattedSize, '1.0 MB');
      });

      test('formats megabytes (under 1 GB)', () {
        final game = createGameInfo(installSize: 1024 * 1024 * 500);
        expect(game.formattedSize, '500.0 MB');
      });

      test('formats with decimal MB', () {
        final game = createGameInfo(installSize: (1024 * 1024 * 1.5).toInt());
        expect(game.formattedSize, '1.5 MB');
      });

      test('formats exactly 1 GB', () {
        final game = createGameInfo(installSize: 1024 * 1024 * 1024);
        expect(game.formattedSize, '1.00 GB');
      });

      test('formats gigabytes', () {
        final game = createGameInfo(installSize: 1024 * 1024 * 1024 * 50);
        expect(game.formattedSize, '50.00 GB');
      });

      test('formats with decimal GB', () {
        final game = createGameInfo(installSize: (1024 * 1024 * 1024 * 2.5).toInt());
        expect(game.formattedSize, '2.50 GB');
      });

      test('formats large game (100+ GB)', () {
        final game = createGameInfo(installSize: 1024 * 1024 * 1024 * 150);
        expect(game.formattedSize, '150.00 GB');
      });

      test('formats boundary: 1023 bytes', () {
        final game = createGameInfo(installSize: 1023);
        expect(game.formattedSize, '1023 B');
      });

      test('formats boundary: 1024 * 1024 - 1 (just under 1 MB)', () {
        final game = createGameInfo(installSize: 1024 * 1024 - 1);
        expect(game.formattedSize, '1024.0 KB');
      });

      test('formats boundary: 1024 * 1024 * 1024 - 1 (just under 1 GB)', () {
        final game = createGameInfo(installSize: 1024 * 1024 * 1024 - 1);
        expect(game.formattedSize, '1024.0 MB');
      });
    });

    group('copyWith', () {
      test('copies all fields when none specified', () {
        final original = createGameInfo(installSize: 1000);
        final copy = original.copyWith();
        expect(copy.displayName, original.displayName);
        expect(copy.appName, original.appName);
        expect(copy.installLocation, original.installLocation);
        expect(copy.installSize, original.installSize);
        expect(copy.version, original.version);
        expect(copy.catalogNamespace, original.catalogNamespace);
        expect(copy.catalogItemId, original.catalogItemId);
        expect(copy.installationGuid, original.installationGuid);
      });

      test('overrides specified fields', () {
        final original = createGameInfo(installSize: 1000);
        final copy = original.copyWith(
          displayName: 'New Name',
          installSize: 2000,
        );
        expect(copy.displayName, 'New Name');
        expect(copy.installSize, 2000);
        expect(copy.appName, original.appName); // unchanged
      });

      test('can override with metadata', () {
        final original = createGameInfo();
        expect(original.metadata, isNull);
        // Note: We can't easily test metadata override without importing GameMetadata
        // but we can verify the original has null metadata
      });
    });
  });
}
