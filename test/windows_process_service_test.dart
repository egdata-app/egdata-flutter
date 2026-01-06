import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:egdata_flutter/services/windows_process_service.dart';

void main() {
  group('WindowsProcessService', () {
    group('hasProcessInDirectory', () {
      test('returns false on non-Windows platforms', () {
        if (!Platform.isWindows) {
          final result = WindowsProcessService.hasProcessInDirectory(
            'C:\\Some\\Path',
          );
          expect(result, isFalse);
        }
      }, skip: Platform.isWindows ? 'Only runs on non-Windows' : null);

      test('returns true when process exists in directory (Windows)', () {
        if (Platform.isWindows) {
          // The Dart VM itself is running, so we can test against its path
          final dartExe = Platform.resolvedExecutable;
          final dartDir = File(dartExe).parent.path;

          final result = WindowsProcessService.hasProcessInDirectory(dartDir);
          expect(result, isTrue);
        }
      }, skip: !Platform.isWindows ? 'Only runs on Windows' : null);

      test('returns false for non-existent directory (Windows)', () {
        if (Platform.isWindows) {
          final result = WindowsProcessService.hasProcessInDirectory(
            'C:\\NonExistent\\Path\\That\\Does\\Not\\Exist\\12345',
          );
          expect(result, isFalse);
        }
      }, skip: !Platform.isWindows ? 'Only runs on Windows' : null);

      test('handles path with forward slashes (Windows)', () {
        if (Platform.isWindows) {
          final dartExe = Platform.resolvedExecutable;
          final dartDir = File(dartExe).parent.path.replaceAll('\\', '/');

          final result = WindowsProcessService.hasProcessInDirectory(dartDir);
          expect(result, isTrue);
        }
      }, skip: !Platform.isWindows ? 'Only runs on Windows' : null);

      test('is case-insensitive (Windows)', () {
        if (Platform.isWindows) {
          final dartExe = Platform.resolvedExecutable;
          final dartDir = File(dartExe).parent.path.toUpperCase();

          final result = WindowsProcessService.hasProcessInDirectory(dartDir);
          expect(result, isTrue);
        }
      }, skip: !Platform.isWindows ? 'Only runs on Windows' : null);
    });

    group('isProcessRunning', () {
      test('returns false on non-Windows platforms', () {
        if (!Platform.isWindows) {
          final result = WindowsProcessService.isProcessRunning('dart.exe');
          expect(result, isFalse);
        }
      }, skip: Platform.isWindows ? 'Only runs on non-Windows' : null);

      test('returns true for running process (Windows)', () {
        if (Platform.isWindows) {
          // dart.exe should be running since we're executing Dart code
          final result = WindowsProcessService.isProcessRunning('dart.exe');
          expect(result, isTrue);
        }
      }, skip: !Platform.isWindows ? 'Only runs on Windows' : null);

      test('returns false for non-existent process (Windows)', () {
        if (Platform.isWindows) {
          final result = WindowsProcessService.isProcessRunning(
            'nonexistent_process_12345.exe',
          );
          expect(result, isFalse);
        }
      }, skip: !Platform.isWindows ? 'Only runs on Windows' : null);

      test('is case-insensitive for process name (Windows)', () {
        if (Platform.isWindows) {
          final result = WindowsProcessService.isProcessRunning('DART.EXE');
          expect(result, isTrue);
        }
      }, skip: !Platform.isWindows ? 'Only runs on Windows' : null);
    });

    group('getAllProcessPaths', () {
      test('returns empty list on non-Windows platforms', () {
        if (!Platform.isWindows) {
          final result = WindowsProcessService.getAllProcessPaths();
          expect(result, isEmpty);
        }
      }, skip: Platform.isWindows ? 'Only runs on non-Windows' : null);

      test('returns non-empty list on Windows', () {
        if (Platform.isWindows) {
          final result = WindowsProcessService.getAllProcessPaths();
          expect(result, isNotEmpty);
          // Should contain at least the Dart VM
          expect(
            result.any((path) => path.toLowerCase().contains('dart')),
            isTrue,
          );
        }
      }, skip: !Platform.isWindows ? 'Only runs on Windows' : null);

      test('all paths are valid file paths (Windows)', () {
        if (Platform.isWindows) {
          final result = WindowsProcessService.getAllProcessPaths();
          for (final path in result) {
            // Each path should contain a backslash (valid Windows path)
            expect(path, contains('\\'));
          }
        }
      }, skip: !Platform.isWindows ? 'Only runs on Windows' : null);
    });

    group('performance', () {
      test('hasProcessInDirectory completes quickly (Windows)', () async {
        if (Platform.isWindows) {
          final stopwatch = Stopwatch()..start();

          // Run multiple times to get a better average
          for (var i = 0; i < 10; i++) {
            WindowsProcessService.hasProcessInDirectory(
              'C:\\Program Files\\Epic Games\\Fortnite',
            );
          }

          stopwatch.stop();
          final avgMs = stopwatch.elapsedMilliseconds / 10;

          // Should complete in under 100ms on average (much faster than wmic)
          expect(avgMs, lessThan(100));
          print('Average hasProcessInDirectory time: ${avgMs}ms');
        }
      }, skip: !Platform.isWindows ? 'Only runs on Windows' : null);

      test('isProcessRunning completes quickly (Windows)', () async {
        if (Platform.isWindows) {
          final stopwatch = Stopwatch()..start();

          for (var i = 0; i < 10; i++) {
            WindowsProcessService.isProcessRunning('dart.exe');
          }

          stopwatch.stop();
          final avgMs = stopwatch.elapsedMilliseconds / 10;

          // Should complete in under 100ms on average
          expect(avgMs, lessThan(100));
          print('Average isProcessRunning time: ${avgMs}ms');
        }
      }, skip: !Platform.isWindows ? 'Only runs on Windows' : null);
    });
  });
}
