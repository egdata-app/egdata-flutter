import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../database/database_service.dart';
import '../models/drive_discovery.dart';
import 'windows_volume_service.dart';
import 'drive_discovery_store.dart';

class DriveScanCancellation {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
}

class DriveDiscoveryService extends ChangeNotifier {
  final DriveDiscoveryStore store;
  final VolumeProvider volumeProvider;
  final String launcherManifestDirectory;
  final Duration pollInterval;

  Timer? _timer;
  bool _refreshing = false;
  bool _hasInitialSnapshot = false;
  Set<String> _connectedVolumeIds = const {};
  List<DriveIdentity> _volumes = const [];
  List<RecoveryCandidate> _candidates = const [];

  DriveDiscoveryService({
    DatabaseService? database,
    DriveDiscoveryStore? store,
    required this.launcherManifestDirectory,
    this.volumeProvider = const WindowsVolumeService(),
    this.pollInterval = const Duration(seconds: 5),
  }) : assert(database != null || store != null),
       store = store ?? DatabaseDriveDiscoveryStore(database!);

  List<DriveIdentity> get volumes => List.unmodifiable(_volumes);
  List<RecoveryCandidate> get recoveryCandidates =>
      List.unmodifiable(_candidates);

  Future<void> start() async {
    if (!Platform.isWindows || _timer != null) return;
    await refresh();
    _timer = Timer.periodic(pollInterval, (_) => unawaited(refresh()));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> refresh() async {
    if (_refreshing || !Platform.isWindows) return;
    _refreshing = true;
    try {
      final volumes = await volumeProvider.listVolumes();
      final volumeIds = volumes.map((drive) => drive.volumeId).toSet();
      final reconnectedIds = _hasInitialSnapshot
          ? volumeIds.difference(_connectedVolumeIds)
          : const <String>{};
      final entries = await store.loadInstalledEntries();
      final changed = <InstalledGameEntry>[];
      final candidates = <RecoveryCandidate>[];

      for (final entry in entries) {
        final previousAvailability = entry.availability;
        final originalInstallLocation = entry.installLocation;
        final drive = _matchDrive(entry, volumes);
        if (drive == null) {
          if (entry.volumeId != null &&
              entry.availability != InstalledGameAvailability.driveMissing) {
            entry.availability = InstalledGameAvailability.driveMissing;
            changed.add(entry);
          }
          continue;
        }

        final relative = entry.relativeInstallPath;
        final discoveredPath = relative == null || relative.isEmpty
            ? entry.installLocation
            : p.windows.join(drive.mountPath, relative);
        if (!await Directory(discoveredPath).exists()) {
          if (entry.availability != InstalledGameAvailability.unknown) {
            entry.availability = InstalledGameAvailability.unknown;
            changed.add(entry);
          }
          continue;
        }

        final manifestPath = await _findManifest(discoveredPath);
        final rawItem = entry.rawItemJson ?? '';
        final itemName = entry.itemFileName ?? '';
        final launchPath = _resolveLaunchPath(entry, discoveredPath, rawItem);
        final itemPath = itemName.isEmpty
            ? ''
            : p.windows.join(launcherManifestDirectory, itemName);
        final itemPresent =
            itemPath.isNotEmpty && await File(itemPath).exists();
        final shouldReview =
            previousAvailability == InstalledGameAvailability.driveMissing ||
            !itemPresent ||
            !p.windows.equals(discoveredPath, entry.installLocation);

        String? validationError;
        if (rawItem.isEmpty || itemName.isEmpty) {
          validationError = 'No cached Epic launcher record is available.';
        } else if (manifestPath == null) {
          validationError = 'The .egstore manifest could not be found.';
        } else if (launchPath.isEmpty || !await File(launchPath).exists()) {
          validationError = 'The launch executable could not be validated.';
        }

        final nextAvailability = validationError == null && shouldReview
            ? InstalledGameAvailability.recoverable
            : itemPresent && validationError == null
            ? InstalledGameAvailability.available
            : InstalledGameAvailability.launcherUnregistered;
        if (entry.availability != nextAvailability ||
            !p.windows.equals(entry.installLocation, discoveredPath)) {
          entry.availability = nextAvailability;
          if (validationError == null) {
            entry.installLocation = discoveredPath;
            entry.manifestLocation = manifestPath;
          }
          changed.add(entry);
        }

        if (shouldReview) {
          candidates.add(
            RecoveryCandidate(
              installationGuid: entry.installationGuid,
              displayName: entry.displayName,
              originalInstallLocation: originalInstallLocation,
              discoveredInstallLocation: discoveredPath,
              itemFileName: itemName,
              rawItemJson: rawItem,
              manifestPath: manifestPath ?? '',
              launchExecutablePath: launchPath,
              drive: drive,
              confidence: validationError == null
                  ? RecoveryConfidence.high
                  : RecoveryConfidence.detectedOnly,
              launcherRecordPresent: itemPresent,
              validationError: validationError,
            ),
          );
        }
      }

      if (changed.isNotEmpty) {
        await store.saveInstalledEntries(changed);
      }
      if (reconnectedIds.isNotEmpty && candidates.isNotEmpty) {
        final matching = candidates
            .where(
              (candidate) => reconnectedIds.contains(candidate.drive.volumeId),
            )
            .toList();
        if (matching.isNotEmpty) {
          final event = ActivityEventEntry()
            ..type = ActivityEventType.driveConnected
            ..title = '${matching.first.drive.displayName} reconnected'
            ..detail =
                '${matching.length} game${matching.length == 1 ? '' : 's'} found'
            ..occurredAt = DateTime.now()
            ..volumeId = matching.first.drive.volumeId;
          await store.addActivity(event);
        }
      }

      final candidateKeys = candidates
          .map(
            (candidate) =>
                '${candidate.installationGuid}|${candidate.discoveredInstallLocation}|${candidate.validationError}',
          )
          .toList(growable: false);
      final previousCandidateKeys = _candidates
          .map(
            (candidate) =>
                '${candidate.installationGuid}|${candidate.discoveredInstallLocation}|${candidate.validationError}',
          )
          .toList(growable: false);
      final shouldNotify =
          changed.isNotEmpty ||
          !setEquals(volumeIds, _connectedVolumeIds) ||
          !listEquals(candidateKeys, previousCandidateKeys);
      _volumes = volumes;
      _candidates = candidates;
      _connectedVolumeIds = volumeIds;
      _hasInitialSnapshot = true;
      if (shouldNotify) notifyListeners();
    } finally {
      _refreshing = false;
    }
  }

  DriveIdentity? _matchDrive(
    InstalledGameEntry entry,
    List<DriveIdentity> volumes,
  ) {
    final volumeId = entry.volumeId;
    if (volumeId != null && volumeId.isNotEmpty) {
      for (final drive in volumes) {
        if (drive.volumeId == volumeId) return drive;
      }
    }
    final serial = entry.volumeSerialNumber;
    if (serial != null) {
      for (final drive in volumes) {
        if (drive.serialNumber == serial) return drive;
      }
    }
    return WindowsVolumeService.findForPath(entry.installLocation, volumes);
  }

  Future<String?> _findManifest(String installLocation) async {
    final store = Directory(p.windows.join(installLocation, '.egstore'));
    if (!await store.exists()) return null;
    await for (final entity in store.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is File && entity.path.toLowerCase().endsWith('.manifest')) {
        return entity.path;
      }
    }
    return null;
  }

