class OfferAsset {
  final String id;
  final String? artifactId;
  final int downloadSizeBytes;
  final int installedSizeBytes;
  final String? itemId;
  final String? namespace;
  final String platform;

  OfferAsset({
    required this.id,
    this.artifactId,
    required this.downloadSizeBytes,
    required this.installedSizeBytes,
    this.itemId,
    this.namespace,
    required this.platform,
  });

  factory OfferAsset.fromJson(Map<String, dynamic> json) {
    return OfferAsset(
      id: (json['_id'] as String?) ?? '',
      artifactId: json['artifactId'] as String?,
      downloadSizeBytes: (json['downloadSizeBytes'] as int?) ?? 0,
      installedSizeBytes: (json['installedSizeBytes'] as int?) ?? 0,
      itemId: json['itemId'] as String?,
      namespace: json['namespace'] as String?,
      platform: (json['platform'] as String?) ?? 'Unknown',
    );
  }

  /// Format download size as human-readable string
  String get formattedDownloadSize {
    return _formatBytes(downloadSizeBytes);
  }

  /// Format installed size as human-readable string
  String get formattedInstalledSize {
    return _formatBytes(installedSizeBytes);
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
