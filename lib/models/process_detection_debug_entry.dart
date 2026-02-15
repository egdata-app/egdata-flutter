class ProcessDetectionDebugEntry {
  final String gameName;
  final String installLocation;
  final bool isRunning;
  final String? matchedProcessPath;
  final String reason;

  const ProcessDetectionDebugEntry({
    required this.gameName,
    required this.installLocation,
    required this.isRunning,
    required this.reason,
    this.matchedProcessPath,
  });
}
