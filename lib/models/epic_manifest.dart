class EpicGameManifest {
  final String displayName;
  final String installationGuid;
  final String installLocation;
  final String stagingLocation;
  final String manifestLocation;
  final String catalogNamespace;
  final String catalogItemId;
  final String appName;
  final String appVersionString;
  final String launchCommand;
  final String launchExecutable;
  final int installSize;
  final String mainGameCatalogNamespace;
  final String mainGameCatalogItemId;
  final String mainGameAppName;
  final List<String> appCategories;

  EpicGameManifest({
    required this.displayName,
    required this.installationGuid,
    required this.installLocation,
    required this.stagingLocation,
    required this.manifestLocation,
    required this.catalogNamespace,
    required this.catalogItemId,
    required this.appName,
    required this.appVersionString,
    required this.launchCommand,
    required this.launchExecutable,
    required this.installSize,
    required this.mainGameCatalogNamespace,
    required this.mainGameCatalogItemId,
    required this.mainGameAppName,
    required this.appCategories,
  });

  factory EpicGameManifest.fromJson(Map<String, dynamic> json) {
    return EpicGameManifest(
      displayName: json['DisplayName'] ?? '',
      installationGuid: json['InstallationGuid'] ?? '',
      installLocation: json['InstallLocation'] ?? '',
      stagingLocation: json['StagingLocation'] ?? '',
      manifestLocation: json['ManifestLocation'] ?? '',
      catalogNamespace: json['CatalogNamespace'] ?? '',
      catalogItemId: json['CatalogItemId'] ?? '',
      appName: json['AppName'] ?? '',
      appVersionString: json['AppVersionString'] ?? '',
      launchCommand: json['LaunchCommand'] ?? '',
      launchExecutable: json['LaunchExecutable'] ?? '',
      installSize: json['InstallSize'] ?? 0,
      mainGameCatalogNamespace: json['MainGameCatalogNamespace'] ?? '',
      mainGameCatalogItemId: json['MainGameCatalogItemId'] ?? '',
      mainGameAppName: json['MainGameAppName'] ?? '',
      appCategories: (json['AppCategories'] as List<dynamic>? ?? const [])
          .map((category) => category.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'DisplayName': displayName,
      'InstallationGuid': installationGuid,
      'InstallLocation': installLocation,
      'StagingLocation': stagingLocation,
      'ManifestLocation': manifestLocation,
      'CatalogNamespace': catalogNamespace,
      'CatalogItemId': catalogItemId,
      'AppName': appName,
      'AppVersionString': appVersionString,
      'LaunchCommand': launchCommand,
      'LaunchExecutable': launchExecutable,
      'InstallSize': installSize,
      'MainGameCatalogNamespace': mainGameCatalogNamespace,
      'MainGameCatalogItemId': mainGameCatalogItemId,
      'MainGameAppName': mainGameAppName,
      'AppCategories': appCategories,
    };
  }
}
