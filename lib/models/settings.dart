class AppSettings {
  final bool autoSync;
  final int syncIntervalMinutes;
  final bool minimizeToTray;
  final bool launchAtStartup;

  AppSettings({
    this.autoSync = false,
    this.syncIntervalMinutes = 60,
    this.minimizeToTray = true,
    this.launchAtStartup = false,
  });

  AppSettings copyWith({
    bool? autoSync,
    int? syncIntervalMinutes,
    bool? minimizeToTray,
    bool? launchAtStartup,
  }) {
    return AppSettings(
      autoSync: autoSync ?? this.autoSync,
      syncIntervalMinutes: syncIntervalMinutes ?? this.syncIntervalMinutes,
      minimizeToTray: minimizeToTray ?? this.minimizeToTray,
      launchAtStartup: launchAtStartup ?? this.launchAtStartup,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'autoSync': autoSync,
      'syncIntervalMinutes': syncIntervalMinutes,
      'minimizeToTray': minimizeToTray,
      'launchAtStartup': launchAtStartup,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      autoSync: json['autoSync'] ?? false,
      syncIntervalMinutes: json['syncIntervalMinutes'] ?? 60,
      minimizeToTray: json['minimizeToTray'] ?? true,
      launchAtStartup: json['launchAtStartup'] ?? false,
    );
  }
}
