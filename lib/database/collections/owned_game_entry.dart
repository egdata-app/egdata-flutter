import 'package:isar_community/isar.dart';

import '../../models/epic_library_item.dart';
import '../../models/upload_status.dart';

part 'owned_game_entry.g.dart';

@Collection()
class OwnedGameEntry {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String identityKey;

  late String namespace;
  late String catalogItemId;
  late String appName;
  late String assetId;

  late String title;
  String? buildVersion;
  String? boxArtUrl;
  String? wideImageUrl;
  String? developer;
  String? publisher;

  late DateTime syncedAt;
  DateTime? lastCloudSyncAt;
  String? lastUploadStatus;
  String? lastUploadMessage;
  String? manifestHash;

  OwnedGameEntry();

  factory OwnedGameEntry.fromLibraryItem(
    EpicLibraryItem item, {
    String? title,
    String? boxArtUrl,
    String? wideImageUrl,
    String? developer,
    String? publisher,
    DateTime? syncedAt,
  }) {
    return OwnedGameEntry()
      ..identityKey = makeIdentityKey(
        namespace: item.namespace,
        catalogItemId: item.catalogItemId,
        appName: item.appName,
        assetId: item.assetId,
      )
      ..namespace = item.namespace
      ..catalogItemId = item.catalogItemId
      ..appName = item.appName
      ..assetId = item.assetId
      ..title = (title == null || title.trim().isEmpty) ? item.appName : title
      ..buildVersion = item.buildVersion
      ..boxArtUrl = boxArtUrl
      ..wideImageUrl = wideImageUrl
      ..developer = developer
      ..publisher = publisher
      ..syncedAt = syncedAt ?? DateTime.now();
  }

  EpicLibraryItem toLibraryItem() {
    return EpicLibraryItem(
      appName: appName,
      title: title,
      catalogItemId: catalogItemId,
      namespace: namespace,
      assetId: assetId,
      buildVersion: buildVersion,
    );
  }

  @ignore
  UploadStatus? get uploadStatus {
    final rawStatus = lastUploadStatus;
    if (rawStatus == null) return null;
    final status = UploadStatusType.values.where((value) {
      return value.name == rawStatus;
    }).firstOrNull;
    if (status == null) return null;
    return UploadStatus(
      status: status,
      message: lastUploadMessage ?? '',
      manifestHash: manifestHash,
    );
  }

  static String makeIdentityKey({
    required String namespace,
    required String catalogItemId,
    required String appName,
    required String assetId,
  }) {
    return [
      namespace.trim().toLowerCase(),
      catalogItemId.trim().toLowerCase(),
      appName.trim().toLowerCase(),
      assetId.trim().toLowerCase(),
    ].join('|');
  }
}
