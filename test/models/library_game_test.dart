import 'package:egdata_flutter/database/collections/owned_game_entry.dart';
import 'package:egdata_flutter/models/epic_library_item.dart';
import 'package:egdata_flutter/models/game_info.dart';
import 'package:egdata_flutter/models/library_game.dart';
import 'package:egdata_flutter/models/upload_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LibraryGame.merge', () {
    test('includes owned-only games as not installed', () {
      final owned = createOwnedGame(
        title: 'Cloud Game',
        catalogItemId: 'catalog-1',
        appName: 'CloudApp',
        assetId: 'asset-1',
      );

      final games = LibraryGame.merge(
        installedGames: const [],
        ownedGames: [owned],
      );

      expect(games, hasLength(1));
      expect(games.single.title, 'Cloud Game');
      expect(games.single.isInstalled, false);
      expect(games.single.ownedGame, owned);
    });

    test('merges installed game with matching owned entry', () {
      final owned = createOwnedGame(
        title: 'Owned Title',
        catalogItemId: 'catalog-1',
        appName: 'AppName',
        assetId: 'asset-1',
      );
      final installed = createInstalledGame(
        displayName: 'Installed Title',
        catalogItemId: 'catalog-1',
        appName: 'AppName',
        installationGuid: 'local-guid',
      );

      final games = LibraryGame.merge(
        installedGames: [installed],
        ownedGames: [owned],
      );

      expect(games, hasLength(1));
      expect(games.single.isInstalled, true);
      expect(games.single.title, 'Owned Title');
      expect(games.single.installedGame, installed);
      expect(games.single.ownedGame, owned);
    });

    test('collapses duplicate owned asset records into one game', () {
      final failedAsset = createOwnedGame(
        title: 'Duplicate Title',
        catalogItemId: 'catalog-1',
        appName: 'AppName',
        assetId: 'asset-a',
        uploadStatus: UploadStatus(
          status: UploadStatusType.failed,
          message: 'No cloud manifest found',
        ),
      );
      final uploadedAsset = createOwnedGame(
        title: 'Duplicate Title',
        catalogItemId: 'catalog-1',
        appName: 'AppName',
        assetId: 'asset-b',
        uploadStatus: UploadStatus(
          status: UploadStatusType.alreadyUploaded,
          message: 'Manifest already exists',
        ),
      );

      final games = LibraryGame.merge(
        installedGames: const [],
        ownedGames: [failedAsset, uploadedAsset],
      );

      expect(games, hasLength(1));
      expect(games.single.title, 'Duplicate Title');
      expect(games.single.statusLabel, 'Exists');
      expect(games.single.ownedGame, uploadedAsset);
    });

    test(
      'does not leave duplicate owned asset when installed game matches',
      () {
        final assetA = createOwnedGame(
          title: 'Owned Title',
          catalogItemId: 'catalog-1',
          appName: 'AppName',
          assetId: 'asset-a',
        );
        final assetB = createOwnedGame(
          title: 'Owned Title',
          catalogItemId: 'catalog-1',
          appName: 'AppName',
          assetId: 'asset-b',
        );
        final installed = createInstalledGame(
          displayName: 'Installed Title',
          catalogItemId: 'catalog-1',
          appName: 'AppName',
          installationGuid: 'local-guid',
        );

        final games = LibraryGame.merge(
          installedGames: [installed],
          ownedGames: [assetA, assetB],
        );

        expect(games, hasLength(1));
        expect(games.single.isInstalled, true);
        expect(games.single.installedGame, installed);
        expect(games.single.title, 'Owned Title');
      },
    );

    test('uses local upload status for installed games', () {
      final installed = createInstalledGame(
        displayName: 'Installed Title',
        catalogItemId: 'catalog-1',
        appName: 'AppName',
        installationGuid: 'local-guid',
      );

      final games = LibraryGame.merge(
        installedGames: [installed],
        ownedGames: const [],
        localUploadStatuses: {
          'local-guid': UploadStatus(
            status: UploadStatusType.uploaded,
            message: 'Uploaded',
          ),
        },
      );

      expect(games.single.statusLabel, 'Uploaded');
      expect(games.single.uploadStatus?.status, UploadStatusType.uploaded);
    });
  });
}

OwnedGameEntry createOwnedGame({
  required String title,
  required String catalogItemId,
  required String appName,
  required String assetId,
  UploadStatus? uploadStatus,
}) {
  final entry = OwnedGameEntry.fromLibraryItem(
    EpicLibraryItem(
      appName: appName,
      title: title,
      catalogItemId: catalogItemId,
      namespace: 'ns',
      assetId: assetId,
    ),
    title: title,
    syncedAt: DateTime.utc(2026),
  );
  if (uploadStatus != null) {
    entry.lastUploadStatus = uploadStatus.status.name;
    entry.lastUploadMessage = uploadStatus.message;
    entry.manifestHash = uploadStatus.manifestHash;
  }
  return entry;
}

GameInfo createInstalledGame({
  required String displayName,
  required String catalogItemId,
  required String appName,
  required String installationGuid,
}) {
  return GameInfo(
    displayName: displayName,
    appName: appName,
    installLocation: r'C:\Games\Example',
    installSize: 1024,
    version: '1.0.0',
    catalogNamespace: 'ns',
    catalogItemId: catalogItemId,
    installationGuid: installationGuid,
  );
}
