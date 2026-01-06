import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

/// Service for detecting running processes on Windows using native Win32 API.
/// This is more efficient and reliable than spawning wmic.exe processes.
class WindowsProcessService {
  /// Check if any process is running from the given install directory.
  /// Returns true if a process with an executable path containing [installPath] is found.
  static bool hasProcessInDirectory(String installPath) {
    if (!Platform.isWindows) return false;

    // Normalize the path for comparison (lowercase, backslashes)
    final normalizedInstallPath = installPath.toLowerCase().replaceAll('/', '\\');

    // Allocate buffer for process IDs (up to 4096 processes)
    const maxProcesses = 4096;
    final pProcessIds = calloc<DWORD>(maxProcesses);
    final pBytesReturned = calloc<DWORD>();

    try {
      // Get list of all process IDs
      final result = EnumProcesses(
        pProcessIds,
        maxProcesses * sizeOf<DWORD>(),
        pBytesReturned,
      );

      if (result == 0) {
        return false;
      }

      final processCount = pBytesReturned.value ~/ sizeOf<DWORD>();

      // Check each process
      for (var i = 0; i < processCount; i++) {
        final pid = pProcessIds[i];
        if (pid == 0) continue;

        final executablePath = _getProcessExecutablePath(pid);
        if (executablePath != null) {
          final normalizedExePath = executablePath.toLowerCase();
          if (normalizedExePath.contains(normalizedInstallPath)) {
            return true;
          }
        }
      }

      return false;
    } finally {
      calloc.free(pProcessIds);
      calloc.free(pBytesReturned);
    }
  }

  /// Get the full executable path for a process by PID.
  /// Returns null if the process cannot be accessed or path cannot be retrieved.
  static String? _getProcessExecutablePath(int pid) {
    // Open process with query limited information access
    // PROCESS_QUERY_LIMITED_INFORMATION (0x1000) works for most processes
    // even without admin rights
    final hProcess = OpenProcess(
      PROCESS_QUERY_LIMITED_INFORMATION,
      FALSE,
      pid,
    );

    if (hProcess == NULL) {
      return null;
    }

    try {
      // Allocate buffer for the path (MAX_PATH = 260, but use larger for long paths)
      const bufferSize = 1024;
      final pPath = wsalloc(bufferSize);
      final pSize = calloc<DWORD>()..value = bufferSize;

      try {
        // Get the full path of the executable
        final result = QueryFullProcessImageName(
          hProcess,
          0, // Use Win32 path format
          pPath,
          pSize,
        );

        if (result != 0 && pSize.value > 0) {
          return pPath.toDartString();
        }
        return null;
      } finally {
        calloc.free(pPath);
        calloc.free(pSize);
      }
    } finally {
      CloseHandle(hProcess);
    }
  }

  /// Get a list of all running process executable paths.
  /// Useful for debugging and testing.
  static List<String> getAllProcessPaths() {
    if (!Platform.isWindows) return [];

    final paths = <String>[];

    const maxProcesses = 4096;
    final pProcessIds = calloc<DWORD>(maxProcesses);
    final pBytesReturned = calloc<DWORD>();

    try {
      final result = EnumProcesses(
        pProcessIds,
        maxProcesses * sizeOf<DWORD>(),
        pBytesReturned,
      );

      if (result == 0) return paths;

      final processCount = pBytesReturned.value ~/ sizeOf<DWORD>();

      for (var i = 0; i < processCount; i++) {
        final pid = pProcessIds[i];
        if (pid == 0) continue;

        final path = _getProcessExecutablePath(pid);
        if (path != null) {
          paths.add(path);
        }
      }
    } finally {
      calloc.free(pProcessIds);
      calloc.free(pBytesReturned);
    }

    return paths;
  }

  /// Check if a specific process name is running.
  /// More efficient alternative to tasklist command.
  static bool isProcessRunning(String processName) {
    if (!Platform.isWindows) return false;

    final lowerProcessName = processName.toLowerCase();

    const maxProcesses = 4096;
    final pProcessIds = calloc<DWORD>(maxProcesses);
    final pBytesReturned = calloc<DWORD>();

    try {
      final result = EnumProcesses(
        pProcessIds,
        maxProcesses * sizeOf<DWORD>(),
        pBytesReturned,
      );

      if (result == 0) return false;

      final processCount = pBytesReturned.value ~/ sizeOf<DWORD>();

      for (var i = 0; i < processCount; i++) {
        final pid = pProcessIds[i];
        if (pid == 0) continue;

        final path = _getProcessExecutablePath(pid);
        if (path != null) {
          final fileName = path.split('\\').last.toLowerCase();
          if (fileName == lowerProcessName) {
            return true;
          }
        }
      }

      return false;
    } finally {
      calloc.free(pProcessIds);
      calloc.free(pBytesReturned);
    }
  }
}
