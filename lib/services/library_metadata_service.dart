import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';

import '../database/database_service.dart';
import 'api_service.dart';

/// Result of a metadata sync run.
class LibraryMetadataSyncResult {
  final int requested;
  final int resolved;
  final int empty;
  final int errors;
  final Duration elapsed;

  const LibraryMetadataSyncResult({
    required this.requested,
    required this.resolved,
    required this.empty,
    required this.errors,
    required this.elapsed,
  });

  @override
  String toString() =>
      'metadata sync: $resolved resolved, $empty empty, $errors errors '
      '(${elapsed.inMilliseconds}ms)';
}

/// Caches `/items/:id/offer` results in Isar so the library can filter
/// and sort by offer-level fields (offerType, tags, releaseDate, price)
/// without per-render network calls.
class LibraryMetadataService extends ChangeNotifier {
  static const Duration defaultStaleAfter = Duration(days: 7);

  final DatabaseService _db;
  final ApiService _api;

  Map<String, LibraryMetadataEntry> _cache = const {};
  bool _loaded = false;
  bool _syncing = false;
  int _syncProgress = 0;
  int _syncTotal = 0;
  DateTime? _lastSyncAt;

  LibraryMetadataService({
    required DatabaseService database,
    required ApiService api,
  }) : _db = database,
       _api = api;

  bool get isSyncing => _syncing;
  int get syncProgress => _syncProgress;
  int get syncTotal => _syncTotal;
  DateTime? get lastSyncAt => _lastSyncAt;

  /// Returns the cached metadata entry for [catalogItemId], if any.
  /// Returns null both when the item hasn't been synced and when the
  /// API explicitly returned no BASE_GAME offer.
  LibraryMetadataEntry? get(String catalogItemId) {
    if (catalogItemId.isEmpty) return null;
    final entry = _cache[catalogItemId];
    if (entry == null) return null;
    // Treat empty placeholders as "no metadata available" for callers.
    if (entry.offerId == null) return null;
    return entry;
  }

  /// Snapshot map keyed by catalogItemId. Includes empty placeholders.
  Map<String, LibraryMetadataEntry> get cache => _cache;

  /// Loads cached metadata from Isar into memory.
  Future<void> loadFromDatabase() async {
    if (_loaded) return;
    _cache = await _db.getLibraryMetadataMap();
    _loaded = true;
    notifyListeners();
  }

  /// Returns the subset of [catalogItemIds] whose cached entry is missing
  /// or older than [staleAfter].
  List<String> _selectStale(
    Iterable<String> catalogItemIds,
    Duration staleAfter,
  ) {
    final now = DateTime.now();
    final ids = <String>[];
    for (final id in catalogItemIds) {
      if (id.isEmpty) continue;
      final entry = _cache[id];
      if (entry == null) {
        ids.add(id);
        continue;
      }
      if (entry.offerId == null) {
        ids.add(id);
        continue;
      }
      if (now.difference(entry.syncedAt) > staleAfter) {
        ids.add(id);
      }
    }
    // Dedupe while preserving order
    return ids.toSet().toList(growable: false);
  }

  /// Fetches and persists metadata for every catalog item ID in the input
  /// that's missing or stale. No-op when nothing is stale or a sync is
  /// already in flight.
  Future<LibraryMetadataSyncResult?> syncStale(
    Iterable<String> catalogItemIds, {
    Duration staleAfter = defaultStaleAfter,
    int concurrency = 8,
  }) async {
    if (_syncing) return null;
    if (!_loaded) await loadFromDatabase();

    final ids = _selectStale(catalogItemIds, staleAfter);
    if (ids.isEmpty) {
      return LibraryMetadataSyncResult(
        requested: 0,
        resolved: 0,
        empty: 0,
        errors: 0,
        elapsed: Duration.zero,
      );
    }

    return _runSync(ids, concurrency: concurrency);
  }

  /// Refreshes metadata for [catalogItemIds] regardless of staleness.
  Future<LibraryMetadataSyncResult?> refresh(
    Iterable<String> catalogItemIds, {
    int concurrency = 8,
  }) async {
    if (_syncing) return null;
    if (!_loaded) await loadFromDatabase();
    final ids = catalogItemIds
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (ids.isEmpty) {
      return LibraryMetadataSyncResult(
        requested: 0,
        resolved: 0,
        empty: 0,
        errors: 0,
        elapsed: Duration.zero,
      );
    }
    return _runSync(ids, concurrency: concurrency);
  }

  Future<LibraryMetadataSyncResult> _runSync(
    List<String> ids, {
    required int concurrency,
  }) async {
    final stopwatch = Stopwatch()..start();
    _syncing = true;
    _syncProgress = 0;
    _syncTotal = ids.length;
    notifyListeners();

    int resolved = 0;
    int empty = 0;
    int errors = 0;

    final pending = <LibraryMetadataEntry>[];
    const flushEvery = 25;

    Future<void> flush() async {
      if (pending.isEmpty) return;
      final batch = List<LibraryMetadataEntry>.from(pending);
      pending.clear();
      await _db.saveLibraryMetadataBatch(batch);
      for (final entry in batch) {
        _cache = {..._cache, entry.catalogItemId: entry};
      }
    }

    final results = await _api.bulkGetItemOffers(
      ids,
      concurrency: concurrency,
      onError: (id, error) {
        errors++;
        debugPrint('LibraryMetadataService error for $id: $error');
      },
    );

    for (final id in ids) {
      _syncProgress++;
      final offer = results[id];
      final entry = offer == null
          ? LibraryMetadataEntry.empty(id)
          : LibraryMetadataEntry.fromOffer(catalogItemId: id, offer: offer);
      pending.add(entry);
      if (offer == null) {
        empty++;
      } else {
        resolved++;
      }
      if (pending.length >= flushEvery) {
        await flush();
        notifyListeners();
      }
    }

    await flush();

    _lastSyncAt = DateTime.now();
    _syncing = false;
    _syncProgress = 0;
    _syncTotal = 0;
    stopwatch.stop();
    notifyListeners();

    final result = LibraryMetadataSyncResult(
      requested: ids.length,
      resolved: resolved,
      empty: empty,
      errors: errors,
      elapsed: stopwatch.elapsed,
    );
    debugPrint(result.toString());
    return result;
  }

  /// Removes cached metadata for items that are no longer in [keepIds].
  Future<void> pruneTo(Set<String> keepIds) async {
    if (!_loaded) await loadFromDatabase();
    if (_cache.isEmpty) return;
    final entries = _cache.values
        .where((e) => !keepIds.contains(e.catalogItemId))
        .toList();
    if (entries.isEmpty) return;
    final isar = _db.isar;
    await isar.writeTxn(() async {
      for (final entry in entries) {
        await isar.libraryMetadataEntrys
            .filter()
            .catalogItemIdEqualTo(entry.catalogItemId)
            .deleteAll();
      }
    });
    _cache = {
      for (final entry in _cache.values)
        if (keepIds.contains(entry.catalogItemId)) entry.catalogItemId: entry,
    };
    notifyListeners();
  }
}

/// Static helpers for using [Offer] data without going through the cache.
extension LibraryMetadataLookup on Map<String, LibraryMetadataEntry> {
  Iterable<String> allTags() sync* {
    final seen = <String>{};
    for (final entry in values) {
      for (final tag in entry.tags) {
        if (seen.add(tag)) yield tag;
      }
    }
  }
}
