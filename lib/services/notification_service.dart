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

    if (Platform.isWindows || Platform.isMacOS) {
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: false,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        macOS: darwinSettings,
      );

      await _notificationsPlugin.initialize(initSettings);
      _isInitialized = true;
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) return;

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      macOS: darwinDetails,
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
    );
  }

  void dispose() {
    // Nothing to dispose
  }
}
