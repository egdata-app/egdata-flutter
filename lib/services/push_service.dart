import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../database/database_service.dart';
import '../utils/platform_utils.dart';
import 'notification_service.dart';

/// Generates a UUID v4
String _generateUuid() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));

  // Set version (4) and variant bits
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  String hex(int byte) => byte.toRadixString(16).padLeft(2, '0');

  return '${hex(bytes[0])}${hex(bytes[1])}${hex(bytes[2])}${hex(bytes[3])}-'
      '${hex(bytes[4])}${hex(bytes[5])}-'
      '${hex(bytes[6])}${hex(bytes[7])}-'
      '${hex(bytes[8])}${hex(bytes[9])}-'
      '${hex(bytes[10])}${hex(bytes[11])}${hex(bytes[12])}${hex(bytes[13])}${hex(bytes[14])}${hex(bytes[15])}';
}

/// Available push notification topics
class PushTopics {
  static const String freeGames = 'free-games';
  static const String sales = 'sales';
  static const String releases = 'releases';

  static const List<String> all = [freeGames, sales, releases];
}

/// Service for managing push notification subscriptions via FCM
class PushService {
  final DatabaseService _db;
  final NotificationService _notification;

  FirebaseMessaging? _messaging;
  String? _fcmToken;
  bool _initialized = false;

  PushService({
    required DatabaseService db,
    required NotificationService notification,
  })  : _db = db,
        _notification = notification;

  bool get isInitialized => _initialized;
  String? get fcmToken => _fcmToken;

  /// Check if push notifications are available (Firebase is configured)
  bool get isAvailable => PlatformUtils.isMobile && Firebase.apps.isNotEmpty;

