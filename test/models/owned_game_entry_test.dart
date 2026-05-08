import 'package:egdata_flutter/database/collections/owned_game_entry.dart';
import 'package:egdata_flutter/models/epic_library_item.dart';
import 'package:egdata_flutter/models/upload_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OwnedGameEntry', () {
    test('builds stable lowercase identity key from Epic fields', () {
      final key = OwnedGameEntry.makeIdentityKey(
        namespace: 'Ns',
        catalogItemId: 'Catalog',
        appName: 'GameApp',
        assetId: 'Asset',
      );

      expect(key, 'ns|catalog|gameapp|asset');
    });

    test('creates cache entry from Epic library item', () {
      final item = EpicLibraryItem(
        appName: 'ExampleApp',
        title: 'ExampleApp',
        catalogItemId: 'catalog-1',
        namespace: 'example',
        assetId: 'asset-1',
        buildVersion: '1.2.3',
      );

      final entry = OwnedGameEntry.fromLibraryItem(
        item,
        title: 'Example Game',
        boxArtUrl: 'box.jpg',
        wideImageUrl: 'wide.jpg',
        developer: 'Developer',
        publisher: 'Publisher',
        syncedAt: DateTime.utc(2026, 1, 1),
      );

      expect(entry.identityKey, 'example|catalog-1|exampleapp|asset-1');
      expect(entry.title, 'Example Game');
      expect(entry.buildVersion, '1.2.3');
      expect(entry.boxArtUrl, 'box.jpg');
      expect(entry.wideImageUrl, 'wide.jpg');
      expect(entry.developer, 'Developer');
      expect(entry.publisher, 'Publisher');
      expect(entry.syncedAt, DateTime.utc(2026, 1, 1));
    });

    test('converts cached upload fields back to UploadStatus', () {
      final entry = OwnedGameEntry()
        ..identityKey = 'ns|catalog|app|asset'
        ..namespace = 'ns'
        ..catalogItemId = 'catalog'
        ..appName = 'app'
        ..assetId = 'asset'
        ..title = 'Game'
        ..syncedAt = DateTime.utc(2026)
        ..lastUploadStatus = UploadStatusType.alreadyUploaded.name
        ..lastUploadMessage = 'Manifest already exists'
        ..manifestHash = 'abc123';

      final status = entry.uploadStatus;

      expect(status?.status, UploadStatusType.alreadyUploaded);
      expect(status?.message, 'Manifest already exists');
      expect(status?.manifestHash, 'abc123');
    });
  });
}
