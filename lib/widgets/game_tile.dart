import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../models/game_info.dart';
import '../models/upload_status.dart';

class GameTile extends StatefulWidget {
  final GameInfo game;
  final UploadStatus? uploadStatus;
  final VoidCallback? onUpload;
  final VoidCallback? onMove;
  final bool isUploading;

  const GameTile({
    super.key,
    required this.game,
    this.uploadStatus,
    this.onUpload,
    this.onMove,
    this.isUploading = false,
  });

  @override
  State<GameTile> createState() => _GameTileState();
}

class _GameTileState extends State<GameTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _isHovered ? AppColors.surfaceLight : AppColors.surface,
          border: Border.all(
            color: _isHovered ? AppColors.borderLight : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Game image
              _buildGameImage(),
              const SizedBox(width: 16),
              // Game info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.game.displayName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.uploadStatus != null) ...[
                          const SizedBox(width: 12),
                          _buildStatusBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Details row
                    Row(
                      children: [
                        _buildDetailChip(
                          icon: Icons.tag_rounded,
                          label: widget.game.appName,
                          isMono: true,
                        ),
                        const SizedBox(width: 12),
                        _buildDetailChip(
                          icon: Icons.storage_rounded,
                          label: widget.game.formattedSize,
                        ),
                        const SizedBox(width: 12),
                        _buildDetailChip(
                          icon: Icons.update_rounded,
                          label: widget.game.version,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Path row
                    Row(
                      children: [
                        Expanded(
                          child: _buildPathChip(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMoveButton(),
                  const SizedBox(width: 8),
                  _buildUploadButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameImage() {
    // Prefer tall box art for tile thumbnails, fallback to any available
    final metadata = widget.game.metadata;
    final imageUrl = metadata?.dieselGameBoxTall ?? metadata?.firstImageUrl;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: imageUrl != null
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _buildPlaceholder(),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildPlaceholder();
                },
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surfaceLight,
      child: const Center(
        child: Icon(
          Icons.games_rounded,
          size: 28,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    bool isMono = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontFamily: isMono ? 'Consolas' : null,
            color: AppColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPathChip() {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: widget.game.installLocation));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Path copied to clipboard'),
            backgroundColor: AppColors.surface,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.folder_rounded,
              size: 12,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                widget.game.installLocation,
                style: const TextStyle(
                  fontSize: 10,
                  fontFamily: 'JetBrainsMono',
                  color: AppColors.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.copy_rounded,
              size: 10,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (widget.uploadStatus!.status) {
      case UploadStatusType.uploaded:
        bgColor = AppColors.success.withValues(alpha: 0.15);
        textColor = AppColors.success;
        label = 'UPLOADED';
        icon = Icons.check_circle_rounded;
        break;
      case UploadStatusType.alreadyUploaded:
        bgColor = AppColors.primary.withValues(alpha: 0.15);
        textColor = AppColors.primaryLight;
        label = 'EXISTS';
        icon = Icons.cloud_done_rounded;
        break;
      case UploadStatusType.failed:
        bgColor = AppColors.error.withValues(alpha: 0.15);
        textColor = AppColors.error;
        label = 'FAILED';
        icon = Icons.error_rounded;
        break;
      case UploadStatusType.uploading:
        bgColor = AppColors.warning.withValues(alpha: 0.15);
        textColor = AppColors.warning;
        label = 'UPLOADING';
        icon = Icons.cloud_upload_rounded;
        break;
      case UploadStatusType.pending:
        bgColor = AppColors.surfaceLight;
        textColor = AppColors.textMuted;
        label = 'PENDING';
        icon = Icons.schedule_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoveButton() {
    return Tooltip(
      message: 'Move game to new location',
      child: Material(
        color: _isHovered ? AppColors.surfaceLight : AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: widget.onMove,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _isHovered ? AppColors.borderLight : AppColors.border,
              ),
            ),
            child: Icon(
              Icons.drive_file_move_rounded,
              size: 18,
              color: _isHovered ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    if (widget.isUploading) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    return Tooltip(
      message: 'Upload manifest',
      child: Material(
        color: _isHovered ? AppColors.primary : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: widget.onUpload,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _isHovered ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Icon(
              Icons.cloud_upload_rounded,
              size: 18,
              color: _isHovered ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
