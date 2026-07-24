import 'dart:convert';
import 'dart:io';

import 'package:egdata_flutter/database/database_service.dart';
import 'package:egdata_flutter/models/drive_discovery.dart';
import 'package:egdata_flutter/services/drive_discovery_store.dart';
import 'package:egdata_flutter/services/epic_recovery_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

class _FakeStore implements DriveDiscoveryStore {
  final List<InstalledGameEntry> entries;
  final List<ActivityEventEntry> events = [];

  _FakeStore(this.entries);

  @override
  Future<void> addActivity(ActivityEventEntry entry) async => events.add(entry);

  @override
  Future<List<InstalledGameEntry>> loadInstalledEntries() async => entries;

  @override
  Future<void> saveInstalledEntries(List<InstalledGameEntry> changed) async {}
}

void main() {
  late Directory temp;
  late Directory manifests;
  late Directory backups;
  late Directory install;
  late File contentManifest;
  late File executable;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('egdata-recovery-test-');
    manifests = await Directory(
      p.join(temp.path, 'launcher-manifests'),
    ).create();
    backups = await Directory(p.join(temp.path, 'backups')).create();
    install = await Directory(p.join(temp.path, 'Game')).create();
    final egstore = await Directory(p.join(install.path, '.egstore')).create();
    contentManifest = await File(
      p.join(egstore.path, 'game.manifest'),
    ).writeAsBytes([1, 2, 3]);
    executable = await File(
      p.join(install.path, 'Game.exe'),
    ).writeAsString('fixture');
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  RecoveryCandidate candidate({String itemFileName = 'game.item'}) {
    final raw = jsonEncode({
      'InstallationGuid': 'guid-1',
      'DisplayName': 'Fixture Game',
      'InstallLocation': r'K:\Epic Games\Fixture Game',
      'ManifestLocation': r'K:\Epic Games\Fixture Game\.egstore\game.manifest',
      'CompleteManifestPath':
          r'K:\Epic Games\Fixture Game\.egstore\complete.manifest',
      'StagingLocation': r'K:\Epic Games\Fixture Game\.egstore\staging',
      'LaunchExecutable': 'Game.exe',
      'CustomEpicField': {'preserve': true},
    });
    return RecoveryCandidate(
      installationGuid: 'guid-1',
      displayName: 'Fixture Game',
      originalInstallLocation: r'K:\Epic Games\Fixture Game',
      discoveredInstallLocation: install.path,
      itemFileName: itemFileName,
      rawItemJson: raw,
      manifestPath: contentManifest.path,
      launchExecutablePath: executable.path,
      drive: const DriveIdentity(
        volumeId: 'fixture-volume',
        serialNumber: 1,
        mountPath: r'K:\',
        label: 'Fixture',
        kind: DriveKind.removable,
      ),
      confidence: RecoveryConfidence.high,
      launcherRecordPresent: false,
    );
  }

  InstalledGameEntry installedEntry() {
    return InstalledGameEntry()
      ..installationGuid = 'guid-1'
      ..displayName = 'Fixture Game'
      ..appName = 'Fixture'
      ..installLocation = r'K:\Epic Games\Fixture Game'
      ..installSize = 3
      ..version = '1'
      ..catalogNamespace = 'fixture'
      ..catalogItemId = 'fixture'
      ..mainGameCatalogNamespace = ''
      ..mainGameCatalogItemId = ''
      ..mainGameAppName = ''
      ..appCategories = []
      ..scannedAt = DateTime.now()
      ..availability = InstalledGameAvailability.recoverable;
  }

  test('restores paths while preserving unknown Epic fields', () async {
    final store = _FakeStore([installedEntry()]);
    final service = EpicRecoveryService(
      store: store,
      launcherManifestDirectory: manifests.path,
      launcherRunning: () => false,
      backupDirectoryProvider: () async => backups,
    );

    final result = await service.restore([candidate()]);

    expect(result.success, isTrue);
    final restored =
        jsonDecode(
              await File(p.join(manifests.path, 'game.item')).readAsString(),
            )
            as Map<String, dynamic>;
    expect(restored['InstallLocation'], install.path);
    expect(restored['ManifestLocation'], contentManifest.path);
    expect((restored['CustomEpicField'] as Map)['preserve'], isTrue);
    expect(
      store.entries.single.availability,
      InstalledGameAvailability.available,
    );
    expect(store.events.single.type, ActivityEventType.recoverySucceeded);
  });

  test('refuses to write while Epic Games Launcher is running', () async {
    final service = EpicRecoveryService(
      store: _FakeStore([installedEntry()]),
      launcherManifestDirectory: manifests.path,
      launcherRunning: () => true,
      backupDirectoryProvider: () async => backups,
    );

    final result = await service.restore([candidate()]);

    expect(result.success, isFalse);
    expect(result.message, contains('Close Epic Games Launcher'));
    expect(await File(p.join(manifests.path, 'game.item')).exists(), isFalse);
  });

  test(
    'rolls back earlier writes when a later item cannot be written',
    () async {
      final existing = File(p.join(manifests.path, 'game.item'));
      await existing.writeAsString('{"sentinel":"original"}');
      final service = EpicRecoveryService(
        store: _FakeStore([installedEntry()]),
        launcherManifestDirectory: manifests.path,
        launcherRunning: () => false,
        backupDirectoryProvider: () async => backups,
      );

      final second = candidate(itemFileName: p.join('missing', 'bad.item'));
      final result = await service.restore([candidate(), second]);

      expect(result.success, isFalse);
      expect(await existing.readAsString(), '{"sentinel":"original"}');
    },
  );
}
