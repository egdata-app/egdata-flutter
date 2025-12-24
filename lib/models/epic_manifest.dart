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
    };
  }
}
