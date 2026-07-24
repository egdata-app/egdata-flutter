import 'package:flutter/foundation.dart';

import '../database/database_service.dart';
import '../models/epic_progress.dart';
import '../models/game_info.dart';
import '../models/library_game.dart';
import '../models/upload_status.dart';
import 'library_metadata_service.dart';
import 'manifest_scanner.dart';

enum LibrarySyncPhase {
  idle,
  loadingCache,
  scanningLocal,
  fetchingEpicLibrary,
  syncingMetadata,
  syncingProgress,
  completed,
  failed,
}

class LibrarySyncSnapshot {
  final LibrarySyncPhase phase;
  final String message;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final Object? error;

  const LibrarySyncSnapshot({
    this.phase = LibrarySyncPhase.idle,
    this.message = 'Idle',
    this.startedAt,
    this.finishedAt,
    this.error,
  });

  bool get isRunning =>
      phase != LibrarySyncPhase.idle &&
      phase != LibrarySyncPhase.completed &&
      phase != LibrarySyncPhase.failed;

  LibrarySyncSnapshot copyWith({
    LibrarySyncPhase? phase,
    String? message,
    DateTime? startedAt,
    DateTime? finishedAt,
    Object? error,
  }) {
    return LibrarySyncSnapshot(
      phase: phase ?? this.phase,
      message: message ?? this.message,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      error: error ?? this.error,
    );
  }
}

/// Local-first desktop library state.
///
/// AppShell owns the network/scanner actions, while this repository owns the
/// cached Isar-backed snapshots and the merged query surface consumed by
/// desktop pages.
class LibraryRepository extends ChangeNotifier {
  final DatabaseService database;
  final LibraryMetadataService metadataService;

  List<GameInfo> _allInstalledGames = const [];
  List<GameInfo> _installedGames = const [];
  List<OwnedGameEntry> _ownedGames = const [];
  Map<String, EpicGameProgress> _progressByCatalogItemId = const {};
  EpicProgressProofResult? _progressProof;
  LibrarySyncSnapshot _sync = const LibrarySyncSnapshot();

  LibraryRepository({required this.database, required this.metadataService});

  List<GameInfo> get allInstalledGames => _allInstalledGames;
  List<GameInfo> get installedGames => _installedGames;
  List<OwnedGameEntry> get ownedGames => _ownedGames;
  Map<String, LibraryMetadataEntry> get metadataByCatalogItemId =>
      metadataService.cache;
  Map<String, EpicGameProgress> get progressByCatalogItemId =>
      _progressByCatalogItemId;
  EpicProgressProofResult? get progressProof => _progressProof;
  LibrarySyncSnapshot get sync => _sync;

  Future<void> loadCached() async {
    markSync(LibrarySyncPhase.loadingCache, 'Loading cached library');
    await metadataService.loadFromDatabase();
    final allInstalled = await database.getAllInstalledGames();
    final owned = await database.getAllOwnedGames();
    final progress = await database.getLibraryProgressMap();
    final proof = await database.getOfficialProgressProof();

    _allInstalledGames = allInstalled;
    _installedGames = ManifestScanner.groupGamesByMainGame(allInstalled);
    _ownedGames = owned;
    _progressByCatalogItemId = progress;
    _progressProof = proof;
    _sync = LibrarySyncSnapshot(
      phase: LibrarySyncPhase.completed,
      message: 'Cached library loaded',
      finishedAt: DateTime.now(),
    );
    notifyListeners();
  }

  Future<void> replaceInstalledGames(List<GameInfo> allGames) async {
    await database.replaceInstalledGames(allGames);
    _allInstalledGames = List<GameInfo>.from(allGames);
    _installedGames = ManifestScanner.groupGamesByMainGame(allGames);
    notifyListeners();
  }

  Future<void> reloadOwnedGames() async {
    _ownedGames = await database.getAllOwnedGames();
    notifyListeners();
  }

  Future<void> replaceProgressSnapshot(EpicProgressSnapshot snapshot) async {
    _progressProof = snapshot.proof;
    _progressByCatalogItemId = {
      ..._progressByCatalogItemId,
      ...snapshot.gamesByCatalogItemId,
    };
    await database.saveOfficialProgressProof(snapshot.proof);
    await database.saveLibraryProgressBatch(
      snapshot.gamesByCatalogItemId.values,
    );
    notifyListeners();
  }

