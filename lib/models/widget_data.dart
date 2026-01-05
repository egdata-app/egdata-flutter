import 'dart:convert';
import 'api/free_game.dart';

/// Lightweight model for widget display
class WidgetFreeGame {
  final String id;
  final String title;
  final String? thumbnailUrl;
  final DateTime endDate;

  WidgetFreeGame({
    required this.id,
    required this.title,
    this.thumbnailUrl,
    required this.endDate,
  });

  /// Create from full FreeGame model
  factory WidgetFreeGame.fromFreeGame(FreeGame game) {
    return WidgetFreeGame(
      id: game.id,
      title: game.title,
      thumbnailUrl: _extractThumbnailUrl(game),
      endDate: game.giveaway?.endDate ?? DateTime.now(),
    );
  }

  /// Extract thumbnail URL with priority: OfferImageTall > DieselGameBoxTall > Thumbnail > first image
  static String? _extractThumbnailUrl(FreeGame game) {
    if (game.keyImages.isEmpty) return null;

    // Priority 1: OfferImageTall - 3:4 portrait (1200x1600) - perfect for widget
    final offerTall = game.keyImages
        .where((img) => img.type == 'OfferImageTall')
        .firstOrNull;
    if (offerTall != null) return offerTall.url;

    // Priority 2: DieselGameBoxTall - vertical box art
    final boxTall = game.keyImages
        .where((img) => img.type == 'DieselGameBoxTall')
        .firstOrNull;
    if (boxTall != null) return boxTall.url;

    // Priority 3: Thumbnail
    final thumbnail = game.keyImages
        .where((img) => img.type == 'Thumbnail')
        .firstOrNull;
    if (thumbnail != null) return thumbnail.url;

    // Fallback: First available image
    return game.keyImages.first.url;
  }

  /// Serialize to JSON for SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'thumbnailUrl': thumbnailUrl,
      'endDate': endDate.toIso8601String(),
    };
  }

  /// Deserialize from JSON
  factory WidgetFreeGame.fromJson(Map<String, dynamic> json) {
    return WidgetFreeGame(
      id: json['id'] as String,
      title: json['title'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      endDate: DateTime.parse(json['endDate'] as String),
    );
  }
}

/// Container for all widget data
class WidgetData {
  final List<WidgetFreeGame> games;
  final DateTime lastUpdate;

  WidgetData({
    required this.games,
    required this.lastUpdate,
  });

  /// Serialize to JSON string for SharedPreferences
  String toJsonString() {
    return jsonEncode(toJson());
  }

  Map<String, dynamic> toJson() {
    return {
      'games': games.map((g) => g.toJson()).toList(),
      'lastUpdate': lastUpdate.toIso8601String(),
    };
  }

  /// Deserialize from JSON string
  factory WidgetData.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return WidgetData.fromJson(json);
  }

  factory WidgetData.fromJson(Map<String, dynamic> json) {
    return WidgetData(
      games: (json['games'] as List<dynamic>)
          .map((e) => WidgetFreeGame.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastUpdate: DateTime.parse(json['lastUpdate'] as String),
    );
  }

  /// Check if data is stale (older than 6 hours)
  bool get isStale {
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);
    return difference.inHours >= 6;
  }

  /// Check if empty
  bool get isEmpty => games.isEmpty;
}
