import '../database/database_service.dart';
import '../models/settings.dart';
import 'api_service.dart';
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
  final ApiService _api;

  bool _isSyncing = false;

  SyncService({
    required DatabaseService db,
    required NotificationService notification,
    ApiService? api,
  })  : _db = db,
        _notification = notification,
        _api = api ?? ApiService();

  bool get isSyncing => _isSyncing;

  /// Performs a sync of free games, followed game prices, and changelogs.
  ///
  /// [settings] - App settings controlling notification preferences
  /// [isFirstSync] - If true, skips all notifications (used on first launch
  ///   to avoid flooding the user with notifications for existing free games)
  /// [skipLocalNotifications] - If true, skips local notifications entirely
  ///   (used on mobile where push notifications handle this instead)
  Future<SyncResult> performSync(
    AppSettings settings, {
    bool isFirstSync = false,
    bool skipLocalNotifications = false,
  }) async {
    if (_isSyncing) {
      return SyncResult(error: 'Sync already in progress');
    }

    _isSyncing = true;

    // Don't show notifications on first sync or when explicitly skipped
    final shouldNotify = !isFirstSync && !skipLocalNotifications;

    try {
      final newFreeGames = <FreeGameEntry>[];
      final gamesOnSale = <FollowedGameEntry>[];
      final newChangelogs = <ChangelogEntry>[];

      // 1. Sync free games (always sync, notify based on settings and flags)
      final freeGameResults = await _syncFreeGames(
        settings.notifyFreeGames && shouldNotify,
      );
      newFreeGames.addAll(freeGameResults);

      // 2. Sync followed games prices (check for sales)
      if (settings.notifySales) {
        final saleResults = await _syncFollowedGamePrices(
          notify: shouldNotify,
        );
        gamesOnSale.addAll(saleResults);
      }

      // 3. Sync changelogs for followed games
      if (settings.notifyFollowedUpdates) {
        final changelogResults = await _syncChangelogs(
          notify: shouldNotify,
        );
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
    final games = await _api.getFreeGames();
    final newGames = <FreeGameEntry>[];

    // Group games by title to merge platform variants
    final gamesByTitle = <String, List<FreeGame>>{};
    for (final game in games) {
      gamesByTitle.putIfAbsent(game.title, () => []).add(game);
    }

    for (final entry in gamesByTitle.entries) {
      final variants = entry.value;
      final firstVariant = variants.first;

      // Check if this free game already exists in the database
      final existing = await _db.getFreeGameByOfferId(firstVariant.id);

      if (existing == null) {
        // New free game detected!
        final newEntry = _freeGameEntryFromApi(firstVariant);

        // Merge platforms from all variants
        final platforms = <String>{};
        for (final variant in variants) {
          final platform = variant.giveaway?.title ?? 'epic';
          platforms.add(platform);
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

  FreeGameEntry _freeGameEntryFromApi(FreeGame game) {
    String? imageUrl;
    final preferredTypes = ['OfferImageWide', 'DieselStoreFrontWide', 'DieselGameBoxTall'];
    for (final type in preferredTypes) {
      for (final img in game.keyImages) {
        if (img.type == type) {
          imageUrl = img.url;
          break;
        }
      }
      if (imageUrl != null) break;
    }
    imageUrl ??= game.keyImages.isNotEmpty ? game.keyImages.first.url : null;

    return FreeGameEntry()
      ..offerId = game.id
      ..title = game.title
      ..namespace = game.namespace
      ..thumbnailUrl = imageUrl
      ..startDate = game.giveaway?.startDate
      ..endDate = game.giveaway?.endDate
      ..platforms = []
      ..syncedAt = DateTime.now()
      ..notifiedNewGame = false;
  }

  Future<List<FollowedGameEntry>> _syncFollowedGamePrices({
    bool notify = true,
  }) async {
    final followedGames = await _db.getAllFollowedGames();
    final gamesOnSale = <FollowedGameEntry>[];

    for (final game in followedGames) {
      try {
        final offer = await _api.getOffer(game.offerId);
        final totalPrice = offer.price?.totalPrice;

        if (totalPrice != null) {
          final originalPrice = totalPrice.originalPrice.toDouble();
          final discountPrice = totalPrice.discountPrice.toDouble();
          final currencyCode = totalPrice.currencyCode;
          final discountPercent = totalPrice.discountPercent;

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
            if (notify) {
              await _notification.showNotification(
                title: 'Game on Sale!',
                body: '${game.title} is now ${game.formattedDiscount} off!',
              );
            }
            game.notifiedSale = true;
            gamesOnSale.add(game);
          }

          // Reset notifiedSale if game is no longer on sale
          if (discountPercent == null || discountPercent == 0) {
            game.notifiedSale = false;
          }

          await _db.saveFollowedGame(game);
        }
      } catch (e) {
        // Skip this game on error, continue with others
        continue;
      }
    }

    return gamesOnSale;
  }

  Future<List<ChangelogEntry>> _syncChangelogs({
    bool notify = true,
  }) async {
    final followedGames = await _db.getAllFollowedGames();
    final newChangelogs = <ChangelogEntry>[];

    // Limit to first 10 followed games to avoid too many API calls
    final gamesToCheck = followedGames.take(10).toList();

    for (final game in gamesToCheck) {
      try {
        final changelog = await _api.getOfferChangelog(game.offerId, limit: 5);

        for (final change in changelog.elements) {
          final changeId = change.id;

          // Check if we've already processed this changelog entry
          final exists = await _db.changelogExists(game.offerId, changeId);
          if (exists) continue;

          // Only include changes from the last 30 days
          final daysSinceChange = DateTime.now().difference(change.timestamp).inDays;
          if (daysSinceChange > 30) continue;

          // Get the primary change type from metadata
          final changeType = change.metadata.changes.isNotEmpty
              ? change.metadata.changes.first.changeType
              : 'update';

          // New changelog entry detected
          final entry = ChangelogEntry()
            ..offerId = game.offerId
            ..changeId = changeId
            ..timestamp = change.timestamp
            ..changeType = changeType
            ..notified = false;

          await _db.saveChangelog(entry);

          // Show notification if enabled
          if (notify) {
            await _notification.showNotification(
              title: 'Game Updated',
              body: '${game.title} has been ${changeType}d',
            );
          }

          entry.notified = true;
          await _db.saveChangelog(entry);

          newChangelogs.add(entry);
        }

        // Update last changelog check time
        game.lastChangelogCheck = DateTime.now();
        if (changelog.elements.isNotEmpty) {
          game.lastChangelogId = changelog.elements.first.id;
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
