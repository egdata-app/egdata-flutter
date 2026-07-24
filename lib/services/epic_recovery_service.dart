import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/database_service.dart';
import '../models/drive_discovery.dart';
import 'windows_process_service.dart';
import 'drive_discovery_store.dart';

typedef LauncherRunningCheck = bool Function();

class EpicRecoveryService {
  final DriveDiscoveryStore store;
  final String launcherManifestDirectory;
  final LauncherRunningCheck launcherRunning;
  final Future<Directory> Function()? backupDirectoryProvider;

  EpicRecoveryService({
    DatabaseService? database,
    DriveDiscoveryStore? store,
    required this.launcherManifestDirectory,
    LauncherRunningCheck? launcherRunning,
    this.backupDirectoryProvider,
  }) : assert(database != null || store != null),
       store = store ?? DatabaseDriveDiscoveryStore(database!),
       launcherRunning =
           launcherRunning ??
           (() =>
               WindowsProcessService.isProcessRunning('EpicGamesLauncher.exe'));

  Future<RestoreResult> restore(List<RecoveryCandidate> candidates) async {
    final selected = candidates
        .where((candidate) => candidate.canRestore)
        .toList();
    if (selected.isEmpty) {
      return const RestoreResult(
        success: false,
        restoredCount: 0,
        message: 'No validated games were selected for recovery.',
      );
    }
    if (launcherRunning()) {
      return const RestoreResult(
        success: false,
        restoredCount: 0,
        message: 'Close Epic Games Launcher before restoring these games.',
      );
    }

    final backupRoot = await _backupRoot();
    await backupRoot.create(recursive: true);
    final batchName = DateTime.now().toUtc().toIso8601String().replaceAll(
      ':',
      '-',
    );
    final batchDirectory = Directory(p.join(backupRoot.path, batchName));
    await batchDirectory.create(recursive: true);
    final backups = <String, String?>{};

    try {
      for (final candidate in selected) {
        await _validate(candidate);
        final targetPath = p.windows.join(
          launcherManifestDirectory,
          candidate.itemFileName,
        );
        final target = File(targetPath);
        if (await target.exists()) {
          final backupPath = p.join(
            batchDirectory.path,
            candidate.itemFileName,
          );
          await target.copy(backupPath);
          backups[targetPath] = backupPath;
        } else {
          backups[targetPath] = null;
        }

        final patched = _patchedItem(candidate);
        final temp = File('$targetPath.egdata.tmp');
        await temp.writeAsString(
          const JsonEncoder.withIndent('\t').convert(patched),
          flush: true,
        );
        await temp.rename(targetPath);
      }

      for (final candidate in selected) {
        if (!await _verify(candidate)) {
          throw StateError(
            '${candidate.displayName} could not be verified after restore.',
          );
        }
      }

      await _markRestored(selected);
      await _recordActivity(
        ActivityEventType.recoverySucceeded,
        'Library recovery completed',
        '${selected.length} game${selected.length == 1 ? '' : 's'} restored without downloading',
      );
      await _pruneBackups(backupRoot);
      return RestoreResult(
        success: true,
        restoredCount: selected.length,
        message:
            '${selected.length} game${selected.length == 1 ? '' : 's'} restored. Restart Epic Games Launcher.',
      );
    } catch (error) {
      await _rollback(backups);
      await _recordActivity(
        ActivityEventType.recoveryFailed,
        'Library recovery failed',
        error.toString(),
      );
      return RestoreResult(
        success: false,
        restoredCount: 0,
        message: 'Recovery failed and launcher files were rolled back: $error',
      );
    }
  }

  Future<void> _validate(RecoveryCandidate candidate) async {
    if (!candidate.canRestore) {
      throw StateError(
        candidate.validationError ?? 'Candidate is not restorable.',
      );
    }
    if (!await Directory(candidate.discoveredInstallLocation).exists()) {
      throw StateError(
        '${candidate.displayName} installation folder is missing.',
      );
    }
    if (!await File(candidate.manifestPath).exists()) {
      throw StateError('${candidate.displayName} manifest is missing.');
    }
    if (!await File(candidate.launchExecutablePath).exists()) {
      throw StateError('${candidate.displayName} executable is missing.');
    }
    jsonDecode(candidate.rawItemJson) as Map<String, dynamic>;
  }

