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
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Material(
          color: widget.isFollowing
              ? (_isHovered ? AppColors.error.withValues(alpha: 0.15) : AppColors.accent.withValues(alpha: 0.15))
              : (_isHovered ? AppColors.surfaceLight : AppColors.surface),
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            onTap: widget.onToggle,
            borderRadius: BorderRadius.circular(4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: widget.isFollowing
                      ? (_isHovered ? AppColors.error : AppColors.accent)
                      : (_isHovered ? AppColors.borderLight : AppColors.border),
                ),
              ),
              child: Icon(
                widget.isFollowing
                    ? (_isHovered ? Icons.heart_broken_rounded : Icons.favorite_rounded)
                    : (_isHovered ? Icons.favorite_rounded : Icons.favorite_border_rounded),
                size: 18,
                color: widget.isFollowing
                    ? (_isHovered ? AppColors.error : AppColors.accent)
                    : (_isHovered ? AppColors.primary : AppColors.textSecondary),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullButton() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        child: Material(
          color: widget.isFollowing
              ? (_isHovered ? AppColors.error.withValues(alpha: 0.15) : AppColors.accent.withValues(alpha: 0.15))
              : (_isHovered ? AppColors.primary : AppColors.surface),
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            onTap: widget.onToggle,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: widget.isFollowing
                      ? (_isHovered ? AppColors.error : AppColors.accent)
                      : (_isHovered ? AppColors.primary : AppColors.border),
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
                        ? (_isHovered ? AppColors.error : AppColors.accent)
                        : (_isHovered ? Colors.white : AppColors.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.isFollowing
                        ? (_isHovered ? 'UNFOLLOW' : 'FOLLOWING')
                        : 'FOLLOW',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: widget.isFollowing
                          ? (_isHovered ? AppColors.error : AppColors.accent)
                          : (_isHovered ? Colors.white : AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
