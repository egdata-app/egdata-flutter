import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/game_info.dart';
import '../models/move_status.dart';

class GameMoverService {
  final StreamController<MoveProgress> _progressController =
      StreamController<MoveProgress>.broadcast();

  Stream<MoveProgress> get progressStream => _progressController.stream;

  MoveProgress _currentProgress = const MoveProgress();
  bool _isCancelled = false;

  void _updateProgress(MoveProgress progress) {
    _currentProgress = progress;
    _progressController.add(progress);
  }

  /// Validates move operation before starting
  /// Returns null if valid, error message if invalid
  Future<String?> validateMove(GameInfo game, String destinationPath) async {
    // Check if source exists
    final sourceDir = Directory(game.installLocation);
    if (!await sourceDir.exists()) {
      return 'Source directory does not exist: ${game.installLocation}';
    }

    // Check destination directory exists
    final destDir = Directory(destinationPath);
    if (!await destDir.exists()) {
      return 'Destination directory does not exist: $destinationPath';
    }

    // Get the game folder name from source
    final gameFolderName = p.basename(game.installLocation);
    final newGamePath = p.join(destinationPath, gameFolderName);

    // Check if destination is same as source
    if (p.equals(game.installLocation, newGamePath)) {
      return 'Destination is the same as current location';
    }

    // Check if game folder already exists at destination
    final newGameDir = Directory(newGamePath);
    if (await newGameDir.exists()) {
      return 'A folder named "$gameFolderName" already exists at destination';
    }

    // Check available disk space
    final availableSpace = await _getAvailableDiskSpace(destinationPath);
    final requiredSpace = (game.installSize * 1.1).round(); // 10% buffer

    if (availableSpace != null && availableSpace < requiredSpace) {
      final availableGB = (availableSpace / (1024 * 1024 * 1024)).toStringAsFixed(2);
      final requiredGB = (requiredSpace / (1024 * 1024 * 1024)).toStringAsFixed(2);
      return 'Not enough disk space. Need $requiredGB GB, only $availableGB GB available';
    }

    // Check if destination is writable
    try {
      final testFile = File(p.join(destinationPath, '.egdata_write_test'));
      await testFile.writeAsString('test');
      await testFile.delete();
    } catch (e) {
      return 'Cannot write to destination folder. Check permissions.';
    }

    return null; // Valid
  }

  Future<int?> _getAvailableDiskSpace(String path) async {
    try {
      if (Platform.isWindows) {
        // Get drive letter from path
        final driveLetter = path.substring(0, 2);
        final result = await Process.run('wmic', [
          'logicaldisk',
          'where',
          'DeviceID="$driveLetter"',
          'get',
          'FreeSpace',
          '/value',
        ]);
        final output = result.stdout.toString();
        final match = RegExp(r'FreeSpace=(\d+)').firstMatch(output);
        if (match != null) {
          return int.tryParse(match.group(1)!);
        }
      } else if (Platform.isMacOS) {
        final result = await Process.run('df', ['-k', path]);
        final lines = result.stdout.toString().split('\n');
        if (lines.length > 1) {
          final parts = lines[1].split(RegExp(r'\s+'));
          if (parts.length > 3) {
            final availableKB = int.tryParse(parts[3]);
            if (availableKB != null) {
              return availableKB * 1024;
            }
          }
        }
      }
    } catch (e) {
      // Ignore errors, return null to skip space check
    }
    return null;
  }