  Map<String, dynamic> _patchedItem(RecoveryCandidate candidate) {
    final json = jsonDecode(candidate.rawItemJson) as Map<String, dynamic>;
    final oldLocation =
        json['InstallLocation'] as String? ?? candidate.originalInstallLocation;
    final newLocation = candidate.discoveredInstallLocation;
    json['InstallLocation'] = newLocation;
    json['ManifestLocation'] = candidate.manifestPath;
    for (final key in const [
      'CompleteManifestPath',
      'PendingManifestPath',
      'StagingLocation',
    ]) {
      final value = json[key];
      if (value is String && value.isNotEmpty) {
        json[key] = _replacePathPrefix(value, oldLocation, newLocation);
      }
    }
    return json;
  }

  String _replacePathPrefix(String value, String oldPrefix, String newPrefix) {
    if (value.toLowerCase().startsWith(oldPrefix.toLowerCase())) {
      return '$newPrefix${value.substring(oldPrefix.length)}';
    }
    return value;
  }

  Future<bool> _verify(RecoveryCandidate candidate) async {
    final itemPath = p.windows.join(
      launcherManifestDirectory,
      candidate.itemFileName,
    );
    final item = File(itemPath);
    if (!await item.exists()) return false;
    try {
      final json =
          jsonDecode(await item.readAsString()) as Map<String, dynamic>;
      return json['InstallationGuid'] == candidate.installationGuid &&
          p.windows.equals(
            json['InstallLocation'] as String? ?? '',
            candidate.discoveredInstallLocation,
          ) &&
          await File(json['ManifestLocation'] as String? ?? '').exists();
    } catch (_) {
      return false;
    }
  }

  Future<void> _rollback(Map<String, String?> backups) async {
    for (final entry in backups.entries) {
      final target = File(entry.key);
      final backupPath = entry.value;
      try {
        if (backupPath == null) {
          if (await target.exists()) await target.delete();
        } else {
          await File(backupPath).copy(target.path);
        }
      } catch (_) {}
    }
  }

  Future<void> _markRestored(List<RecoveryCandidate> candidates) async {
    final entries = await store.loadInstalledEntries();
    final byGuid = {for (final entry in entries) entry.installationGuid: entry};
    final changed = <InstalledGameEntry>[];
    final now = DateTime.now();
    for (final candidate in candidates) {
      final entry = byGuid[candidate.installationGuid];
      if (entry == null) continue;
      entry.installLocation = candidate.discoveredInstallLocation;
      entry.manifestLocation = candidate.manifestPath;
      entry.itemFilePath = p.windows.join(
        launcherManifestDirectory,
        candidate.itemFileName,
      );
      entry.availability = InstalledGameAvailability.available;
      entry.lastSeenAt = now;
      changed.add(entry);
    }
    await store.saveInstalledEntries(changed);
  }

  Future<Directory> _backupRoot() async {
    if (backupDirectoryProvider != null) return backupDirectoryProvider!();
    final support = await getApplicationSupportDirectory();
    return Directory(p.join(support.path, 'recovery-backups'));
  }

  Future<void> _pruneBackups(Directory root) async {
    final directories = await root
        .list()
        .where((entity) => entity is Directory)
        .cast<Directory>()
        .toList();
    directories.sort((a, b) => b.path.compareTo(a.path));
    for (final directory in directories.skip(20)) {
      await directory.delete(recursive: true);
    }
  }

  Future<void> _recordActivity(
    ActivityEventType type,
    String title,
    String detail,
  ) async {
    final event = ActivityEventEntry()
      ..type = type
      ..title = title
      ..detail = detail
      ..occurredAt = DateTime.now();
    await store.addActivity(event);
  }
}
