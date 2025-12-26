import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'collections/free_game_entry.dart';
import 'collections/followed_game_entry.dart';
import 'collections/changelog_entry.dart';

export 'collections/free_game_entry.dart';
export 'collections/followed_game_entry.dart';
export 'collections/changelog_entry.dart';

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
      [FreeGameEntrySchema, FollowedGameEntrySchema, ChangelogEntrySchema],
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

  Future<void> close() async {
    await _isar.close();
    _initialized = false;
    _instance = null;
  }
}
