import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../models/calendar_event.dart';

class CalendarEventTile extends StatefulWidget {
  final CalendarEvent event;
  final VoidCallback? onTap;

  const CalendarEventTile({
    super.key,
    required this.event,
    this.onTap,
  });

  @override
  State<CalendarEventTile> createState() => _CalendarEventTileState();
}

class _CalendarEventTileState extends State<CalendarEventTile> {
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
          borderRadius: BorderRadius.circular(6),
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Event type indicator
                _buildEventTypeIndicator(),
                const SizedBox(width: 12),
                // Game image
                _buildGameImage(),
                const SizedBox(width: 12),
                // Event info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.event.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusBadge(),
                        ],
                      ),
                      if (widget.event.subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.event.subtitle!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      _buildDateRow(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventTypeIndicator() {
    final color = _getEventColor();

    return Container(
      width: 4,
      height: 48,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildGameImage() {
    return Container(
      width: 40,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: widget.event.thumbnailUrl != null
            ? Image.network(
                widget.event.thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder(),
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
      child: Center(
        child: Icon(
          _getEventIcon(),
          size: 16,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    String label;
    Color bgColor;
    Color textColor;

    if (widget.event.isUpcoming) {
      label = 'UPCOMING';
      bgColor = AppColors.primary.withValues(alpha: 0.15);
      textColor = AppColors.primaryLight;
    } else if (widget.event.isActive) {
      label = 'ACTIVE';
      bgColor = AppColors.success.withValues(alpha: 0.15);
      textColor = AppColors.success;
    } else if (widget.event.hasEnded) {
      label = 'ENDED';
      bgColor = AppColors.surfaceLight;
      textColor = AppColors.textMuted;
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildDateRow() {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Row(
      children: [
        Icon(
          Icons.schedule_rounded,
          size: 12,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: 4),
        Text(
          dateFormat.format(widget.event.startDate),
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          timeFormat.format(widget.event.startDate),
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
        if (widget.event.endDate != null) ...[
          const SizedBox(width: 8),
          const Icon(
            Icons.arrow_forward_rounded,
            size: 10,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 4),
          Text(
            dateFormat.format(widget.event.endDate!),
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ],
    );
  }

  Color _getEventColor() {
    switch (widget.event.type) {
      case CalendarEventType.freeGame:
        return AppColors.success;
      case CalendarEventType.release:
        return AppColors.primary;
      case CalendarEventType.sale:
        return AppColors.warning;
      case CalendarEventType.followedUpdate:
        return AppColors.accent;
    }
  }

  IconData _getEventIcon() {
    switch (widget.event.type) {
      case CalendarEventType.freeGame:
        return Icons.card_giftcard_rounded;
      case CalendarEventType.release:
        return Icons.rocket_launch_rounded;
      case CalendarEventType.sale:
        return Icons.local_offer_rounded;
      case CalendarEventType.followedUpdate:
        return Icons.update_rounded;
    }
  }
}
