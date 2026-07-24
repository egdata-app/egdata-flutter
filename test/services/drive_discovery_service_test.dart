@TestOn('windows')
library;

import 'dart:convert';
import 'dart:io';

import 'package:egdata_flutter/database/database_service.dart';
import 'package:egdata_flutter/models/drive_discovery.dart';
import 'package:egdata_flutter/services/drive_discovery_service.dart';
import 'package:egdata_flutter/services/drive_discovery_store.dart';
import 'package:egdata_flutter/services/windows_volume_service.dart';
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

class _FakeVolumes implements VolumeProvider {
  final List<DriveIdentity> drives;
  const _FakeVolumes(this.drives);

  @override
  Future<List<DriveIdentity>> listVolumes() async => drives;
}

void main() {
  test('finds a recoverable cached game after its volume returns', () async {
    final temp = await Directory.systemTemp.createTemp(
      'egdata-discovery-test-',
    );
    addTearDown(() async => temp.delete(recursive: true));
    final root = p.windows.rootPrefix(temp.path);
    final relative = p.windows.relative(temp.path, from: root);
    final egstore = await Directory(p.join(temp.path, '.egstore')).create();
    final manifest = await File(
      p.join(egstore.path, 'fixture.manifest'),
    ).writeAsBytes([1]);
    await File(p.join(temp.path, 'Game.exe')).writeAsString('fixture');
    final launcherDir = await Directory(p.join(temp.path, 'launcher')).create();
    final raw = jsonEncode({
      'InstallationGuid': 'guid-1',
      'InstallLocation': temp.path,
      'LaunchExecutable': 'Game.exe',
    });
    final entry = InstalledGameEntry()
      ..installationGuid = 'guid-1'
      ..displayName = 'Fixture Game'
      ..appName = 'Fixture'
      ..installLocation = temp.path
      ..installSize = 1
      ..version = '1'
      ..catalogNamespace = 'fixture'
      ..catalogItemId = 'fixture'
      ..mainGameCatalogNamespace = ''
      ..mainGameCatalogItemId = ''
      ..mainGameAppName = ''
      ..appCategories = []
      ..scannedAt = DateTime.now()
      ..rawItemJson = raw
      ..itemFileName = 'fixture.item'
      ..volumeId = 'volume-1'
      ..volumeSerialNumber = 42
      ..relativeInstallPath = relative
      ..availability = InstalledGameAvailability.driveMissing;
    final store = _FakeStore([entry]);
    final drive = DriveIdentity(
      volumeId: 'volume-1',
      serialNumber: 42,
      mountPath: root,
      label: 'Fixture',
      kind: DriveKind.removable,
    );
    final service = DriveDiscoveryService(
      store: store,
      launcherManifestDirectory: launcherDir.path,
      volumeProvider: _FakeVolumes([drive]),
    );

    await service.refresh();

    expect(service.recoveryCandidates, hasLength(1));
    expect(service.recoveryCandidates.single.manifestPath, manifest.path);
    expect(service.recoveryCandidates.single.canRestore, isTrue);
    expect(entry.availability, InstalledGameAvailability.recoverable);
  });
}
