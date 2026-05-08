const Object _unset = Object();

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
  final String libraryViewMode;
  final String libraryFilter;
  final String libraryOfferTypeFilter;
  final String? librarySelectedTag;
  final String? librarySelectedCategoryName;
  final bool libraryOnlyOnSale;
  final bool libraryOnlyFree;
  final String librarySortBy;
  final bool librarySortAscending;

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
    this.libraryViewMode = 'grid',
    this.libraryFilter = 'all',
    this.libraryOfferTypeFilter = 'any',
    this.librarySelectedTag,
    this.librarySelectedCategoryName,
    this.libraryOnlyOnSale = false,
    this.libraryOnlyFree = false,
    this.librarySortBy = 'title',
    this.librarySortAscending = true,
  });

  // Nullable fields use a sentinel so callers can pass `null` to clear them.
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
    String? libraryViewMode,
    String? libraryFilter,
    String? libraryOfferTypeFilter,
    Object? librarySelectedTag = _unset,
    Object? librarySelectedCategoryName = _unset,
    bool? libraryOnlyOnSale,
    bool? libraryOnlyFree,
    String? librarySortBy,
    bool? librarySortAscending,
  }) {
    return AppSettings(
      autoSync: autoSync ?? this.autoSync,
      syncIntervalMinutes: syncIntervalMinutes ?? this.syncIntervalMinutes,
      minimizeToTray: minimizeToTray ?? this.minimizeToTray,
      launchAtStartup: launchAtStartup ?? this.launchAtStartup,
      notifyFreeGames: notifyFreeGames ?? this.notifyFreeGames,
      notifyReleases: notifyReleases ?? this.notifyReleases,
      notifySales: notifySales ?? this.notifySales,
      notifyFollowedUpdates:
          notifyFollowedUpdates ?? this.notifyFollowedUpdates,
      country: country ?? this.country,
      deviceId: deviceId ?? this.deviceId,
      pushNotificationsEnabled:
          pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      hasSeenFreeGamesNotificationPrompt:
          hasSeenFreeGamesNotificationPrompt ??
          this.hasSeenFreeGamesNotificationPrompt,
      libraryViewMode: libraryViewMode ?? this.libraryViewMode,
      libraryFilter: libraryFilter ?? this.libraryFilter,
      libraryOfferTypeFilter:
          libraryOfferTypeFilter ?? this.libraryOfferTypeFilter,
      librarySelectedTag: identical(librarySelectedTag, _unset)
          ? this.librarySelectedTag
          : librarySelectedTag as String?,
      librarySelectedCategoryName:
          identical(librarySelectedCategoryName, _unset)
          ? this.librarySelectedCategoryName
          : librarySelectedCategoryName as String?,
      libraryOnlyOnSale: libraryOnlyOnSale ?? this.libraryOnlyOnSale,
      libraryOnlyFree: libraryOnlyFree ?? this.libraryOnlyFree,
      librarySortBy: librarySortBy ?? this.librarySortBy,
      librarySortAscending: librarySortAscending ?? this.librarySortAscending,
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
      'libraryViewMode': libraryViewMode,
      'libraryFilter': libraryFilter,
      'libraryOfferTypeFilter': libraryOfferTypeFilter,
      'librarySelectedTag': librarySelectedTag,
      'librarySelectedCategoryName': librarySelectedCategoryName,
      'libraryOnlyOnSale': libraryOnlyOnSale,
      'libraryOnlyFree': libraryOnlyFree,
      'librarySortBy': librarySortBy,
      'librarySortAscending': librarySortAscending,
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
      hasSeenFreeGamesNotificationPrompt:
          json['hasSeenFreeGamesNotificationPrompt'] ?? false,
      libraryViewMode: json['libraryViewMode'] ?? 'grid',
      libraryFilter: json['libraryFilter'] ?? 'all',
      libraryOfferTypeFilter: json['libraryOfferTypeFilter'] ?? 'any',
      librarySelectedTag: json['librarySelectedTag'] as String?,
      librarySelectedCategoryName:
          json['librarySelectedCategoryName'] as String?,
      libraryOnlyOnSale: json['libraryOnlyOnSale'] ?? false,
      libraryOnlyFree: json['libraryOnlyFree'] ?? false,
      librarySortBy: json['librarySortBy'] ?? 'title',
      librarySortAscending: json['librarySortAscending'] ?? true,
    );
  }
}
