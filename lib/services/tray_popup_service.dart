import 'dart:io';
import 'package:flutter/services.dart';

/// Service to communicate with the native macOS tray popup.
class TrayPopupService {
  static final TrayPopupService _instance = TrayPopupService._internal();
  factory TrayPopupService() => _instance;
  TrayPopupService._internal();

  static const MethodChannel _channel = MethodChannel('com.egdata.app/tray_popup');

  Function()? onOpenApp;

  void init() {
    if (!Platform.isMacOS) return;

    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onOpenApp':
          onOpenApp?.call();
          break;
      }
    });
  }

  /// Shows the popup at the specified screen coordinates.
  Future<void> showPopup({required double x, required double y}) async {
    if (!Platform.isMacOS) return;

    try {
      await _channel.invokeMethod('showPopup', {'x': x, 'y': y});
    } on PlatformException catch (e) {
      print('Failed to show tray popup: ${e.message}');
    }
  }

  /// Hides the popup.
  Future<void> hidePopup() async {
    if (!Platform.isMacOS) return;

    try {
      await _channel.invokeMethod('hidePopup');
    } on PlatformException catch (e) {
      print('Failed to hide tray popup: ${e.message}');
    }
  }

  /// Updates the popup stats.
  Future<void> updateStats({
    required String weeklyPlaytime,
    required int gamesInstalled,
    String? mostPlayedGame,
    String? currentGame,
    String? currentSessionTime,
  }) async {
    if (!Platform.isMacOS) return;

    try {
      await _channel.invokeMethod('updateStats', {
        'weeklyPlaytime': weeklyPlaytime,
        'gamesInstalled': gamesInstalled,
        'mostPlayedGame': mostPlayedGame,
        'currentGame': currentGame,
        'currentSessionTime': currentSessionTime,
      });
    } on PlatformException catch (e) {
      print('Failed to update tray popup stats: ${e.message}');
    }
  }
}
