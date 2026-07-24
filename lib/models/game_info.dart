import 'game_metadata.dart';
import 'drive_discovery.dart';

class GameInfo {
  final String displayName;
  final String appName;
  final String installLocation;
  final int installSize;
  final String version;
  final String catalogNamespace;
  final String catalogItemId;
  final String installationGuid;
  final String? manifestHash;
  final String? manifestLocation;
  final String? itemFilePath;
  final String? launchExecutable;
  final String mainGameCatalogNamespace;
  final String mainGameCatalogItemId;
  final String mainGameAppName;
  final List<String> appCategories;
  final GameMetadata? metadata;
  final String? rawItemJson;
  final String? itemFileName;
  final String? volumeId;
  final int? volumeSerialNumber;
  final String? relativeInstallPath;
  final DateTime? lastSeenAt;
  final InstalledGameAvailability availability;

  GameInfo({
    required this.displayName,
    required this.appName,
    required this.installLocation,
    required this.installSize,
    required this.version,
    required this.catalogNamespace,
    required this.catalogItemId,
    required this.installationGuid,
    this.manifestHash,
    this.manifestLocation,
    this.itemFilePath,
    this.launchExecutable,
    this.mainGameCatalogNamespace = '',
    this.mainGameCatalogItemId = '',
    this.mainGameAppName = '',
    this.appCategories = const [],
    this.metadata,
    this.rawItemJson,
    this.itemFileName,
    this.volumeId,
    this.volumeSerialNumber,
    this.relativeInstallPath,
    this.lastSeenAt,
    this.availability = InstalledGameAvailability.unknown,
  });

  String get formattedSize {
    if (installSize < 1024) {
      return '$installSize B';
    }
    if (installSize < 1024 * 1024) {
      return '${(installSize / 1024).toStringAsFixed(1)} KB';
    }
    if (installSize < 1024 * 1024 * 1024) {
      return '${(installSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(installSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  GameInfo copyWith({
    String? displayName,
    String? appName,
    String? installLocation,
    int? installSize,
    String? version,
    String? catalogNamespace,
    String? catalogItemId,
    String? installationGuid,
    String? manifestHash,
    String? manifestLocation,
    String? itemFilePath,
    String? launchExecutable,
    String? mainGameCatalogNamespace,
    String? mainGameCatalogItemId,
    String? mainGameAppName,
    List<String>? appCategories,
    GameMetadata? metadata,
    String? rawItemJson,
    String? itemFileName,
    String? volumeId,
    int? volumeSerialNumber,
    String? relativeInstallPath,
    DateTime? lastSeenAt,
    InstalledGameAvailability? availability,
  }) {
    return GameInfo(
      displayName: displayName ?? this.displayName,
      appName: appName ?? this.appName,
      installLocation: installLocation ?? this.installLocation,
      installSize: installSize ?? this.installSize,
      version: version ?? this.version,
      catalogNamespace: catalogNamespace ?? this.catalogNamespace,
      catalogItemId: catalogItemId ?? this.catalogItemId,
      installationGuid: installationGuid ?? this.installationGuid,
      manifestHash: manifestHash ?? this.manifestHash,
      manifestLocation: manifestLocation ?? this.manifestLocation,
      itemFilePath: itemFilePath ?? this.itemFilePath,
      launchExecutable: launchExecutable ?? this.launchExecutable,
      mainGameCatalogNamespace:
          mainGameCatalogNamespace ?? this.mainGameCatalogNamespace,
      mainGameCatalogItemId:
          mainGameCatalogItemId ?? this.mainGameCatalogItemId,
      mainGameAppName: mainGameAppName ?? this.mainGameAppName,
      appCategories: appCategories ?? this.appCategories,
      metadata: metadata ?? this.metadata,
      rawItemJson: rawItemJson ?? this.rawItemJson,
      itemFileName: itemFileName ?? this.itemFileName,
      volumeId: volumeId ?? this.volumeId,
      volumeSerialNumber: volumeSerialNumber ?? this.volumeSerialNumber,
      relativeInstallPath: relativeInstallPath ?? this.relativeInstallPath,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      availability: availability ?? this.availability,
    );
  }
}
