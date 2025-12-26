import 'dart:convert';

import 'package:http/http.dart' as http;

import '../database/database_service.dart';
import '../models/settings.dart';
import 'notification_service.dart';

class SyncResult {
  final List<FreeGameEntry> newFreeGames;
  final List<FollowedGameEntry> gamesOnSale;
  final List<ChangelogEntry> newChangelogs;
  final DateTime syncedAt;
  final String? error;

  SyncResult({
    this.newFreeGames = const [],
    this.gamesOnSale = const [],
    this.newChangelogs = const [],
    DateTime? syncedAt,
    this.error,
  }) : syncedAt = syncedAt ?? DateTime.now();

  bool get hasChanges =>
      newFreeGames.isNotEmpty ||
      gamesOnSale.isNotEmpty ||
      newChangelogs.isNotEmpty;
}

class SyncService {
  final DatabaseService _db;
  final NotificationService _notification;
  final http.Client _client;

  static const _baseUrl = 'https://api.egdata.app';

  bool _isSyncing = false;

  SyncService({
    required DatabaseService db,
    required NotificationService notification,
    http.Client? client,
  })  : _db = db,
        _notification = notification,
        _client = client ?? http.Client();

  bool get isSyncing => _isSyncing;

  Future<SyncResult> performSync(AppSettings settings) async {
    if (_isSyncing) {
      return SyncResult(error: 'Sync already in progress');
    }

    _isSyncing = true;

    try {
      final newFreeGames = <FreeGameEntry>[];
      final gamesOnSale = <FollowedGameEntry>[];
      final newChangelogs = <ChangelogEntry>[];

      // 1. Sync free games (always sync, notify based on settings)
      final freeGameResults = await _syncFreeGames(settings.notifyFreeGames);
      newFreeGames.addAll(freeGameResults);

      // 2. Sync followed games prices (check for sales)
      if (settings.notifySales) {
        final saleResults = await _syncFollowedGamePrices();
        gamesOnSale.addAll(saleResults);
      }

      // 3. Sync changelogs for followed games
      if (settings.notifyFollowedUpdates) {
        final changelogResults = await _syncChangelogs();
        newChangelogs.addAll(changelogResults);
      }

      // Clean up old data
      await _db.deleteExpiredFreeGames();
      await _db.cleanupOldChangelogs();

      return SyncResult(
        newFreeGames: newFreeGames,
        gamesOnSale: gamesOnSale,
        newChangelogs: newChangelogs,
      );
    } catch (e) {
      return SyncResult(error: e.toString());
    } finally {
      _isSyncing = false;
    }
  }

  Future<List<FreeGameEntry>> _syncFreeGames(bool notify) async {
    final response = await _client.get(Uri.parse('$_baseUrl/free-games'));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch free games: ${response.statusCode}');
    }

    final List<dynamic> games = jsonDecode(response.body);
    final newGames = <FreeGameEntry>[];

    // Group games by title to merge platform variants
    final gamesByTitle = <String, List<Map<String, dynamic>>>{};
    for (final game in games) {
      final title = game['title'] as String;
      gamesByTitle.putIfAbsent(title, () => []).add(game as Map<String, dynamic>);
    }

    for (final entry in gamesByTitle.entries) {
      final variants = entry.value;
      final firstVariant = variants.first;
      final offerId = firstVariant['id'] as String;

      // Check if this free game already exists in the database
      final existing = await _db.getFreeGameByOfferId(offerId);

      if (existing == null) {
        // New free game detected!
        final newEntry = FreeGameEntry.fromApiJson(firstVariant);

        // Merge platforms from all variants
        final platforms = <String>{};
        for (final variant in variants) {
          final giveaway = variant['giveaway'] as Map<String, dynamic>?;
          final platform = giveaway?['platform'] as String?;
          platforms.add(platform ?? 'epic');
        }
        newEntry.platforms = platforms.toList();

        await _db.saveFreeGame(newEntry);

        // Show notification if enabled and game is currently active
        if (notify && newEntry.isActive) {
          await _notification.showNotification(
            title: 'Free Game Available!',
            body: '${newEntry.title} is now free on Epic Games Store',
          );
          newEntry.notifiedNewGame = true;
          await _db.saveFreeGame(newEntry);
        }

        newGames.add(newEntry);
      } else {
        // Update existing entry with fresh data
        existing.syncedAt = DateTime.now();
        await _db.saveFreeGame(existing);
      }
    }

