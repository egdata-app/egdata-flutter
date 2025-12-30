import 'package:flutter/material.dart';
import '../main.dart';

class FollowButton extends StatefulWidget {
  final bool isFollowing;
  final VoidCallback onToggle;
  final bool compact;

  const FollowButton({
    super.key,
    required this.isFollowing,
    required this.onToggle,
    this.compact = false,
  });

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompactButton();
    }
    return _buildFullButton();
  }

  Widget _buildCompactButton() {
    return Tooltip(
      message: widget.isFollowing ? 'Unfollow' : 'Follow',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: widget.isFollowing
                  ? (_isHovered
                      ? AppColors.error.withOpacity(0.15)
                      : AppColors.accentPink.withOpacity(0.12))
                  : (_isHovered
                      ? AppColors.primary.withOpacity(0.12)
                      : AppColors.surfaceLight),
              borderRadius: BorderRadius.circular(AppColors.radiusSmall),
              border: Border.all(
                color: widget.isFollowing
                    ? (_isHovered
                        ? AppColors.error.withOpacity(0.4)
                        : AppColors.accentPink.withOpacity(0.25))
                    : (_isHovered
                        ? AppColors.primary.withOpacity(0.4)
                        : AppColors.borderLight),
              ),
            ),
            child: Icon(
              widget.isFollowing
                  ? (_isHovered ? Icons.heart_broken_rounded : Icons.favorite_rounded)
                  : (_isHovered ? Icons.favorite_rounded : Icons.favorite_border_rounded),
              size: 18,
              color: widget.isFollowing
                  ? (_isHovered ? AppColors.error : AppColors.accentPink)
                  : (_isHovered ? AppColors.primary : AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isFollowing
                ? (_isHovered
                    ? AppColors.error.withOpacity(0.15)
                    : AppColors.accentPink.withOpacity(0.12))
                : (_isHovered
                    ? AppColors.primary
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(AppColors.radiusSmall),
            border: Border.all(
              color: widget.isFollowing
                  ? (_isHovered
                      ? AppColors.error.withOpacity(0.4)
                      : AppColors.accentPink.withOpacity(0.25))
                  : (_isHovered
                      ? AppColors.primary
                      : AppColors.borderLight),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.isFollowing
                    ? (_isHovered ? Icons.heart_broken_rounded : Icons.favorite_rounded)
                    : Icons.favorite_border_rounded,
                size: 16,
                color: widget.isFollowing
                    ? (_isHovered ? AppColors.error : AppColors.accentPink)
                    : (_isHovered ? Colors.white : AppColors.textSecondary),
              ),
              const SizedBox(width: 8),
              Text(
                widget.isFollowing
                    ? (_isHovered ? 'Unfollow' : 'Following')
                    : 'Follow',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.isFollowing
                      ? (_isHovered ? AppColors.error : AppColors.accentPink)
                      : (_isHovered ? Colors.white : AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
