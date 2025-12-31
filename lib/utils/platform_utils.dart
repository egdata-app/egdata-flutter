import 'dart:io';

/// Utility class for platform detection and feature flags.
///
/// Use this class to conditionally enable/disable features based on the
/// current platform. This enables the same codebase to run on desktop
/// (Windows, macOS) and mobile (Android, iOS) with appropriate features.
class PlatformUtils {
  PlatformUtils._();

  /// Whether the app is running on a desktop platform (Windows, macOS, Linux).
  static bool get isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  /// Whether the app is running on a mobile platform (Android, iOS).
  static bool get isMobile => Platform.isAndroid || Platform.isIOS;

  /// Individual platform checks.
  static bool get isWindows => Platform.isWindows;
  static bool get isMacOS => Platform.isMacOS;
  static bool get isLinux => Platform.isLinux;
  static bool get isAndroid => Platform.isAndroid;
  static bool get isIOS => Platform.isIOS;

  // Feature flags based on platform capabilities

  /// Whether the platform supports scanning Epic Games manifest files.
  /// Only available on Windows and macOS where Epic Games Launcher is installed.
  static bool get supportsManifestScanning => isDesktop;

  /// Whether the platform supports tracking game playtime via process detection.
  /// Only available on desktop platforms with process inspection capabilities.
  static bool get supportsPlaytimeTracking => isDesktop;

  /// Whether the platform supports system tray integration.
  /// Only available on desktop platforms.
  static bool get supportsTray => isDesktop;

  /// Whether the platform supports launch at startup functionality.
  /// Currently only Windows has full support.
  static bool get supportsLaunchAtStartup => isWindows;

  /// Whether the platform supports the auto-update system.
  /// Only available on desktop platforms.
  static bool get supportsAutoUpdate => isDesktop;

  /// Whether the platform supports local notifications.
  /// Available on all platforms.
  static bool get supportsLocalNotifications => true;

  /// Whether the platform supports push notifications.
  /// Mobile platforms have better push notification support.
  static bool get supportsPushNotifications => isMobile;
}
