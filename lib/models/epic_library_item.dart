class EpicLibraryItem {
  final String appName;
  final String catalogItemId;
  final String namespace;
  final String assetId;
  final String? buildVersion;

  EpicLibraryItem({
    required this.appName,
    required this.catalogItemId,
    required this.namespace,
    required this.assetId,
    this.buildVersion,
  });

  factory EpicLibraryItem.fromJson(Map<String, dynamic> json) {
    return EpicLibraryItem(
      appName: json['appName'] as String,
      catalogItemId: json['catalogItemId'] as String,
      namespace: json['namespace'] as String,
      assetId: json['assetId'] as String? ?? json['appName'] as String,
      buildVersion: json['buildVersion'] as String?,
    );
  }
}
