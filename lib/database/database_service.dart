import 'dart:async';
import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'collections/free_game_entry.dart';
import 'collections/followed_game_entry.dart';
import 'collections/changelog_entry.dart';
import 'collections/playtime_session_entry.dart';
import 'collections/game_process_cache_entry.dart';

export 'collections/free_game_entry.dart';
export 'collections/followed_game_entry.dart';
export 'collections/changelog_entry.dart';
export 'collections/playtime_session_entry.dart';
export 'collections/game_process_cache_entry.dart';

class DatabaseService {
  static DatabaseService? _instance;
  late Isar _isar;
  bool _initialized = false;

  DatabaseService._();

  static Future<DatabaseService> getInstance() async {
    if (_instance == null) {
      _instance = DatabaseService._();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    if (_initialized) return;

    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [
        FreeGameEntrySchema,
        FollowedGameEntrySchema,
        ChangelogEntrySchema,
        PlaytimeSessionEntrySchema,
        GameProcessCacheEntrySchema,
      ],
      directory: dir.path,
      name: 'egdata',
    );
    _initialized = true;
  }

  Isar get isar => _isar;

  // Migration from SharedPreferences (followed games)
  Future<void> migrateFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if already migrated
    if (prefs.getBool('isar_migrated') == true) return;

    // Migrate followed games
    final followedJson = prefs.getString('followed_games');
    if (followedJson != null) {
      try {
        final List<dynamic> games = jsonDecode(followedJson);
        await _isar.writeTxn(() async {
          for (final json in games) {
            final entry = FollowedGameEntry()
              ..offerId = json['offerId'] as String
              ..title = json['title'] as String
              ..namespace = json['namespace'] as String?
              ..thumbnailUrl = json['thumbnailUrl'] as String?
              ..followedAt = json['followedAt'] != null
                  ? DateTime.parse(json['followedAt'] as String)
                  : DateTime.now();
            await _isar.followedGameEntrys.put(entry);
          }
        });
      } catch (e) {
        // Migration failed, but continue - user can re-follow games
        // Error logged silently - users can re-follow games if needed
      }
    }

    // Mark as migrated
    await prefs.setBool('isar_migrated', true);

