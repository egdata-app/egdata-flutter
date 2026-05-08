import '../database/collections/library_metadata_entry.dart';
import '../database/collections/owned_game_entry.dart';
import 'game_info.dart';
import 'upload_status.dart';

enum LibraryFilter { all, installed, notInstalled, favorites, uploads }

enum LibraryViewMode { grid, list }

/// What kind of offer a library item resolves to. Used for the
/// "Type" pill in the right sidebar (Games vs DLC vs Add-ons).
enum LibraryOfferTypeFilter { any, baseGame, dlc, addOn, edition, other }

extension LibraryOfferTypeFilterX on LibraryOfferTypeFilter {
  String get label => switch (this) {
    LibraryOfferTypeFilter.any => 'Any type',
    LibraryOfferTypeFilter.baseGame => 'Base games',
    LibraryOfferTypeFilter.dlc => 'DLC',
    LibraryOfferTypeFilter.addOn => 'Add-ons',
    LibraryOfferTypeFilter.edition => 'Editions',
    LibraryOfferTypeFilter.other => 'Other',
  };

  bool matches(String? offerType) {
    if (this == LibraryOfferTypeFilter.any) return true;
    final type = offerType?.toUpperCase() ?? '';
    return switch (this) {
      LibraryOfferTypeFilter.baseGame => type == 'BASE_GAME',
      LibraryOfferTypeFilter.dlc => type == 'DLC',
      LibraryOfferTypeFilter.addOn => type == 'ADD_ON' || type == 'ADDON',
      LibraryOfferTypeFilter.edition =>
        type == 'EDITION' || type == 'CONSUMABLE',
      LibraryOfferTypeFilter.other =>
        type.isNotEmpty &&
            type != 'BASE_GAME' &&
            type != 'DLC' &&
            type != 'ADD_ON' &&
            type != 'ADDON' &&
            type != 'EDITION',
      LibraryOfferTypeFilter.any => true,
    };
  }
}

enum LibrarySortBy { title, releaseDate, lastModified }

extension LibrarySortByX on LibrarySortBy {
  String get label => switch (this) {
    LibrarySortBy.title => 'Title',
    LibrarySortBy.releaseDate => 'Release date',
    LibrarySortBy.lastModified => 'Recently updated',
  };
}

class LibraryGame {
  final String identityKey;
  final String title;
  final String appName;
  final String namespace;
  final String catalogItemId;
  final String assetId;
  final String? buildVersion;
  final String? boxArtUrl;
  final String? wideImageUrl;
  final GameInfo? installedGame;
  final OwnedGameEntry? ownedGame;
  final UploadStatus? uploadStatus;
  final bool isUploadRunning;
  final LibraryMetadataEntry? metadata;

  const LibraryGame({
    required this.identityKey,
    required this.title,
    required this.appName,
    required this.namespace,
    required this.catalogItemId,
    required this.assetId,
    this.buildVersion,
    this.boxArtUrl,
    this.wideImageUrl,
    this.installedGame,
    this.ownedGame,
    this.uploadStatus,
    this.isUploadRunning = false,
    this.metadata,
  });

  String? get offerType => metadata?.offerType;
  List<String> get tags => metadata?.tags ?? const [];
  DateTime? get releaseDate => metadata?.releaseDate;
  DateTime? get lastModifiedDate => metadata?.lastModifiedDate;
  bool get isFreeMetadata => metadata?.isFree ?? false;
  bool get isOnSale => metadata?.isOnSale ?? false;
  String? get developerDisplayName => metadata?.developerDisplayName;
  String? get publisherDisplayName => metadata?.publisherDisplayName;

  bool get isInstalled => installedGame != null;

  bool get hasOwnedSource => ownedGame != null;

  bool get hasUploadActivity =>
      isUploadRunning ||
      uploadStatus != null ||
      ownedGame?.lastCloudSyncAt != null;

