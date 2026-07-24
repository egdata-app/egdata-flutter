enum InstalledGameAvailability {
  unknown,
  available,
  driveMissing,
  launcherUnregistered,
  recoverable,
}

enum DriveKind { fixed, removable, network, other }

class DriveIdentity {
  final String volumeId;
  final int serialNumber;
  final String mountPath;
  final String label;
  final DriveKind kind;

  const DriveIdentity({
    required this.volumeId,
    required this.serialNumber,
    required this.mountPath,
    required this.label,
    required this.kind,
  });

  String get displayName => label.trim().isEmpty
      ? mountPath.replaceAll('\\', '')
      : '$label (${mountPath.replaceAll('\\', '')})';
}

enum RecoveryConfidence { high, detectedOnly }

class RecoveryCandidate {
  final String installationGuid;
  final String displayName;
  final String originalInstallLocation;
  final String discoveredInstallLocation;
  final String itemFileName;
  final String rawItemJson;
  final String manifestPath;
  final String launchExecutablePath;
  final DriveIdentity drive;
  final RecoveryConfidence confidence;
  final bool launcherRecordPresent;
  final String? validationError;

  const RecoveryCandidate({
    required this.installationGuid,
    required this.displayName,
    required this.originalInstallLocation,
    required this.discoveredInstallLocation,
    required this.itemFileName,
    required this.rawItemJson,
    required this.manifestPath,
    required this.launchExecutablePath,
    required this.drive,
    required this.confidence,
    required this.launcherRecordPresent,
    this.validationError,
  });

  bool get canRestore =>
      confidence == RecoveryConfidence.high && validationError == null;
}

class DetectedUnknownInstall {
  final String installLocation;
  final String manifestPath;

  const DetectedUnknownInstall({
    required this.installLocation,
    required this.manifestPath,
  });

  String get displayName {
    final normalized = installLocation.replaceAll('/', '\\');
    final parts = normalized.split('\\').where((part) => part.isNotEmpty);
    return parts.isEmpty ? installLocation : parts.last;
  }
}

class RestoreResult {
  final bool success;
  final int restoredCount;
  final String message;

  const RestoreResult({
    required this.success,
    required this.restoredCount,
    required this.message,
  });
}
