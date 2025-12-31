import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    // Android initialization
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS/macOS initialization
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    final result = await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = result ?? false;

    // Request permissions on Android 13+
    if (Platform.isAndroid) {
      await _requestAndroidPermissions();
    }

    // Request permissions on iOS
    if (Platform.isIOS) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  Future<void> _requestAndroidPermissions() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - can be extended to navigate to specific pages
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) return;

    const androidDetails = AndroidNotificationDetails(
      'egdata_channel',
      'EGData Notifications',
      channelDescription: 'Notifications for free games and sales',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  Future<void> showFreeGameNotification({
    required String gameTitle,
    required String offerId,
  }) async {
    await showNotification(
      title: 'Free Game Available!',
      body: '$gameTitle is now free on Epic Games Store',
      payload: 'free_game:$offerId',
    );
  }

  Future<void> showSaleNotification({
    required String gameTitle,
    required int discountPercent,
    required String offerId,
  }) async {
    await showNotification(
      title: 'Game On Sale!',
      body: '$gameTitle is $discountPercent% off',
      payload: 'sale:$offerId',
    );
  }

  void dispose() {
    // Nothing to dispose
  }
}
