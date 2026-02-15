enum ManifestHealthIssueType {
  staleManifestLocation,
  duplicateInstallLocation,
  orphanAddon,
}

class ManifestHealthIssue {
  final ManifestHealthIssueType type;
  final String title;
  final String description;
  final String installationGuid;

  const ManifestHealthIssue({
    required this.type,
    required this.title,
    required this.description,
    required this.installationGuid,
  });
}

class ManifestHealthReport {
  final List<ManifestHealthIssue> issues;
  final int repairedCount;

  const ManifestHealthReport({required this.issues, this.repairedCount = 0});

  bool get hasIssues => issues.isNotEmpty;
}
