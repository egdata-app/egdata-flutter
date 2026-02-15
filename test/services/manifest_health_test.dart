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
      String mainGameCatalogItemId = '',
      String? manifestLocation,
    }) {
      return GameInfo(
        displayName: name,
        appName: name,
        installLocation: installLocation,
        installSize: 1024,
        version: '1.0',
        catalogNamespace: 'ns',
        catalogItemId: catalogItemId,
        installationGuid: guid,
        mainGameCatalogItemId: mainGameCatalogItemId,
        manifestLocation: manifestLocation,
      );
    }

    test('detects duplicate install folders and orphan add-ons', () {
      final scanner = ManifestScanner();
      final games = [
        createGame(
          name: 'Base Game',
          guid: 'base',
          catalogItemId: 'base-id',
          installLocation: r'C:\Games\Shared',
        ),
        createGame(
          name: 'DLC Game',
          guid: 'dlc',
          catalogItemId: 'dlc-id',
          mainGameCatalogItemId: 'missing-main-id',
          installLocation: r'C:\Games\Shared',
          manifestLocation: r'C:\DoesNotExist\file.manifest',
        ),
      ];

      final report = scanner.analyzeManifestHealth(games);

      expect(report.issues.isNotEmpty, isTrue);
      expect(
        report.issues.any(
          (issue) =>
              issue.type == ManifestHealthIssueType.duplicateInstallLocation,
        ),
        isTrue,
      );
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
