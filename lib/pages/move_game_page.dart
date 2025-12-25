import 'dart:async';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../main.dart';
import '../models/game_info.dart';
import '../models/move_status.dart';
import '../services/game_mover_service.dart';
import '../services/process_detector_service.dart';
import '../widgets/delete_confirmation_dialog.dart';

class MoveGamePage extends StatefulWidget {
  final GameInfo game;

  const MoveGamePage({super.key, required this.game});

  @override
  State<MoveGamePage> createState() => _MoveGamePageState();
}

class _MoveGamePageState extends State<MoveGamePage> {
  final GameMoverService _moverService = GameMoverService();
  final ProcessDetectorService _processDetector = ProcessDetectorService();

  MoveProgress _progress = const MoveProgress();

  // Responsive text size helpers
  double _scaleText(double baseSize) {
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 1000).clamp(0.9, 1.4);
    return baseSize * scale;
  }

  double get _titleSize => _scaleText(10);
  double get _headingSize => _scaleText(12);
  double get _bodySize => _scaleText(16);
  double get _secondarySize => _scaleText(15);
  double get _smallSize => _scaleText(14);
  double get _labelSize => _scaleText(10);
  double get _tinySize => _scaleText(12);
  StreamSubscription<MoveProgress>? _progressSubscription;
  StreamSubscription<LauncherState>? _launcherSubscription;

  String? _selectedDestination;
  String? _validationError;
  String? _oldPath;
  bool _isValidating = false;
  bool _launcherRestarted = false;
  int? _availableSpace;
  bool _isSameDrive = false;

  @override
  void initState() {
    super.initState();
    _progressSubscription = _moverService.progressStream.listen(
      _onProgressUpdate,
    );
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    _launcherSubscription?.cancel();
    _moverService.dispose();
    super.dispose();
  }

  void _onProgressUpdate(MoveProgress progress) {
    setState(() {
      _progress = progress;
      if (progress.phase == MovePhase.waitingForRestart &&
          _launcherSubscription == null) {
        _startLauncherMonitoring();
      }
    });
  }

  Future<void> _selectDestination() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select destination folder for ${widget.game.displayName}',
      lockParentWindow: true,
    );

    if (result != null) {
      setState(() {
        _selectedDestination = result;
        _validationError = null;
        _availableSpace = null;
      });

      // Fetch disk space info
      final space = await _moverService.getAvailableDiskSpace(result);
      final sameDrive = _moverService.isSameDrive(
        widget.game.installLocation,
        result,
      );

      if (mounted) {
        setState(() {
          _availableSpace = space;
          _isSameDrive = sameDrive;
        });
      }
    }
  }

  Future<void> _validateAndStartMove() async {
    if (_selectedDestination == null) return;

    setState(() {
      _isValidating = true;
      _validationError = null;
    });

    final error = await _moverService.validateMove(
      widget.game,
      _selectedDestination!,
    );

    if (error != null) {
      setState(() {
        _validationError = error;
        _isValidating = false;
      });
      return;
    }

    setState(() {
      _isValidating = false;
    });

    // Start the move
    final result = await _moverService.moveGame(
      widget.game,
      _selectedDestination!,
    );

    if (result.success) {
      setState(() {
        _oldPath = result.oldPath;
      });
    } else {
      setState(() {
        _progress = _progress.copyWith(
          phase: MovePhase.failed,
          errorMessage: result.errorMessage,
        );
      });
    }
  }

  void _startLauncherMonitoring() {
    _launcherSubscription = _processDetector.monitorLauncherState().listen((
      state,
    ) {
      setState(() {
        _progress = _progress.copyWith(launcherState: state);
        if (state == LauncherState.restarted) {
          _launcherRestarted = true;
        }
      });
    });
  }

  Future<void> _skipRestartCheck() async {
    _launcherSubscription?.cancel();
    setState(() {
      _launcherRestarted = true;
    });
  }

  Future<void> _showDeleteConfirmation() async {
    if (_oldPath == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeleteConfirmationDialog(
        path: _oldPath!,
        formattedSize: widget.game.formattedSize,
      ),
    );

    if (shouldDelete == true) {
      await _moverService.deleteOldInstallation(_oldPath!);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } else {
      // User chose to keep files, mark as completed anyway
      setState(() {
        _progress = _progress.copyWith(phase: MovePhase.completed);
      });
    }
  }

  void _finish() {
    Navigator.pop(context, true);
  }

  void _cancel() {
    if (_progress.phase == MovePhase.copying) {
      _moverService.cancelMove();
    }
    Navigator.pop(context, false);
  }

  String? get _keyArtUrl {
    final metadata = widget.game.metadata;
    if (metadata == null) return null;
    // Prefer horizontal box art for background, fallback to first available
    return metadata.dieselGameBox ?? metadata.firstImageUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background keyart
          if (_keyArtUrl != null)
            Positioned.fill(
              child: Image.network(
                _keyArtUrl!,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          // Gradient overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background.withValues(alpha: 0.85),
                    AppColors.background.withValues(alpha: 0.92),
                    AppColors.background,
                  ],
                  stops: const [0.0, 0.35, 0.7],
                ),
              ),
            ),
          ),
          // Content
          Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildContent()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.7),
            border: const Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: _progress.phase == MovePhase.copying ? null : _cancel,
                icon: const Icon(Icons.arrow_back_rounded),
                color: AppColors.textSecondary,
                tooltip: 'Cancel',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MOVE GAME',
                      style: TextStyle(
                        fontSize: _labelSize,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.game.displayName,
                      style: TextStyle(
                        fontSize: _headingSize,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_progress.phase) {
      case MovePhase.idle:
      case MovePhase.selectingFolder:
      case MovePhase.validating:
        return _buildFolderSelectionView();
      case MovePhase.copying:
      case MovePhase.updatingManifest:
        return _buildCopyingView();
      case MovePhase.waitingForRestart:
        return _launcherRestarted
            ? _buildReadyToDeleteView()
            : _buildWaitingForRestartView();
      case MovePhase.deletingOld:
        return _buildDeletingView();
      case MovePhase.completed:
        return _buildCompletedView();
      case MovePhase.failed:
        return _buildErrorView();
      case MovePhase.cancelled:
        return _buildCancelledView();
    }
  }

  Widget _buildFolderSelectionView() {
    final gameFolderName = p.basename(widget.game.installLocation);
    final previewPath = _selectedDestination != null
        ? p.join(_selectedDestination!, gameFolderName)
        : null;

    final screenSize = MediaQuery.of(context).size;
    final maxWidth = (screenSize.width * 0.75).clamp(400.0, 800.0);

    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current location
            _buildLocationCard(
              title: 'CURRENT LOCATION',
              path: widget.game.installLocation,
              icon: Icons.folder_rounded,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 24),
            // Arrow
            const Center(
              child: Icon(
                Icons.arrow_downward_rounded,
                size: 32,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            // Destination selection
            _buildLocationCard(
              title: 'NEW LOCATION',
              path: previewPath,
              icon: Icons.folder_open_rounded,
              color: AppColors.primary,
              isEmpty: _selectedDestination == null,
              onTap: _selectDestination,
            ),
            if (_validationError != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_rounded,
                      size: 18,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _validationError!,
                        style: TextStyle(
                          fontSize: _smallSize,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            // Info
            _buildSpaceInfoBanner(),
            const SizedBox(height: 32),
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _cancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _selectedDestination != null && !_isValidating
                      ? _validateAndStartMove
                      : null,
                  child: _isValidating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Start Move'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard({
    required String title,
    required String? path,
    required IconData icon,
    required Color color,
    bool isEmpty = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: onTap != null
                ? color.withValues(alpha: 0.5)
                : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: _headingSize * 1.1, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: _labelSize,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: color,
                  ),
                ),
                if (onTap != null) ...[
                  const Spacer(),
                  Text(
                    isEmpty ? 'SELECT FOLDER' : 'CHANGE',
                    style: TextStyle(
                      fontSize: _labelSize,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: _headingSize,
                    color: color,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              path ?? 'No folder selected',
              style: TextStyle(
                fontSize: _smallSize,
                fontFamily: 'JetBrainsMono',
                color: isEmpty ? AppColors.textMuted : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpaceInfoBanner() {
    final gameSize = widget.game.installSize;
    final gameSizeFormatted = widget.game.formattedSize;

    // No destination selected yet
    if (_selectedDestination == null) {
      return _buildInfoContainer(
        icon: Icons.info_outline_rounded,
        iconColor: AppColors.textMuted,
        text: 'Game size: $gameSizeFormatted. Select a destination to check available space.',
      );
    }

    // Fetching disk space
    if (_availableSpace == null) {
      return _buildInfoContainer(
        icon: Icons.hourglass_empty_rounded,
        iconColor: AppColors.textMuted,
        text: 'Checking available disk space...',
      );
    }

    final availableFormatted = GameMoverService.formatBytes(_availableSpace!);
    final hasEnoughSpace = _availableSpace! > gameSize;

    if (_isSameDrive) {
      // Same drive - space will be the same after move (copy then delete)
      final spaceAfterMove = _availableSpace!;
      final spaceAfterFormatted = GameMoverService.formatBytes(spaceAfterMove);

      return _buildInfoContainer(
        icon: hasEnoughSpace
            ? Icons.check_circle_outline_rounded
            : Icons.warning_rounded,
        iconColor: hasEnoughSpace ? AppColors.success : AppColors.warning,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Same drive detected',
              style: TextStyle(
                fontSize: _smallSize,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Available: $availableFormatted | Game size: $gameSizeFormatted',
              style: TextStyle(
                fontSize: _tinySize,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              'Space after move: $spaceAfterFormatted (files will be moved, not duplicated)',
              style: TextStyle(
                fontSize: _tinySize,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    } else {
      // Different drive - need full space for copy
      final spaceAfterCopy = _availableSpace! - gameSize;
      final spaceAfterFormatted = spaceAfterCopy > 0
          ? GameMoverService.formatBytes(spaceAfterCopy)
          : '0 B';

      if (!hasEnoughSpace) {
        return _buildInfoContainer(
          icon: Icons.error_outline_rounded,
          iconColor: AppColors.error,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Not enough space',
                style: TextStyle(
                  fontSize: _smallSize,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Available: $availableFormatted | Required: $gameSizeFormatted',
                style: TextStyle(
                  fontSize: _tinySize,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }

      return _buildInfoContainer(
        icon: Icons.check_circle_outline_rounded,
        iconColor: AppColors.success,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sufficient space available',
              style: TextStyle(
                fontSize: _smallSize,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Available: $availableFormatted | Game size: $gameSizeFormatted',
              style: TextStyle(
                fontSize: _tinySize,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              'Space after copy: $spaceAfterFormatted',
              style: TextStyle(
                fontSize: _tinySize,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildInfoContainer({
    required IconData icon,
    required Color iconColor,
    String? text,
    Widget? child,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: child ??
                Text(
                  text ?? '',
                  style: TextStyle(
                    fontSize: _smallSize,
                    color: AppColors.textSecondary,
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyingView() {
    final screenSize = MediaQuery.of(context).size;
    final maxWidth = (screenSize.width * 0.7).clamp(350.0, 700.0);
    final progressSize = (screenSize.width * 0.15).clamp(100.0, 160.0);

    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress indicator
            SizedBox(
              width: progressSize,
              height: progressSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: progressSize,
                    height: progressSize,
                    child: CircularProgressIndicator(
                      value: _progress.progressPercent,
                      strokeWidth: 8,
                      backgroundColor: AppColors.surfaceLight,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    _progress.formattedProgress,
                    style: TextStyle(
                      fontSize: _scaleText(24),
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Status text
            Text(
              _progress.phase == MovePhase.updatingManifest
                  ? 'Updating manifest...'
                  : 'Copying files...',
              style: TextStyle(
                fontSize: _headingSize,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            // Bytes progress
            Text(
              _progress.formattedBytesProgress,
              style: TextStyle(
                fontSize: _secondarySize,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            // File count
            Text(
              '${_progress.copiedFiles} / ${_progress.totalFiles} files',
              style: TextStyle(
                fontSize: _smallSize,
                color: AppColors.textMuted,
              ),
            ),
            if (_progress.currentFile.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _progress.currentFile,
                  style: TextStyle(
                    fontSize: _tinySize,
                    fontFamily: 'JetBrainsMono',
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: 32),
            // Cancel button
            OutlinedButton(
              onPressed: _cancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingForRestartView() {
    IconData statusIcon;
    Color statusColor;
    String statusText;

    switch (_progress.launcherState) {
      case LauncherState.running:
        statusIcon = Icons.sync_rounded;
        statusColor = AppColors.warning;
        statusText = 'Epic Games Launcher is running - please close it';
      case LauncherState.stopped:
        statusIcon = Icons.pause_circle_outline_rounded;
        statusColor = AppColors.textSecondary;
        statusText = 'Launcher closed - please reopen it';
      case LauncherState.restarted:
        statusIcon = Icons.check_circle_rounded;
        statusColor = AppColors.success;
        statusText = 'Launcher restarted successfully!';
      case LauncherState.unknown:
        statusIcon = Icons.help_outline_rounded;
        statusColor = AppColors.textMuted;
        statusText = 'Checking launcher status...';
    }

    final screenSize = MediaQuery.of(context).size;
    final maxWidth = (screenSize.width * 0.7).clamp(350.0, 700.0);
    final iconSize = (screenSize.width * 0.08).clamp(48.0, 80.0);

    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(statusIcon, size: iconSize, color: statusColor),
            const SizedBox(height: 24),
            Text(
              'Restart Epic Games Launcher',
              style: TextStyle(
                fontSize: _titleSize,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'The manifest has been updated. Please close and reopen the Epic Games Launcher for the changes to take effect.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _bodySize,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: _smallSize,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: _skipRestartCheck,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: const Text('Skip'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadyToDeleteView() {
    final screenSize = MediaQuery.of(context).size;
    final maxWidth = (screenSize.width * 0.7).clamp(350.0, 700.0);
    final iconSize = (screenSize.width * 0.06).clamp(40.0, 64.0);

    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: iconSize,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Move Complete!',
              style: TextStyle(
                fontSize: _titleSize,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'The game has been moved to the new location. Would you like to delete the old files to free up space?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _bodySize,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: _finish,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: const Text('Keep Old Files'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _showDeleteConfirmation,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                  ),
                  child: const Text('Delete Old Files'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeletingView() {
    final screenSize = MediaQuery.of(context).size;
    final spinnerSize = (screenSize.width * 0.06).clamp(40.0, 64.0);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: spinnerSize,
            height: spinnerSize,
            child: const CircularProgressIndicator(
              strokeWidth: 4,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Deleting old files...',
            style: TextStyle(
              fontSize: _headingSize,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait, this may take a while.',
            style: TextStyle(
              fontSize: _secondarySize,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedView() {
    final screenSize = MediaQuery.of(context).size;
    final maxWidth = (screenSize.width * 0.65).clamp(320.0, 600.0);
    final iconSize = (screenSize.width * 0.06).clamp(40.0, 64.0);

    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: iconSize,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Move Complete!',
              style: TextStyle(
                fontSize: _titleSize,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'The game has been successfully moved.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _bodySize,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(onPressed: _finish, child: const Text('Done')),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    final screenSize = MediaQuery.of(context).size;
    final maxWidth = (screenSize.width * 0.7).clamp(350.0, 700.0);
    final iconSize = (screenSize.width * 0.06).clamp(40.0, 64.0);

    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_rounded,
                size: iconSize,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Move Failed',
              style: TextStyle(
                fontSize: _titleSize,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (_progress.errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _progress.errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: _smallSize,
                    fontFamily: 'JetBrainsMono',
                    color: AppColors.error,
                  ),
                ),
              ),
            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: _cancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border),
              ),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelledView() {
    final screenSize = MediaQuery.of(context).size;
    final maxWidth = (screenSize.width * 0.65).clamp(320.0, 600.0);
    final iconSize = (screenSize.width * 0.06).clamp(40.0, 64.0);

    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cancel_rounded,
              size: iconSize,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 24),
            Text(
              'Move Cancelled',
              style: TextStyle(
                fontSize: _titleSize,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'The move operation was cancelled.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _bodySize,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: _cancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border),
              ),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
