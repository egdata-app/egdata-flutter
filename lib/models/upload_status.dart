enum UploadStatusType {
  uploaded,
  alreadyUploaded,
  failed,
  pending,
  uploading,
}

class UploadStatus {
  final UploadStatusType status;
  final String message;
  final String? manifestHash;

  UploadStatus({
    required this.status,
    required this.message,
    this.manifestHash,
  });

  factory UploadStatus.fromJson(Map<String, dynamic> json) {
    UploadStatusType statusType;
    final statusStr = json['status'] ?? '';

    switch (statusStr) {
      case 'uploaded':
        statusType = UploadStatusType.uploaded;
        break;
      case 'already_uploaded':
        statusType = UploadStatusType.alreadyUploaded;
        break;
      default:
        statusType = UploadStatusType.failed;
    }

    return UploadStatus(
      status: statusType,
      message: json['message'] ?? '',
      manifestHash: json['manifest_hash'],
    );
  }
}