    // Clear old data from SharedPreferences
    await prefs.remove('followed_games');
  }

  // Free Games operations
  Future<List<FreeGameEntry>> getAllFreeGames() async {
    return _isar.freeGameEntrys.where().findAll();
  }

  Future<List<FreeGameEntry>> getActiveFreeGames() async {
    final now = DateTime.now();
    return _isar.freeGameEntrys
        .filter()
        .startDateLessThan(now)
        .and()
        .endDateGreaterThan(now)
        .findAll();
  }

  Future<FreeGameEntry?> getFreeGameByOfferId(String offerId) async {
    return _isar.freeGameEntrys.filter().offerIdEqualTo(offerId).findFirst();
  }

  Future<void> saveFreeGame(FreeGameEntry entry) async {
    await _isar.writeTxn(() => _isar.freeGameEntrys.put(entry));
  }

  Future<void> saveFreeGames(List<FreeGameEntry> entries) async {
    await _isar.writeTxn(() => _isar.freeGameEntrys.putAll(entries));
  }

  Future<void> deleteExpiredFreeGames() async {
    final now = DateTime.now();
    final expiredThreshold = now.subtract(const Duration(days: 7));
    await _isar.writeTxn(() async {
      await _isar.freeGameEntrys
          .filter()
          .endDateLessThan(expiredThreshold)
          .deleteAll();
    });
  }

  // Followed Games operations
  Future<List<FollowedGameEntry>> getAllFollowedGames() async {
    return _isar.followedGameEntrys.where().findAll();
  }

  Future<FollowedGameEntry?> getFollowedGameByOfferId(String offerId) async {
    return _isar.followedGameEntrys.filter().offerIdEqualTo(offerId).findFirst();
  }

  Future<void> saveFollowedGame(FollowedGameEntry entry) async {
    await _isar.writeTxn(() => _isar.followedGameEntrys.put(entry));
  }

  Future<bool> deleteFollowedGame(String offerId) async {
    return await _isar.writeTxn(() async {
      return await _isar.followedGameEntrys
          .filter()
          .offerIdEqualTo(offerId)
          .deleteFirst();
    });
  }

  Future<bool> isFollowing(String offerId) async {
    final count = await _isar.followedGameEntrys
        .filter()
        .offerIdEqualTo(offerId)
        .count();
    return count > 0;
  }

  // Changelog operations
  Future<List<ChangelogEntry>> getChangelogForGame(String offerId) async {
    return _isar.changelogEntrys
        .filter()
        .offerIdEqualTo(offerId)
        .sortByTimestampDesc()
        .findAll();
  }

  Future<ChangelogEntry?> getLatestChangelogForGame(String offerId) async {
    return _isar.changelogEntrys
        .filter()
        .offerIdEqualTo(offerId)
        .sortByTimestampDesc()
        .findFirst();
  }

  Future<void> saveChangelog(ChangelogEntry entry) async {
    await _isar.writeTxn(() => _isar.changelogEntrys.put(entry));
  }

  Future<void> saveChangelogs(List<ChangelogEntry> entries) async {
    await _isar.writeTxn(() => _isar.changelogEntrys.putAll(entries));
  }

  Future<bool> changelogExists(String offerId, String changeId) async {
    final count = await _isar.changelogEntrys
        .filter()
        .offerIdEqualTo(offerId)
        .and()
        .changeIdEqualTo(changeId)
        .count();
    return count > 0;
  }

  // Clean up old changelog entries (older than 90 days)
  Future<void> cleanupOldChangelogs() async {
    final threshold = DateTime.now().subtract(const Duration(days: 90));
    await _isar.writeTxn(() async {
      await _isar.changelogEntrys
          .filter()
          .timestampLessThan(threshold)
          .deleteAll();
    });
  }

  // Playtime Session operations
  Future<List<PlaytimeSessionEntry>> getAllPlaytimeSessions() async {
    return _isar.playtimeSessionEntrys.where().findAll();
  }

  Future<List<PlaytimeSessionEntry>> getSessionsForGame(String gameId) async {
    return _isar.playtimeSessionEntrys
        .filter()
        .gameIdEqualTo(gameId)
        .sortByStartTimeDesc()
        .findAll();
  }

  Future<List<PlaytimeSessionEntry>> getSessionsInRange(
      DateTime start, DateTime end) async {
    return _isar.playtimeSessionEntrys
        .filter()
        .startTimeGreaterThan(start)
        .and()
        .startTimeLessThan(end)
        .sortByStartTimeDesc()
        .findAll();
  }

  Future<PlaytimeSessionEntry?> getActiveSession() async {
    return _isar.playtimeSessionEntrys
        .filter()
        .endTimeIsNull()
        .findFirst();
  }

  Future<void> savePlaytimeSession(PlaytimeSessionEntry entry) async {
    await _isar.writeTxn(() => _isar.playtimeSessionEntrys.put(entry));
  }

  Future<void> endSession(int sessionId, DateTime endTime) async {
    await _isar.writeTxn(() async {
      final session = await _isar.playtimeSessionEntrys.get(sessionId);
      if (session != null) {
        session.endTime = endTime;
        session.durationSeconds = endTime.difference(session.startTime).inSeconds;
        await _isar.playtimeSessionEntrys.put(session);
      }
    });
  }

  Future<int> getTotalPlaytimeSeconds(String gameId) async {
    final sessions = await _isar.playtimeSessionEntrys
        .filter()
        .gameIdEqualTo(gameId)
        .and()
        .endTimeIsNotNull()
        .findAll();
    return sessions.fold<int>(0, (sum, s) => sum + s.durationSeconds);
  }

  Future<Map<String, int>> getWeeklyPlaytimeByGame() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(weekStart.year, weekStart.month, weekStart.day);

    final sessions = await _isar.playtimeSessionEntrys
        .filter()
        .startTimeGreaterThan(startOfWeek)
        .and()
        .endTimeIsNotNull()
        .findAll();

    final playtimeByGame = <String, int>{};
    for (final session in sessions) {
      playtimeByGame[session.gameId] =
          (playtimeByGame[session.gameId] ?? 0) + session.durationSeconds;
    }
    return playtimeByGame;
  }

  Future<List<PlaytimeSessionEntry>> getRecentSessions({int limit = 10}) async {
    return _isar.playtimeSessionEntrys
        .where()
        .sortByStartTimeDesc()
        .limit(limit)
        .findAll();
  }

  // Clean up old playtime sessions (older than 90 days)
  Future<void> cleanupOldPlaytimeSessions() async {
    final threshold = DateTime.now().subtract(const Duration(days: 90));
    await _isar.writeTxn(() async {
      await _isar.playtimeSessionEntrys
          .filter()
          .startTimeLessThan(threshold)
          .deleteAll();
    });
  }

  // Game Process Cache operations
  Future<GameProcessCacheEntry?> getProcessCache(String catalogItemId) async {
    return _isar.gameProcessCacheEntrys
        .filter()
        .catalogItemIdEqualTo(catalogItemId)
        .findFirst();
  }

  Future<void> saveProcessCache(GameProcessCacheEntry entry) async {
    // Delete existing entry for this catalogItemId first
    await _isar.writeTxn(() async {
      await _isar.gameProcessCacheEntrys
          .filter()
          .catalogItemIdEqualTo(entry.catalogItemId)
          .deleteAll();
      await _isar.gameProcessCacheEntrys.put(entry);
    });
  }

  Future<void> clearProcessCache() async {
    await _isar.writeTxn(() => _isar.gameProcessCacheEntrys.clear());
  }

  Future<void> close() async {
    await _isar.close();
    _initialized = false;
    _instance = null;
  }

  // Manifest Upload Count operations
  static const String _uploadCountKey = 'manifest_upload_count';
  final _uploadCountController = StreamController<int>.broadcast();

  Stream<int> get uploadCountStream => _uploadCountController.stream;

  Future<int> getManifestUploadCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_uploadCountKey) ?? 0;
  }

  Future<void> incrementManifestUploadCount() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_uploadCountKey) ?? 0;
    final newCount = currentCount + 1;
    await prefs.setInt(_uploadCountKey, newCount);
    _uploadCountController.add(newCount);
  }
}