  String _resolveLaunchPath(
    InstalledGameEntry entry,
    String installLocation,
    String rawItem,
  ) {
    var launchExecutable = entry.launchExecutable ?? '';
    if (rawItem.isNotEmpty) {
      try {
        final json = jsonDecode(rawItem) as Map<String, dynamic>;
        launchExecutable =
            json['LaunchExecutable'] as String? ?? launchExecutable;
      } catch (_) {}
    }
    if (launchExecutable.isEmpty) return '';
    if (p.windows.isAbsolute(launchExecutable)) return launchExecutable;
    return p.windows.join(installLocation, launchExecutable);
  }

  Future<List<DetectedUnknownInstall>> scanFolder(
    String root, {
    DriveScanCancellation? cancellation,
    ValueChanged<String>? onProgress,
  }) async {
    final knownPaths = (await store.loadInstalledEntries())
        .map(
          (entry) => p.windows.normalize(entry.installLocation).toLowerCase(),
        )
        .toSet();
    final results = <DetectedUnknownInstall>[];
    final directory = Directory(root);
    if (!await directory.exists()) return results;

    await for (final entity in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (cancellation?.isCancelled == true) break;
      if (entity is! Directory ||
          p.windows.basename(entity.path) != '.egstore') {
        continue;
      }
      final installLocation = p.windows.dirname(entity.path);
      onProgress?.call(installLocation);
      String? manifestPath;
      await for (final child in entity.list(
        recursive: true,
        followLinks: false,
      )) {
        if (child is File && child.path.toLowerCase().endsWith('.manifest')) {
          manifestPath = child.path;
          break;
        }
      }
      if (manifestPath != null &&
          !knownPaths.contains(
            p.windows.normalize(installLocation).toLowerCase(),
          )) {
        results.add(
          DetectedUnknownInstall(
            installLocation: installLocation,
            manifestPath: manifestPath,
          ),
        );
      }
    }
    return results;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
