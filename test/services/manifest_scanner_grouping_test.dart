import 'package:flutter_test/flutter_test.dart';
import 'package:egdata_flutter/models/game_info.dart';
import 'package:egdata_flutter/services/manifest_scanner.dart';

void main() {
  group('ManifestScanner.groupGamesByMainGame', () {
    GameInfo createGame({
      required String displayName,
      required String catalogItemId,
      required String installationGuid,
      String mainGameCatalogItemId = '',
      String appName = '',
      String mainGameAppName = '',
      String launchExecutable = '',
      int installSize = 0,
      List<String> appCategories = const [],
      String installLocation = r'K:\Epic Games\Sample',
      String catalogNamespace = 'ns',
      String mainGameCatalogNamespace = 'ns',
    }) {
      return GameInfo(
        displayName: displayName,
        appName: appName,
        installLocation: installLocation,
        installSize: installSize,
        version: '1.0.0',
        catalogNamespace: catalogNamespace,
        catalogItemId: catalogItemId,
        installationGuid: installationGuid,
        launchExecutable: launchExecutable.isEmpty ? null : launchExecutable,
        mainGameCatalogNamespace: mainGameCatalogNamespace,
        mainGameCatalogItemId: mainGameCatalogItemId,
        mainGameAppName: mainGameAppName,
        appCategories: appCategories,
      );
    }

    test('prefers base game over addon in same group', () {
      final baseGame = createGame(
        displayName: 'Marvel\'s Guardians of the Galaxy',
        catalogItemId: 'base-id',
        installationGuid: 'base-guid',
        appName: 'base-app',
        mainGameCatalogItemId: 'base-id',
        mainGameAppName: 'base-app',
        launchExecutable: 'retail/gotg.exe',
        installSize: 82,
        appCategories: const ['public', 'games', 'applications'],
      );

      final dlc = createGame(
        displayName: 'Marvel\'s Guardians of the Galaxy: Sleek-Lord Outfit',
        catalogItemId: 'dlc-id',
        installationGuid: 'dlc-guid',
        appName: 'dlc-app',
        mainGameCatalogItemId: 'base-id',
        mainGameAppName: 'base-app',
        launchExecutable: '',
        installSize: 1,
        appCategories: const ['addons', 'applications'],
      );

      final grouped = ManifestScanner.groupGamesByMainGame([dlc, baseGame]);

      expect(grouped, hasLength(1));
      expect(grouped.first.catalogItemId, equals('base-id'));
      expect(grouped.first.displayName, equals(baseGame.displayName));
    });

    test('keeps separate games in different groups', () {
      final cyberpunk = createGame(
        displayName: 'Cyberpunk 2077',
        catalogItemId: 'cp-base',
        installationGuid: 'cp-base-guid',
        appName: 'ginger',
        mainGameCatalogItemId: 'cp-base',
        mainGameAppName: 'ginger',
        launchExecutable: 'redprelauncher.exe',
        installSize: 80,
      );

      final cairn = createGame(
        displayName: 'Cairn',
        catalogItemId: 'cairn-base',
        installationGuid: 'cairn-guid',
        appName: 'cairn',
        mainGameCatalogItemId: 'cairn-base',
        mainGameAppName: 'cairn',
        launchExecutable: 'Cairn.exe',
        installSize: 11,
      );

      final grouped = ManifestScanner.groupGamesByMainGame([cyberpunk, cairn]);

      expect(grouped, hasLength(2));
      expect(
        grouped.map((g) => g.catalogItemId),
        containsAll(['cp-base', 'cairn-base']),
      );
    });

    test('uses install location fallback when main game ids are missing', () {
      final primary = createGame(
        displayName: 'Game Primary',
        catalogItemId: '',
        installationGuid: 'primary-guid',
        launchExecutable: 'game.exe',
        installSize: 50,
        installLocation: r'K:\Epic Games\SameFolder',
      );

      final secondary = createGame(
        displayName: 'Game Secondary',
        catalogItemId: '',
        installationGuid: 'secondary-guid',
        launchExecutable: '',
        installSize: 1,
        appCategories: const ['addons'],
        installLocation: r'K:\Epic Games\SameFolder',
      );

      final grouped = ManifestScanner.groupGamesByMainGame([
        secondary,
        primary,
      ]);

      expect(grouped, hasLength(1));
      expect(grouped.first.installationGuid, equals('primary-guid'));
    });
  });
}