    return newGames;
  }

  Future<List<FollowedGameEntry>> _syncFollowedGamePrices() async {
    final followedGames = await _db.getAllFollowedGames();
    final gamesOnSale = <FollowedGameEntry>[];

    for (final game in followedGames) {
      try {
        final response = await _client.get(
          Uri.parse('$_baseUrl/offers/${game.offerId}'),
        );

        if (response.statusCode != 200) continue;

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final price = data['price'] as Map<String, dynamic>?;

        if (price != null) {
          final totalPrice = price['totalPrice'] as Map<String, dynamic>?;
          if (totalPrice != null) {
            final originalPrice = (totalPrice['originalPrice'] as num?)?.toDouble();
            final discountPrice = (totalPrice['discountPrice'] as num?)?.toDouble();
            final currencyCode = totalPrice['currencyCode'] as String?;

            // Calculate discount percentage
            int? discountPercent;
            if (originalPrice != null && discountPrice != null && originalPrice > 0) {
              discountPercent = ((1 - (discountPrice / originalPrice)) * 100).round();
            }

            final wasOnSale = game.isOnSale;
            final previousDiscountPercent = game.discountPercent;

            // Update pricing info
            game.originalPrice = originalPrice;
            game.currentPrice = discountPrice;
            game.discountPercent = discountPercent;
            game.priceCurrency = currencyCode;

            // Check if this is a new sale (wasn't on sale before, or discount increased)
            final isNewSale = discountPercent != null &&
                discountPercent > 0 &&
                (!wasOnSale || (previousDiscountPercent != null && discountPercent > previousDiscountPercent)) &&
                !game.notifiedSale;

            if (isNewSale) {
              await _notification.showNotification(
                title: 'Game on Sale!',
                body: '${game.title} is now ${game.formattedDiscount} off!',
              );
              game.notifiedSale = true;
              gamesOnSale.add(game);
            }

            // Reset notifiedSale if game is no longer on sale
            if (discountPercent == null || discountPercent == 0) {
              game.notifiedSale = false;
            }

            await _db.saveFollowedGame(game);
          }
        }
      } catch (e) {
        // Skip this game on error, continue with others
        continue;
      }
    }

    return gamesOnSale;
  }

  Future<List<ChangelogEntry>> _syncChangelogs() async {
    final followedGames = await _db.getAllFollowedGames();
    final newChangelogs = <ChangelogEntry>[];

    // Limit to first 10 followed games to avoid too many API calls
    final gamesToCheck = followedGames.take(10).toList();

    for (final game in gamesToCheck) {
      try {
        final response = await _client.get(
          Uri.parse('$_baseUrl/offers/${game.offerId}/changelog?limit=5'),
        );

        if (response.statusCode != 200) continue;

        final List<dynamic> changelog = jsonDecode(response.body);

        for (final change in changelog) {
          final changeMap = change as Map<String, dynamic>;
          final changeId = changeMap['_id'] as String? ??
              changeMap['id'] as String? ??
              DateTime.now().toIso8601String();

          // Check if we've already processed this changelog entry
          final exists = await _db.changelogExists(game.offerId, changeId);
          if (exists) continue;

          // Parse timestamp
          final timestamp = changeMap['timestamp'] != null
              ? DateTime.tryParse(changeMap['timestamp'] as String)
              : null;

          // Only include changes from the last 30 days
          if (timestamp != null) {
            final daysSinceChange = DateTime.now().difference(timestamp).inDays;
            if (daysSinceChange > 30) continue;
          }

          // New changelog entry detected
          final entry = ChangelogEntry.fromApiJson(game.offerId, changeMap);
          await _db.saveChangelog(entry);

          // Show notification
          final changeType = entry.changeType ?? 'updated';
          await _notification.showNotification(
            title: 'Game Updated',
            body: '${game.title} has been $changeType',
          );

          entry.notified = true;
          await _db.saveChangelog(entry);

          newChangelogs.add(entry);
        }

        // Update last changelog check time
        game.lastChangelogCheck = DateTime.now();
        if (changelog.isNotEmpty) {
          final latestChange = changelog.first as Map<String, dynamic>;
          game.lastChangelogId = latestChange['_id'] as String? ??
              latestChange['id'] as String?;
        }
        await _db.saveFollowedGame(game);
      } catch (e) {
        // Skip this game on error, continue with others
        continue;
      }
    }

    return newChangelogs;
  }
}
