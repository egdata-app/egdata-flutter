import 'dart:io';
import 'package:flutter/services.dart';

/// Service to communicate window settings to native macOS code.
/// Used to sync the minimize-to-tray preference with the native window delegate.
class WindowChannelService {
  static final WindowChannelService _instance = WindowChannelService._internal();
  factory WindowChannelService() => _instance;
  WindowChannelService._internal();

  static const MethodChannel _channel = MethodChannel('com.egdata.app/window');

  /// Updates the native macOS window delegate with the minimize-to-tray preference.
  /// When enabled, clicking the red close button will hide the window instead of quitting.
  Future<void> setMinimizeToTray(bool value) async {
    if (!Platform.isMacOS) return;

    try {
      await _channel.invokeMethod('setMinimizeToTray', value);
    } on PlatformException catch (e) {
      // Log but don't crash if method channel fails
      print('Failed to set minimize to tray: ${e.message}');
    }
  }
}