  Future<void> replaceProgressProof(EpicProgressProofResult proof) async {
    _progressProof = proof;
    await database.saveOfficialProgressProof(proof);
    notifyListeners();
  }

  void refreshMetadataCache() {
    notifyListeners();
  }

  void markSync(LibrarySyncPhase phase, String message, {Object? error}) {
    final now = DateTime.now();
    _sync = LibrarySyncSnapshot(
      phase: phase,
      message: message,
      startedAt: _sync.isRunning ? _sync.startedAt : now,
      finishedAt:
          phase == LibrarySyncPhase.completed ||
              phase == LibrarySyncPhase.failed
          ? now
          : null,
      error: error,
    );
    notifyListeners();
  }

  List<LibraryGame> mergedGames({
    Map<String, UploadStatus> localUploadStatuses = const {},
    Map<String, UploadStatus> ownedUploadStatuses = const {},
    Set<String> uploadingInstalledIds = const {},
    Set<String> syncingOwnedKeys = const {},
  }) {
    return LibraryGame.merge(
      installedGames: _installedGames,
      ownedGames: _ownedGames,
      localUploadStatuses: localUploadStatuses,
      ownedUploadStatuses: ownedUploadStatuses,
      uploadingInstalledIds: uploadingInstalledIds,
      syncingOwnedKeys: syncingOwnedKeys,
      metadataByCatalogItemId: metadataService.cache,
      progressByCatalogItemId: _progressByCatalogItemId,
    );
  }

  LibraryGame? findGameByIdentityKey(
    String identityKey, {
    Map<String, UploadStatus> localUploadStatuses = const {},
    Map<String, UploadStatus> ownedUploadStatuses = const {},
    Set<String> uploadingInstalledIds = const {},
    Set<String> syncingOwnedKeys = const {},
  }) {
    final normalized = identityKey.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    for (final game in mergedGames(
      localUploadStatuses: localUploadStatuses,
      ownedUploadStatuses: ownedUploadStatuses,
      uploadingInstalledIds: uploadingInstalledIds,
      syncingOwnedKeys: syncingOwnedKeys,
    )) {
      if (game.identityKey.toLowerCase() == normalized) return game;
    }
    return null;
  }

  LibraryGame? findGameByCatalogItemId(
    String catalogItemId, {
    Map<String, UploadStatus> localUploadStatuses = const {},
    Map<String, UploadStatus> ownedUploadStatuses = const {},
    Set<String> uploadingInstalledIds = const {},
    Set<String> syncingOwnedKeys = const {},
  }) {
    final normalized = catalogItemId.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    for (final game in mergedGames(
      localUploadStatuses: localUploadStatuses,
      ownedUploadStatuses: ownedUploadStatuses,
      uploadingInstalledIds: uploadingInstalledIds,
      syncingOwnedKeys: syncingOwnedKeys,
    )) {
      if (game.catalogItemId.toLowerCase() == normalized) return game;
    }
    return null;
  }

  LibraryGame? findInstalledGame(
    GameInfo installed, {
    Map<String, UploadStatus> localUploadStatuses = const {},
    Map<String, UploadStatus> ownedUploadStatuses = const {},
    Set<String> uploadingInstalledIds = const {},
    Set<String> syncingOwnedKeys = const {},
  }) {
    final games = mergedGames(
      localUploadStatuses: localUploadStatuses,
      ownedUploadStatuses: ownedUploadStatuses,
      uploadingInstalledIds: uploadingInstalledIds,
      syncingOwnedKeys: syncingOwnedKeys,
    );
    for (final game in games) {
      if (identical(game.installedGame, installed)) return game;
      if (game.installedGame?.installationGuid == installed.installationGuid) {
        return game;
      }
    }
    final catalogItemId = installed.catalogItemId.trim();
    if (catalogItemId.isNotEmpty) {
      return findGameByCatalogItemId(
        catalogItemId,
        localUploadStatuses: localUploadStatuses,
        ownedUploadStatuses: ownedUploadStatuses,
        uploadingInstalledIds: uploadingInstalledIds,
        syncingOwnedKeys: syncingOwnedKeys,
      );
    }
    return null;
  }
}