  /// Main move operation - copies files and updates manifest
  Future<MoveResult> moveGame(GameInfo game, String destinationPath) async {
    _isCancelled = false;

    final gameFolderName = p.basename(game.installLocation);
    final newGamePath = p.join(destinationPath, gameFolderName);

    _updateProgress(MoveProgress(
      phase: MovePhase.copying,
      sourcePath: game.installLocation,
      destinationPath: newGamePath,
      startTime: DateTime.now(),
    ));

    try {
      // Count total files and bytes
      final sourceDir = Directory(game.installLocation);
      int totalFiles = 0;
      int totalBytes = 0;

      await for (final entity in sourceDir.list(recursive: true)) {
        if (entity is File) {
          totalFiles++;
          totalBytes += await entity.length();
        }
      }

      _updateProgress(_currentProgress.copyWith(
        totalFiles: totalFiles,
        totalBytes: totalBytes,
      ));

      // Create destination directory
      await Directory(newGamePath).create(recursive: true);

      // Copy files
      int copiedFiles = 0;
      int copiedBytes = 0;

      await for (final entity in sourceDir.list(recursive: true)) {
        if (_isCancelled) {
          // Cleanup partial copy
          await _deleteDirectory(newGamePath);
          return const MoveResult(
            success: false,
            errorMessage: 'Move cancelled by user',
          );
        }

        final relativePath = p.relative(entity.path, from: game.installLocation);
        final newPath = p.join(newGamePath, relativePath);

        if (entity is Directory) {
          await Directory(newPath).create(recursive: true);
        } else if (entity is File) {
          _updateProgress(_currentProgress.copyWith(
            currentFile: relativePath,
          ));

          // Ensure parent directory exists
          await Directory(p.dirname(newPath)).create(recursive: true);

          // Copy file
          await entity.copy(newPath);

          final fileSize = await entity.length();
          copiedFiles++;
          copiedBytes += fileSize;

          _updateProgress(_currentProgress.copyWith(
            copiedFiles: copiedFiles,
            copiedBytes: copiedBytes,
          ));
        }
      }

      // Update manifest
      _updateProgress(_currentProgress.copyWith(
        phase: MovePhase.updatingManifest,
        currentFile: '',
      ));

      final manifestUpdateResult = await _updateManifest(
        game.itemFilePath!,
        newGamePath,
      );

      if (!manifestUpdateResult) {
        return MoveResult(
          success: false,
          errorMessage: 'Failed to update manifest file',
          oldPath: game.installLocation,
          newPath: newGamePath,
        );
      }

      _updateProgress(_currentProgress.copyWith(
        phase: MovePhase.waitingForRestart,
      ));

      return MoveResult(
        success: true,
        oldPath: game.installLocation,
        newPath: newGamePath,
      );
    } catch (e) {
      _updateProgress(_currentProgress.copyWith(
        phase: MovePhase.failed,
        errorMessage: e.toString(),
      ));

      return MoveResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Updates the Epic Games manifest .item file with new paths
  Future<bool> _updateManifest(String itemFilePath, String newInstallLocation) async {
    try {
      final itemFile = File(itemFilePath);
      final content = await itemFile.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      // Get the old install location before updating
      final oldInstallLocation = json['InstallLocation'] as String;

      // Update InstallLocation
      json['InstallLocation'] = newInstallLocation;

      // Update ManifestLocation if it exists - replace old path prefix with new one
      final oldManifestLocation = json['ManifestLocation'] as String?;
      if (oldManifestLocation != null && oldManifestLocation.isNotEmpty) {
        if (oldManifestLocation.startsWith(oldInstallLocation)) {
          // Replace the old install path with the new one
          final relativePath = oldManifestLocation.substring(oldInstallLocation.length);
          json['ManifestLocation'] = newInstallLocation + relativePath;
        }
      }

      // Update StagingLocation if it exists and points to old location
      final oldStagingLocation = json['StagingLocation'] as String?;
      if (oldStagingLocation != null && oldStagingLocation.isNotEmpty) {
        if (oldStagingLocation.startsWith(oldInstallLocation)) {
          // Replace the old install path with the new one
          final relativePath = oldStagingLocation.substring(oldInstallLocation.length);
          json['StagingLocation'] = newInstallLocation + relativePath;
        }
      }

      // Write back with pretty printing (atomic write)
      final encoder = const JsonEncoder.withIndent('\t');
      final newContent = encoder.convert(json);

      final tempFile = File('$itemFilePath.tmp');
      await tempFile.writeAsString(newContent);

      // Rename temp file to original (atomic on most systems)
      await tempFile.rename(itemFilePath);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Deletes the old game installation
  Future<bool> deleteOldInstallation(String path) async {
    _updateProgress(_currentProgress.copyWith(
      phase: MovePhase.deletingOld,
    ));

    try {
      await _deleteDirectory(path);

      _updateProgress(_currentProgress.copyWith(
        phase: MovePhase.completed,
      ));

      return true;
    } catch (e) {
      _updateProgress(_currentProgress.copyWith(
        phase: MovePhase.failed,
        errorMessage: 'Failed to delete old files: $e',
      ));
      return false;
    }
  }

  Future<void> _deleteDirectory(String path) async {
    final dir = Directory(path);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  /// Cancels ongoing move operation
  void cancelMove() {
    _isCancelled = true;
    _updateProgress(_currentProgress.copyWith(
      phase: MovePhase.cancelled,
    ));
  }

  void dispose() {
    _progressController.close();
  }
}