  /// Initialize Firebase Messaging for mobile platforms
  Future<void> init() async {
    if (_initialized) return;

    // Firebase Messaging only works on mobile platforms
    if (!PlatformUtils.isMobile) {
      _initialized = true;
      return;
    }

    // Check if Firebase is initialized
    if (Firebase.apps.isEmpty) {
      debugPrint('PushService: Firebase not initialized, push notifications disabled');
      _initialized = true;
      return;
    }

    try {
      _messaging = FirebaseMessaging.instance;

      // Request permission
      final settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Get FCM token
        _fcmToken = await _messaging!.getToken();
        debugPrint('PushService: FCM Token: $_fcmToken');

        // Listen for token refresh
        _messaging!.onTokenRefresh.listen(_handleTokenRefresh);

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle background message tap
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
      } else {
        debugPrint('PushService: Push notification permission denied');
      }

      _initialized = true;
    } catch (e) {
      debugPrint('PushService: Failed to initialize: $e');
      // Don't throw - push notifications are optional
      _initialized = true;
    }
  }

  void _handleTokenRefresh(String newToken) async {
    debugPrint('PushService: FCM Token refreshed: $newToken');
    _fcmToken = newToken;

    // If we have an existing subscription, we need to re-subscribe with the new token
    final subscription = await _db.getPushSubscription();
    if (subscription != null) {
      // The old subscription is now invalid, delete it
      await _db.clearAllPushSubscriptions();
      debugPrint('PushService: Token changed, subscription cleared. User needs to re-subscribe.');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('PushService: Received foreground message: ${message.notification?.title}');

    // Show local notification for foreground messages
    if (message.notification != null) {
      _notification.showNotification(
        title: message.notification!.title ?? 'EGData',
        body: message.notification!.body ?? '',
        payload: message.data['offerId'] as String?,
      );
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('PushService: Message opened app: ${message.notification?.title}');
    // Handle navigation based on message data
    // This can be expanded to navigate to specific pages
  }

  /// Subscribe to push notifications using FCM topics
  Future<PushSubscriptionResult> subscribe({
    List<String> topics = const [],
  }) async {
    if (!PlatformUtils.isMobile) {
      return PushSubscriptionResult(
        success: false,
        error: 'Push notifications are only available on mobile devices',
      );
    }

    if (Firebase.apps.isEmpty || _messaging == null) {
      return PushSubscriptionResult(
        success: false,
        error: 'Firebase not configured. Add google-services.json to enable push notifications.',
      );
    }

    try {
      // Generate a local subscription ID
      final subscriptionId = _generateUuid();

      // Subscribe to FCM topics directly
      for (final topic in topics) {
        debugPrint('PushService: Subscribing to FCM topic: $topic');
        await _messaging!.subscribeToTopic(topic);
      }

      // Save subscription locally
      final entry = PushSubscriptionEntry()
        ..subscriptionId = subscriptionId
        ..endpoint = _fcmToken ?? 'fcm'
        ..topics = topics
        ..createdAt = DateTime.now();
      await _db.savePushSubscription(entry);

      debugPrint('PushService: Successfully subscribed to ${topics.length} topics');

      return PushSubscriptionResult(
        success: true,
        subscriptionId: subscriptionId,
        message: 'Subscribed to push notifications',
      );
    } catch (e) {
      debugPrint('PushService: Failed to subscribe: $e');
      return PushSubscriptionResult(
        success: false,
        error: 'Failed to subscribe: $e',
      );
    }
  }

  /// Unsubscribe from all push notifications
  Future<PushSubscriptionResult> unsubscribe() async {
    try {
      final subscription = await _db.getPushSubscription();
      debugPrint('PushService: Unsubscribing, local subscription: ${subscription?.subscriptionId}');

      if (subscription == null) {
        return PushSubscriptionResult(
          success: true,
          message: 'No active subscription',
        );
      }

      // Unsubscribe from all FCM topics
      if (_messaging != null) {
        for (final topic in subscription.topics) {
          debugPrint('PushService: Unsubscribing from FCM topic: $topic');
          await _messaging!.unsubscribeFromTopic(topic);
        }
      }

      // Delete local subscription
      await _db.deletePushSubscription(subscription.subscriptionId);
      debugPrint('PushService: Successfully unsubscribed from all topics');

      return PushSubscriptionResult(
        success: true,
        message: 'Successfully unsubscribed',
      );
    } catch (e) {
      debugPrint('PushService: Exception during unsubscribe: $e');
      return PushSubscriptionResult(
        success: false,
        error: 'Failed to unsubscribe: $e',
      );
    }
  }

  /// Subscribe to additional FCM topics
  Future<PushSubscriptionResult> subscribeToTopics({
    required List<String> topics,
  }) async {
    try {
      final subscription = await _db.getPushSubscription();
      debugPrint('PushService: Subscribe to topics $topics, subscription: ${subscription?.subscriptionId}');

      if (subscription == null) {
        return PushSubscriptionResult(
          success: false,
          error: 'No active subscription. Please subscribe first.',
        );
      }

      if (_messaging == null) {
        return PushSubscriptionResult(
          success: false,
          error: 'Firebase Messaging not initialized',
        );
      }

      // Subscribe to FCM topics directly
      for (final topic in topics) {
        debugPrint('PushService: Subscribing to FCM topic: $topic');
        await _messaging!.subscribeToTopic(topic);
      }

      // Update local topics
      final updatedTopics = {...subscription.topics, ...topics}.toList();
      await _db.updatePushSubscriptionTopics(subscription.subscriptionId, updatedTopics);

      debugPrint('PushService: Successfully subscribed to topics: $updatedTopics');

      return PushSubscriptionResult(
        success: true,
        message: 'Subscribed to topics',
        topics: updatedTopics,
      );
    } catch (e) {
      debugPrint('PushService: Exception subscribing to topics: $e');
      return PushSubscriptionResult(
        success: false,
        error: 'Failed to subscribe to topics: $e',
      );
    }
  }

  /// Unsubscribe from specific FCM topics
  Future<PushSubscriptionResult> unsubscribeFromTopics({
    required List<String> topics,
  }) async {
    try {
      final subscription = await _db.getPushSubscription();
      debugPrint('PushService: Unsubscribe from topics $topics, subscription: ${subscription?.subscriptionId}');

      if (subscription == null) {
        return PushSubscriptionResult(
          success: false,
          error: 'No active subscription',
        );
      }

      if (_messaging == null) {
        return PushSubscriptionResult(
          success: false,
          error: 'Firebase Messaging not initialized',
        );
      }

      // Unsubscribe from FCM topics directly
      for (final topic in topics) {
        debugPrint('PushService: Unsubscribing from FCM topic: $topic');
        await _messaging!.unsubscribeFromTopic(topic);
      }

      // Update local topics
      final updatedTopics = subscription.topics.where((t) => !topics.contains(t)).toList();
      await _db.updatePushSubscriptionTopics(subscription.subscriptionId, updatedTopics);

      debugPrint('PushService: Successfully unsubscribed, remaining topics: $updatedTopics');

      return PushSubscriptionResult(
        success: true,
        message: 'Unsubscribed from topics',
        topics: updatedTopics,
      );
    } catch (e) {
      debugPrint('PushService: Exception unsubscribing from topics: $e');
      return PushSubscriptionResult(
        success: false,
        error: 'Failed to unsubscribe from topics: $e',
      );
    }
  }

  /// Get current subscription status
  Future<PushSubscriptionState> getSubscriptionState() async {
    final localSubscription = await _db.getPushSubscription();
    return PushSubscriptionState(
      isSubscribed: localSubscription != null,
      subscriptionId: localSubscription?.subscriptionId,
      topics: localSubscription?.topics ?? [],
    );
  }

  /// Check if subscribed to a specific topic
  Future<bool> isSubscribedToTopic(String topic) async {
    final subscription = await _db.getPushSubscription();
    return subscription?.topics.contains(topic) ?? false;
  }

  void dispose() {
    // Nothing to dispose for FCM-based subscriptions
  }
}

/// Result of a push subscription operation
class PushSubscriptionResult {
  final bool success;
  final String? subscriptionId;
  final String? deviceId;
  final String? message;
  final String? error;
  final List<String>? topics;

  PushSubscriptionResult({
    required this.success,
    this.subscriptionId,
    this.deviceId,
    this.message,
    this.error,
    this.topics,
  });
}

/// Current state of push subscription
class PushSubscriptionState {
  final bool isSubscribed;
  final String? subscriptionId;
  final List<String> topics;

  PushSubscriptionState({
    required this.isSubscribed,
    this.subscriptionId,
    required this.topics,
  });
}
