class AppSettings {
  final bool autoSync;
  final int syncIntervalMinutes;
  final bool minimizeToTray;
  final bool launchAtStartup;
  final bool notifyFreeGames;
  final bool notifyReleases;
  final bool notifySales;
  final bool notifyFollowedUpdates;
  final String country;
  // Push notification settings - deviceId is auto-generated UUID for API auth
  final String? deviceId;
  final bool pushNotificationsEnabled;
  final bool hasSeenFreeGamesNotificationPrompt;

  AppSettings({
    this.autoSync = false,
    this.syncIntervalMinutes = 60,
    this.minimizeToTray = true,
    this.launchAtStartup = true,
    this.notifyFreeGames = true,
    this.notifyReleases = false,
    this.notifySales = false,
    this.notifyFollowedUpdates = true,
    this.country = 'US',
    this.deviceId,
    this.pushNotificationsEnabled = false,
    this.hasSeenFreeGamesNotificationPrompt = false,
  });

  AppSettings copyWith({
    bool? autoSync,
    int? syncIntervalMinutes,
    bool? minimizeToTray,
    bool? launchAtStartup,
    bool? notifyFreeGames,
    bool? notifyReleases,
    bool? notifySales,
    bool? notifyFollowedUpdates,
    String? country,
    String? deviceId,
    bool? pushNotificationsEnabled,
    bool? hasSeenFreeGamesNotificationPrompt,
  }) {
    return AppSettings(
      autoSync: autoSync ?? this.autoSync,
      syncIntervalMinutes: syncIntervalMinutes ?? this.syncIntervalMinutes,
      minimizeToTray: minimizeToTray ?? this.minimizeToTray,
      launchAtStartup: launchAtStartup ?? this.launchAtStartup,
      notifyFreeGames: notifyFreeGames ?? this.notifyFreeGames,
      notifyReleases: notifyReleases ?? this.notifyReleases,
      notifySales: notifySales ?? this.notifySales,
      notifyFollowedUpdates: notifyFollowedUpdates ?? this.notifyFollowedUpdates,
      country: country ?? this.country,
      deviceId: deviceId ?? this.deviceId,
      pushNotificationsEnabled: pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      hasSeenFreeGamesNotificationPrompt: hasSeenFreeGamesNotificationPrompt ?? this.hasSeenFreeGamesNotificationPrompt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'autoSync': autoSync,
      'syncIntervalMinutes': syncIntervalMinutes,
      'minimizeToTray': minimizeToTray,
      'launchAtStartup': launchAtStartup,
      'notifyFreeGames': notifyFreeGames,
      'notifyReleases': notifyReleases,
      'notifySales': notifySales,
      'notifyFollowedUpdates': notifyFollowedUpdates,
      'country': country,
      'deviceId': deviceId,
      'pushNotificationsEnabled': pushNotificationsEnabled,
      'hasSeenFreeGamesNotificationPrompt': hasSeenFreeGamesNotificationPrompt,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      autoSync: json['autoSync'] ?? false,
      syncIntervalMinutes: json['syncIntervalMinutes'] ?? 60,
      minimizeToTray: json['minimizeToTray'] ?? true,
      launchAtStartup: json['launchAtStartup'] ?? true,
      notifyFreeGames: json['notifyFreeGames'] ?? true,
      notifyReleases: json['notifyReleases'] ?? false,
      notifySales: json['notifySales'] ?? false,
      notifyFollowedUpdates: json['notifyFollowedUpdates'] ?? true,
      country: json['country'] ?? 'US',
      deviceId: json['deviceId'] as String?,
      pushNotificationsEnabled: json['pushNotificationsEnabled'] ?? false,
      hasSeenFreeGamesNotificationPrompt: json['hasSeenFreeGamesNotificationPrompt'] ?? false,
    );
  }
}
