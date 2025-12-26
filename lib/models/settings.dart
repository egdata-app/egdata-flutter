class AppSettings {
  final bool autoSync;
  final int syncIntervalMinutes;
  final bool minimizeToTray;
  final bool launchAtStartup;
  final bool notifyFreeGames;
  final bool notifyReleases;
  final bool notifySales;
  final bool notifyFollowedUpdates;

  AppSettings({
    this.autoSync = false,
    this.syncIntervalMinutes = 60,
    this.minimizeToTray = true,
    this.launchAtStartup = true,
    this.notifyFreeGames = true,
    this.notifyReleases = false,
    this.notifySales = false,
    this.notifyFollowedUpdates = true,
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
    );
  }
}
