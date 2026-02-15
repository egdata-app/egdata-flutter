import 'package:egdata_flutter/models/game_info.dart';
import 'package:egdata_flutter/models/manifest_health_issue.dart';
import 'package:egdata_flutter/services/manifest_scanner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ManifestScanner.analyzeManifestHealth', () {
    GameInfo createGame({
      required String name,
      required String guid,
      required String catalogItemId,
      required String installLocation,
      String catalogNamespace = 'ns',
      String mainGameCatalogItemId = '',
      String? manifestLocation,
    }) {
      return GameInfo(
        displayName: name,
        appName: name,
        installLocation: installLocation,
        installSize: 1024,
        version: '1.0',
        catalogNamespace: catalogNamespace,
        catalogItemId: catalogItemId,
        installationGuid: guid,
        mainGameCatalogItemId: mainGameCatalogItemId,
        manifestLocation: manifestLocation,
      );
    }

    test('does not flag duplicate install for same namespace', () {
      final scanner = ManifestScanner();
      final games = [
        createGame(
          name: 'Base Game',
          guid: 'base',
          catalogItemId: 'base-id',
          catalogNamespace: 'shared-ns',
          installLocation: r'C:\Games\Shared',
        ),
        createGame(
          name: 'DLC Game',
          guid: 'dlc',
          catalogItemId: 'dlc-id',
          catalogNamespace: 'shared-ns',
          installLocation: r'C:\Games\Shared',
        ),
      ];

      final report = scanner.analyzeManifestHealth(games);

      expect(
        report.issues.any(
          (issue) =>
              issue.type == ManifestHealthIssueType.duplicateInstallLocation,
        ),
        isFalse,
      );
    });

    test('detects duplicate install folders across namespaces', () {
      final scanner = ManifestScanner();
      final games = [
        createGame(
          name: 'Base Game',
          guid: 'base',
          catalogItemId: 'base-id',
          catalogNamespace: 'ns-one',
          installLocation: r'C:\Games\Shared',
        ),
        createGame(
          name: 'DLC Game',
          guid: 'dlc',
          catalogItemId: 'dlc-id',
          catalogNamespace: 'ns-two',
          installLocation: r'C:\Games\Shared',
        ),
      ];

      final report = scanner.analyzeManifestHealth(games);

      expect(
        report.issues.any(
          (issue) =>
              issue.type == ManifestHealthIssueType.duplicateInstallLocation,
        ),
        isTrue,
      );
    });

    test('detects orphan add-ons and stale manifest paths', () {
      final scanner = ManifestScanner();
      final games = [
        createGame(
          name: 'Base Game',
          guid: 'base',
          catalogItemId: 'base-id',
          catalogNamespace: 'ns-one',
          installLocation: r'C:\Games\Shared',
        ),
        createGame(
          name: 'DLC Game',
          guid: 'dlc',
          catalogItemId: 'dlc-id',
          catalogNamespace: 'ns-two',
          mainGameCatalogItemId: 'missing-main-id',
          installLocation: r'C:\Games\Shared',
          manifestLocation: r'C:\DoesNotExist\file.manifest',
        ),
      ];

      final report = scanner.analyzeManifestHealth(games);

      expect(report.issues.isNotEmpty, isTrue);
      expect(
        report.issues.any(
          (issue) => issue.type == ManifestHealthIssueType.orphanAddon,
        ),
        isTrue,
      );
      expect(
        report.issues.any(
          (issue) =>
              issue.type == ManifestHealthIssueType.staleManifestLocation,
        ),
        isTrue,
      );
    });
  });
}
