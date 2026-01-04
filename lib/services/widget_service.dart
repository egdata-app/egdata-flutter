import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import '../models/widget_data.dart';
import '../database/database_service.dart';
import 'api_service.dart';

/// Service for updating Android home screen widget with free games data
class WidgetService {
  final ApiService _api;

  WidgetService({
    ApiService? apiService,
  }) : _api = apiService ?? ApiService();

  /// Update widget with current free games data
  Future<void> updateWidget() async {
    try {
      // Fetch active free games
      final games = await _fetchActiveFreeGames();

      // Limit to 6 games max for widget display
      final limitedGames = games.take(6).toList();

      // Convert to widget models
      final widgetGames = limitedGames
          .map((game) => WidgetFreeGame.fromFreeGame(game))
          .toList();

      // Create widget data
      final widgetData = WidgetData(
        games: widgetGames,
        lastUpdate: DateTime.now(),
      );

      // Save to SharedPreferences via home_widget
      await HomeWidget.saveWidgetData<String>(
        'widget_data',
        widgetData.toJsonString(),
      );

      // Trigger widget update
      await HomeWidget.updateWidget(
        name: 'FreeGamesWidgetProvider',
        androidName: 'FreeGamesWidgetProvider',
      );

      debugPrint('Widget updated successfully with ${widgetGames.length} games');
    } catch (e) {
      debugPrint('Error updating widget: $e');
      // Don't rethrow - widget update failures shouldn't crash the app
    }
  }

  /// Fetch active free games from API (or DB on failure)
  Future<List<FreeGame>> _fetchActiveFreeGames() async {
    try {
      // Try API first
      final allGames = await _api.getFreeGames();
      return _filterActiveGames(allGames);
    } catch (e) {
      debugPrint('API fetch failed, falling back to database: $e');
      // Fallback to database cache
      return _fetchFromDatabase();
    }
  }

  /// Filter for currently active free games
  List<FreeGame> _filterActiveGames(List<FreeGame> games) {
    final now = DateTime.now();
    return games.where((game) {
      if (game.giveaway == null) return false;
      return now.isAfter(game.giveaway!.startDate) &&
          now.isBefore(game.giveaway!.endDate);
    }).toList();
  }

  /// Fetch free games from database cache
  Future<List<FreeGame>> _fetchFromDatabase() async {
    try {
      final db = await DatabaseService.getInstance();
      final entries = await db.getActiveFreeGames();

      // Convert database entries back to FreeGame models
      // Note: Database entries have limited data, so we reconstruct what we can
      return entries.map((entry) {
        return FreeGame(
          id: entry.offerId,
          namespace: entry.namespace ?? '',
          title: entry.title,
          description: '',
          offerType: 'BASE_GAME',
          effectiveDate: entry.startDate ?? DateTime.now(),
          creationDate: entry.syncedAt,
          lastModifiedDate: entry.syncedAt,
          isCodeRedemptionOnly: false,
          keyImages: entry.thumbnailUrl != null
              ? [
                  KeyImage(
                    type: 'Thumbnail',
                    url: entry.thumbnailUrl!,
                    md5: null,
                  )
                ]
              : [],
          seller: Seller(id: '', name: ''),
          urlSlug: '',
          tags: [],
          items: [],
          categories: [],
          developerDisplayName: '',
          publisherDisplayName: '',
          viewableDate: DateTime.now(),
          refundType: 'NON_REFUNDABLE',
          giveaway: entry.startDate != null && entry.endDate != null
              ? Giveaway(
                  startDate: entry.startDate!,
                  endDate: entry.endDate!,
                )
              : null,
        );
      }).toList();
    } catch (e) {
      debugPrint('Database fetch failed: $e');
      return [];
    }
  }

  /// Get current widget data (for debugging)
  Future<WidgetData?> getWidgetData() async {
    try {
      final jsonString = await HomeWidget.getWidgetData<String>('widget_data');
      if (jsonString == null) return null;
      return WidgetData.fromJsonString(jsonString);
    } catch (e) {
      debugPrint('Error reading widget data: $e');
      return null;
    }
  }

  /// Clear widget data
  Future<void> clearWidgetData() async {
    try {
      await HomeWidget.saveWidgetData<String>('widget_data', '');
      await HomeWidget.updateWidget(
        name: 'FreeGamesWidgetProvider',
        androidName: 'FreeGamesWidgetProvider',
      );
    } catch (e) {
      debugPrint('Error clearing widget data: $e');
    }
  }
}
