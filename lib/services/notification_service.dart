import 'dart:io';
import 'package:local_notifier/local_notifier.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    if (Platform.isWindows || Platform.isMacOS) {
      await localNotifier.setup(
        appName: 'EGData Client',
        shortcutPolicy: ShortcutPolicy.requireCreate,
      );
      _isInitialized = true;
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) return;

    final notification = LocalNotification(
      title: title,
      body: body,
    );

    await notification.show();
  }

  void dispose() {
    // Nothing to dispose now
  }
}
