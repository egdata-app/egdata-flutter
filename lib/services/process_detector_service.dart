import 'dart:async';
import 'dart:io';

import '../models/move_status.dart';

class ProcessDetectorService {
  static const String _windowsProcessName = 'EpicGamesLauncher.exe';
  static const String _macProcessName = 'EpicGamesLauncher';

  /// Checks if Epic Games Launcher is currently running
  Future<bool> isLauncherRunning() async {
    try {
      if (Platform.isWindows) {
        return _isWindowsProcessRunning(_windowsProcessName);
      } else if (Platform.isMacOS) {
        return _isMacProcessRunning(_macProcessName);
      }
      return false;
    } catch (e) {
      // If we can't detect, assume not running
      return false;
    }
  }

  Future<bool> _isWindowsProcessRunning(String processName) async {
    final result = await Process.run('tasklist', [
      '/FI',
      'IMAGENAME eq $processName',
      '/FO',
      'CSV',
      '/NH',
    ]);
    return result.stdout.toString().contains(processName);
  }

  Future<bool> _isMacProcessRunning(String processName) async {
    final result = await Process.run('pgrep', ['-x', processName]);
    return result.exitCode == 0;
  }

  /// Returns a stream that monitors the launcher state
  /// Emits LauncherState.restarted when the launcher has been stopped and started again
  Stream<LauncherState> monitorLauncherState({
    Duration pollInterval = const Duration(seconds: 2),
  }) async* {
    bool? wasRunning;
    bool hasStoppedOnce = false;

    while (true) {
      await Future.delayed(pollInterval);

      final isRunning = await isLauncherRunning();

      if (wasRunning == true && !isRunning) {
        // Launcher just stopped
        hasStoppedOnce = true;
        yield LauncherState.stopped;
      } else if (hasStoppedOnce && isRunning) {
        // Launcher restarted after being stopped
        yield LauncherState.restarted;
        break; // Mission accomplished
      } else if (isRunning) {
        yield LauncherState.running;
      } else {
        yield LauncherState.stopped;
      }

      wasRunning = isRunning;
    }
  }
}
