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
    final statusStr = (json['status'] ?? '').toString().toLowerCase();
    final message = (json['message'] ?? '').toString().toLowerCase();

    switch (statusStr) {
      case 'uploaded':
      case 'success':
      case 'created':
      case 'ok':
        statusType = UploadStatusType.uploaded;
        break;
      case 'already_uploaded':
      case 'exists':
      case 'duplicate':
        statusType = UploadStatusType.alreadyUploaded;
        break;
      case 'failed':
      case 'error':
        statusType = UploadStatusType.failed;
        break;
      default:
        // Fallback: check message content for success indicators
        if (message.contains('success') || message.contains('uploaded')) {
          statusType = UploadStatusType.uploaded;
        } else if (message.contains('already') || message.contains('exists')) {
          statusType = UploadStatusType.alreadyUploaded;
        } else {
          statusType = UploadStatusType.failed;
        }
    }

    return UploadStatus(
      status: statusType,
      message: json['message'] ?? '',
      manifestHash: json['manifest_hash'],
    );
  }
}
