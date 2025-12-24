enum MovePhase {
  idle,
  selectingFolder,
  validating,
  copying,
  updatingManifest,
  waitingForRestart,
  deletingOld,
  completed,
  failed,
  cancelled,
}

enum LauncherState {
  unknown,
  running,
  stopped,
  restarted,
}

class MoveProgress {
  final MovePhase phase;
  final int totalFiles;
  final int copiedFiles;
  final int totalBytes;
  final int copiedBytes;
  final String currentFile;
  final String? errorMessage;
  final String? sourcePath;
  final String? destinationPath;
  final DateTime? startTime;
  final LauncherState launcherState;

  const MoveProgress({
    this.phase = MovePhase.idle,
    this.totalFiles = 0,
    this.copiedFiles = 0,
    this.totalBytes = 0,
    this.copiedBytes = 0,
    this.currentFile = '',
    this.errorMessage,
    this.sourcePath,
    this.destinationPath,
    this.startTime,
    this.launcherState = LauncherState.unknown,
  });

  double get progressPercent =>
      totalBytes > 0 ? copiedBytes / totalBytes : 0.0;

  Duration get elapsed =>
      startTime != null ? DateTime.now().difference(startTime!) : Duration.zero;

  String get formattedProgress => '${(progressPercent * 100).toStringAsFixed(1)}%';

  String get formattedBytesProgress =>
      '${_formatBytes(copiedBytes)} / ${_formatBytes(totalBytes)}';

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  MoveProgress copyWith({
    MovePhase? phase,
    int? totalFiles,
    int? copiedFiles,
    int? totalBytes,
    int? copiedBytes,
    String? currentFile,
    String? errorMessage,
    String? sourcePath,
    String? destinationPath,
    DateTime? startTime,
    LauncherState? launcherState,
  }) {
    return MoveProgress(
      phase: phase ?? this.phase,
      totalFiles: totalFiles ?? this.totalFiles,
      copiedFiles: copiedFiles ?? this.copiedFiles,
      totalBytes: totalBytes ?? this.totalBytes,
      copiedBytes: copiedBytes ?? this.copiedBytes,
      currentFile: currentFile ?? this.currentFile,
      errorMessage: errorMessage ?? this.errorMessage,
      sourcePath: sourcePath ?? this.sourcePath,
      destinationPath: destinationPath ?? this.destinationPath,
      startTime: startTime ?? this.startTime,
      launcherState: launcherState ?? this.launcherState,
    );
  }
}

class MoveResult {
  final bool success;
  final String? errorMessage;
  final String? oldPath;
  final String? newPath;

  const MoveResult({
    required this.success,
    this.errorMessage,
    this.oldPath,
    this.newPath,
  });
}
