import 'game_metadata.dart';

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
  final GameMetadata? metadata;

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
    this.metadata,
  });

  String get formattedSize {
    if (installSize < 1024) return '$installSize B';
    if (installSize < 1024 * 1024) return '${(installSize / 1024).toStringAsFixed(1)} KB';
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
    GameMetadata? metadata,
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
      metadata: metadata ?? this.metadata,
    );
  }
}