  String get installLocation => installedGame?.installLocation ?? '';

  String get versionLabel =>
      installedGame?.version ?? buildVersion ?? ownedGame?.buildVersion ?? '';

  String get statusLabel {
    if (isUploadRunning) return 'Uploading';
    final status = uploadStatus?.status;
    if (status == null) return isInstalled ? 'Installed' : 'Not installed';
    switch (status) {
      case UploadStatusType.uploaded:
        return 'Uploaded';
      case UploadStatusType.alreadyUploaded:
        return 'Exists';
      case UploadStatusType.failed:
        final message = uploadStatus?.message.toLowerCase() ?? '';
        return message.contains('no cloud manifest')
            ? 'No cloud manifest'
            : 'Failed';
      case UploadStatusType.pending:
        return 'Pending';
      case UploadStatusType.uploading:
        return 'Uploading';
    }
  }

  static List<LibraryGame> merge({
    required List<GameInfo> installedGames,
    required List<OwnedGameEntry> ownedGames,
    Map<String, UploadStatus> localUploadStatuses = const {},
    Map<String, UploadStatus> ownedUploadStatuses = const {},
    Set<String> uploadingInstalledIds = const {},
    Set<String> syncingOwnedKeys = const {},
    Map<String, LibraryMetadataEntry> metadataByCatalogItemId = const {},
  }) {
    final byKey = <String, LibraryGame>{};
    final ownedByCatalogApp = <String, OwnedGameEntry>{};
    final ownedGroups = <String, List<OwnedGameEntry>>{};

    LibraryMetadataEntry? metadataFor(String catalogItemId) {
      if (catalogItemId.isEmpty) return null;
      final entry = metadataByCatalogItemId[catalogItemId];
      if (entry == null) return null;
      // Empty placeholders carry no useful filter data; treat as null.
      if (entry.offerId == null) return null;
      return entry;
    }

    for (final owned in ownedGames) {
      final catalogAppKey = _ownedCatalogAppKey(owned);
      (ownedGroups[catalogAppKey] ??= []).add(owned);
    }

    for (final entries in ownedGroups.values) {
      final owned = _preferredOwnedEntry(entries, ownedUploadStatuses);
      final catalogAppKey = _ownedCatalogAppKey(owned);
      ownedByCatalogApp[catalogAppKey] = owned;
      final status = _preferredUploadStatus(entries, ownedUploadStatuses);
      byKey[owned.identityKey] = LibraryGame(
        identityKey: owned.identityKey,
        title: owned.title,
        appName: owned.appName,
        namespace: owned.namespace,
        catalogItemId: owned.catalogItemId,
        assetId: owned.assetId,
        buildVersion: owned.buildVersion,
        boxArtUrl: owned.boxArtUrl,
        wideImageUrl: owned.wideImageUrl,
        ownedGame: owned,
        uploadStatus: status,
        isUploadRunning: entries.any(
          (entry) => syncingOwnedKeys.contains(entry.identityKey),
        ),
        metadata: metadataFor(owned.catalogItemId),
      );
    }

    for (final installed in installedGames) {
      final matchedOwned =
          ownedByCatalogApp[_catalogAppKey(
            namespace: installed.catalogNamespace,
            catalogItemId: installed.catalogItemId,
            appName: installed.appName,
          )];
      final key = matchedOwned?.identityKey ?? _installedIdentityKey(installed);
      final existing = byKey[key];
      final localStatus = localUploadStatuses[installed.installationGuid];
      final uploadStatus = localStatus ?? existing?.uploadStatus;

      byKey[key] = LibraryGame(
        identityKey: key,
        title:
            existing?.title ??
            installed.metadata?.title ??
            installed.displayName,
        appName: installed.appName,
        namespace: installed.catalogNamespace,
        catalogItemId: installed.catalogItemId,
        assetId: existing?.assetId ?? installed.installationGuid,
        buildVersion: existing?.buildVersion ?? installed.version,
        boxArtUrl: existing?.boxArtUrl ?? installed.metadata?.dieselGameBoxTall,
        wideImageUrl:
            existing?.wideImageUrl ?? installed.metadata?.dieselGameBox,
        installedGame: installed,
        ownedGame: existing?.ownedGame ?? matchedOwned,
        uploadStatus: uploadStatus,
        isUploadRunning:
            uploadingInstalledIds.contains(installed.installationGuid) ||
            (existing != null &&
                syncingOwnedKeys.contains(existing.identityKey)),
        metadata: existing?.metadata ?? metadataFor(installed.catalogItemId),
      );
    }

    final games = byKey.values.toList();
    games.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );
    return games;
  }

  static String _installedIdentityKey(GameInfo game) {
    return OwnedGameEntry.makeIdentityKey(
      namespace: game.catalogNamespace,
      catalogItemId: game.catalogItemId,
      appName: game.appName,
      assetId: game.installationGuid,
    );
  }

  static String _catalogAppKey({
    required String namespace,
    required String catalogItemId,
    required String appName,
  }) {
    return [
      namespace.trim().toLowerCase(),
      catalogItemId.trim().toLowerCase(),
      appName.trim().toLowerCase(),
    ].join('|');
  }

  static String _ownedCatalogAppKey(OwnedGameEntry owned) {
    return _catalogAppKey(
      namespace: owned.namespace,
      catalogItemId: owned.catalogItemId,
      appName: owned.appName,
    );
  }

  static OwnedGameEntry _preferredOwnedEntry(
    List<OwnedGameEntry> entries,
    Map<String, UploadStatus> ownedUploadStatuses,
  ) {
    return entries.reduce((best, candidate) {
      final bestStatus =
          ownedUploadStatuses[best.identityKey] ?? best.uploadStatus;
      final candidateStatus =
          ownedUploadStatuses[candidate.identityKey] ?? candidate.uploadStatus;
      final statusCmp = _uploadStatusRank(
        candidateStatus,
      ).compareTo(_uploadStatusRank(bestStatus));
      if (statusCmp != 0) return statusCmp > 0 ? candidate : best;

      final imageCmp = _hasImage(candidate).compareTo(_hasImage(best));
      if (imageCmp != 0) return imageCmp > 0 ? candidate : best;

      final versionCmp = _hasBuildVersion(
        candidate,
      ).compareTo(_hasBuildVersion(best));
      if (versionCmp != 0) return versionCmp > 0 ? candidate : best;

      return candidate.identityKey.compareTo(best.identityKey) < 0
          ? candidate
          : best;
    });
  }

  static UploadStatus? _preferredUploadStatus(
    List<OwnedGameEntry> entries,
    Map<String, UploadStatus> ownedUploadStatuses,
  ) {
    UploadStatus? best;
    for (final entry in entries) {
      final status =
          ownedUploadStatuses[entry.identityKey] ?? entry.uploadStatus;
      if (status == null) continue;
      if (best == null || _uploadStatusRank(status) > _uploadStatusRank(best)) {
        best = status;
      }
    }
    return best;
  }

  static int _uploadStatusRank(UploadStatus? status) {
    return switch (status?.status) {
      UploadStatusType.uploaded => 4,
      UploadStatusType.alreadyUploaded => 4,
      UploadStatusType.uploading => 3,
      UploadStatusType.pending => 2,
      UploadStatusType.failed => 1,
      null => 0,
    };
  }

  static int _hasImage(OwnedGameEntry entry) {
    return (entry.boxArtUrl?.isNotEmpty == true ||
            entry.wideImageUrl?.isNotEmpty == true)
        ? 1
        : 0;
  }

  static int _hasBuildVersion(OwnedGameEntry entry) {
    return entry.buildVersion?.isNotEmpty == true ? 1 : 0;
  }
}
