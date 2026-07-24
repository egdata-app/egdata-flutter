import 'package:isar_community/isar.dart';

import '../../models/game_info.dart';
import '../../models/game_metadata.dart';
import '../../models/drive_discovery.dart';

part 'installed_game_entry.g.dart';

@Collection()
class InstalledGameEntry {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String installationGuid;

  late String displayName;
  late String appName;
  late String installLocation;
  late int installSize;
  late String version;
  late String catalogNamespace;
  late String catalogItemId;
  String? manifestHash;
  String? manifestLocation;
  String? itemFilePath;
  String? launchExecutable;
  late String mainGameCatalogNamespace;
  late String mainGameCatalogItemId;
  late String mainGameAppName;
  late List<String> appCategories;

  String? metadataId;
  String? metadataTitle;
  String? metadataDescription;
  String? metadataDeveloper;
  String? metadataPublisher;
  String? metadataKeyImagesPacked;

  late DateTime scannedAt;
  String? rawItemJson;
  String? itemFileName;
  String? volumeId;
  int? volumeSerialNumber;
  String? relativeInstallPath;
  DateTime? lastSeenAt;

  @enumerated
  late InstalledGameAvailability availability;

  InstalledGameEntry();

  factory InstalledGameEntry.fromGameInfo(
    GameInfo game, {
    DateTime? scannedAt,
  }) {
    final metadata = game.metadata;
    return InstalledGameEntry()
      ..installationGuid = game.installationGuid
      ..displayName = game.displayName
      ..appName = game.appName
      ..installLocation = game.installLocation
      ..installSize = game.installSize
      ..version = game.version
      ..catalogNamespace = game.catalogNamespace
      ..catalogItemId = game.catalogItemId
      ..manifestHash = game.manifestHash
      ..manifestLocation = game.manifestLocation
      ..itemFilePath = game.itemFilePath
      ..launchExecutable = game.launchExecutable
      ..mainGameCatalogNamespace = game.mainGameCatalogNamespace
      ..mainGameCatalogItemId = game.mainGameCatalogItemId
      ..mainGameAppName = game.mainGameAppName
      ..appCategories = List<String>.from(game.appCategories)
      ..metadataId = metadata?.id
      ..metadataTitle = metadata?.title
      ..metadataDescription = metadata?.description
      ..metadataDeveloper = metadata?.developer
      ..metadataPublisher = metadata?.publisher
      ..metadataKeyImagesPacked = metadata == null
          ? null
          : _packKeyImages(metadata.keyImages)
      ..scannedAt = scannedAt ?? DateTime.now()
      ..rawItemJson = game.rawItemJson
      ..itemFileName = game.itemFileName
      ..volumeId = game.volumeId
      ..volumeSerialNumber = game.volumeSerialNumber
      ..relativeInstallPath = game.relativeInstallPath
      ..lastSeenAt = game.lastSeenAt ?? scannedAt ?? DateTime.now()
      ..availability = game.availability;
  }

  @ignore
  GameInfo get gameInfo {
    return GameInfo(
      displayName: displayName,
      appName: appName,
      installLocation: installLocation,
      installSize: installSize,
      version: version,
      catalogNamespace: catalogNamespace,
      catalogItemId: catalogItemId,
      installationGuid: installationGuid,
      manifestHash: manifestHash,
      manifestLocation: manifestLocation,
      itemFilePath: itemFilePath,
      launchExecutable: launchExecutable,
      mainGameCatalogNamespace: mainGameCatalogNamespace,
      mainGameCatalogItemId: mainGameCatalogItemId,
      mainGameAppName: mainGameAppName,
      appCategories: List<String>.from(appCategories),
      metadata: _metadata,
      rawItemJson: rawItemJson,
      itemFileName: itemFileName,
      volumeId: volumeId,
      volumeSerialNumber: volumeSerialNumber,
      relativeInstallPath: relativeInstallPath,
      lastSeenAt: lastSeenAt,
      availability: availability,
    );
  }

  void updateFromGameInfo(GameInfo game, DateTime seenAt) {
    final updated = InstalledGameEntry.fromGameInfo(game, scannedAt: seenAt);
    displayName = updated.displayName;
    appName = updated.appName;
    installLocation = updated.installLocation;
    installSize = updated.installSize;
    version = updated.version;
    catalogNamespace = updated.catalogNamespace;
    catalogItemId = updated.catalogItemId;
    manifestHash = updated.manifestHash;
    manifestLocation = updated.manifestLocation;
    itemFilePath = updated.itemFilePath;
    launchExecutable = updated.launchExecutable;
    mainGameCatalogNamespace = updated.mainGameCatalogNamespace;
    mainGameCatalogItemId = updated.mainGameCatalogItemId;
    mainGameAppName = updated.mainGameAppName;
    appCategories = updated.appCategories;
    metadataId = updated.metadataId;
    metadataTitle = updated.metadataTitle;
    metadataDescription = updated.metadataDescription;
    metadataDeveloper = updated.metadataDeveloper;
    metadataPublisher = updated.metadataPublisher;
    metadataKeyImagesPacked = updated.metadataKeyImagesPacked;
    scannedAt = seenAt;
    rawItemJson = updated.rawItemJson ?? rawItemJson;
    itemFileName = updated.itemFileName ?? itemFileName;
    volumeId = updated.volumeId ?? volumeId;
    volumeSerialNumber = updated.volumeSerialNumber ?? volumeSerialNumber;
    relativeInstallPath = updated.relativeInstallPath ?? relativeInstallPath;
    lastSeenAt = seenAt;
    availability = game.availability;
  }

  GameMetadata? get _metadata {
    final id = metadataId;
    final title = metadataTitle;
    if ((id == null || id.isEmpty) && (title == null || title.isEmpty)) {
      return null;
    }
    return GameMetadata(
      id: id ?? '',
      title: title ?? displayName,
      description: metadataDescription,
      developer: metadataDeveloper,
      publisher: metadataPublisher,
      keyImages: _unpackKeyImages(metadataKeyImagesPacked),
    );
  }

  static String _packKeyImages(List<KeyImage> images) {
    return images
        .where((image) => image.type.isNotEmpty && image.url.isNotEmpty)
        .map((image) => '${image.type}|${image.url}')
        .join('\n');
  }

  static List<KeyImage> _unpackKeyImages(String? packed) {
    if (packed == null || packed.isEmpty) return const [];
    final images = <KeyImage>[];
    for (final line in packed.split('\n')) {
      final separator = line.indexOf('|');
      if (separator <= 0) continue;
      images.add(
        KeyImage(
          type: line.substring(0, separator),
          url: line.substring(separator + 1),
        ),
      );
    }
    return images;
  }
}
