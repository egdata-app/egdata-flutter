import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Service for tracking user analytics events using Firebase Analytics
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  FirebaseAnalytics? _analytics;
  FirebaseAnalyticsObserver? _observer;

  /// Initialize Firebase Analytics
  Future<void> initialize() async {
    try {
      _analytics = FirebaseAnalytics.instance;
      _observer = FirebaseAnalyticsObserver(analytics: _analytics!);
      debugPrint('Firebase Analytics initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize Firebase Analytics: $e');
    }
  }

  /// Get the FirebaseAnalyticsObserver for navigation tracking
  FirebaseAnalyticsObserver? get observer => _observer;

  /// Track a custom event
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (_analytics == null) return;

    try {
      await _analytics!.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (e) {
      debugPrint('Failed to log event $name: $e');
    }
  }

  /// Track screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (_analytics == null) return;

    try {
      await _analytics!.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
    } catch (e) {
      debugPrint('Failed to log screen view $screenName: $e');
    }
  }

  /// Track game view
  Future<void> logGameView({
    required String gameId,
    required String gameName,
  }) async {
    await logEvent(
      name: 'view_game',
      parameters: {
        'game_id': gameId,
        'game_name': gameName,
      },
    );
  }

  /// Track search
  Future<void> logSearch({
    required String searchTerm,
    String? category,
  }) async {
    await logEvent(
      name: 'search',
      parameters: {
        'search_term': searchTerm,
        if (category != null) 'search_category': category,
      },
    );
  }

  /// Track game follow/unfollow
  Future<void> logFollowGame({
    required String gameId,
    required String gameName,
    required bool followed,
  }) async {
    await logEvent(
      name: followed ? 'follow_game' : 'unfollow_game',
      parameters: {
        'game_id': gameId,
        'game_name': gameName,
      },
    );
  }

  /// Track manifest upload (Desktop)
  Future<void> logManifestUpload({
    required int count,
    required bool success,
  }) async {
    await logEvent(
      name: 'manifest_upload',
      parameters: {
        'count': count,
        'success': success,
      },
    );
  }

  /// Track free game view
  Future<void> logFreeGameView({
    required String gameId,
    required String gameName,
  }) async {
    await logEvent(
      name: 'view_free_game',
      parameters: {
        'game_id': gameId,
        'game_name': gameName,
      },
    );
  }

  /// Set user properties
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    if (_analytics == null) return;

    try {
      await _analytics!.setUserProperty(
        name: name,
        value: value,
      );
    } catch (e) {
      debugPrint('Failed to set user property $name: $e');
    }
  }

  /// Set user country preference
  Future<void> setUserCountry(String country) async {
    await setUserProperty(
      name: 'user_country',
      value: country,
    );
  }
}
