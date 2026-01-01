import 'package:flutter/material.dart';
import '../main.dart';

class FollowButton extends StatefulWidget {
  final bool isFollowing;
  final VoidCallback onToggle;
  final VoidCallback? onLongPress;
  final bool isLoading;
  final bool compact;

  const FollowButton({
    super.key,
    required this.isFollowing,
    required this.onToggle,
    this.onLongPress,
    this.isLoading = false,
    this.compact = false,
  });

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  AnimationController? _shimmerController;
  Animation<double>? _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _shimmerController!, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompactButton();
    }
    return _buildFullButton();
  }

  Widget _buildCompactButton() {
    return Tooltip(
      message: widget.isLoading
          ? 'Processing...'
          : (widget.isFollowing ? 'Unfollow' : 'Follow'),
      child: MouseRegion(
        cursor: widget.isLoading
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.isLoading ? null : widget.onToggle,
          onLongPress: widget.isLoading ? null : widget.onLongPress,
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: widget.isFollowing
                      ? (_isHovered && !widget.isLoading
                            ? AppColors.error.withValues(alpha: 0.15)
                            : AppColors.accentPink.withValues(alpha: 0.12))
                      : (_isHovered && !widget.isLoading
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : AppColors.surfaceLight),
                  borderRadius: BorderRadius.circular(AppColors.radiusSmall),
                  border: Border.all(
                    color: widget.isFollowing
                        ? (_isHovered && !widget.isLoading
                              ? AppColors.error.withValues(alpha: 0.4)
                              : AppColors.accentPink.withValues(alpha: 0.25))
                        : (_isHovered && !widget.isLoading
                              ? AppColors.primary.withValues(alpha: 0.4)
                              : AppColors.borderLight),
                  ),
                ),
                child: Center(
                  child: AnimatedOpacity(
                    opacity: widget.isLoading ? 0.4 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      widget.isFollowing
                          ? (_isHovered && !widget.isLoading
                                ? Icons.heart_broken_rounded
                                : Icons.favorite_rounded)
                          : (_isHovered && !widget.isLoading
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded),
                      size: 18,
                      color: widget.isFollowing
                          ? (_isHovered && !widget.isLoading
                                ? AppColors.error
                                : AppColors.accentPink)
                          : (_isHovered && !widget.isLoading
                                ? AppColors.primary
                                : AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
              // Shimmer overlay when loading - covers entire button
              if (widget.isLoading && _shimmerAnimation != null)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppColors.radiusSmall),
                    child: AnimatedBuilder(
                      animation: _shimmerAnimation!,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment(_shimmerAnimation!.value, 0),
                              end: Alignment(_shimmerAnimation!.value + 1, 0),
                              colors: [
                                Colors.transparent,
                                AppColors.primary.withValues(alpha: 0.15),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullButton() {
    return MouseRegion(
      cursor: widget.isLoading
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.isLoading ? null : widget.onToggle,
        onLongPress: widget.isLoading ? null : widget.onLongPress,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: widget.isFollowing
                    ? (_isHovered && !widget.isLoading
                          ? AppColors.error.withValues(alpha: 0.15)
                          : AppColors.accentPink.withValues(alpha: 0.12))
                    : (_isHovered && !widget.isLoading
                          ? AppColors.primary
                          : Colors.transparent),
                borderRadius: BorderRadius.circular(AppColors.radiusSmall),
                border: Border.all(
                  color: widget.isFollowing
                      ? (_isHovered && !widget.isLoading
                            ? AppColors.error.withValues(alpha: 0.4)
                            : AppColors.accentPink.withValues(alpha: 0.25))
                      : (_isHovered && !widget.isLoading
                            ? AppColors.primary
                            : AppColors.borderLight),
                ),
              ),
              child: AnimatedOpacity(
                opacity: widget.isLoading ? 0.5 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.isFollowing
                          ? (_isHovered && !widget.isLoading
                                ? Icons.heart_broken_rounded
                                : Icons.favorite_rounded)
                          : Icons.favorite_border_rounded,
                      size: 16,
                      color: widget.isFollowing
                          ? (_isHovered && !widget.isLoading
                                ? AppColors.error
                                : AppColors.accentPink)
                          : (_isHovered && !widget.isLoading
                                ? Colors.white
                                : AppColors.textSecondary),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.isLoading
                          ? 'Saving...'
                          : (widget.isFollowing
                                ? (_isHovered ? 'Unfollow' : 'Following')
                                : 'Follow'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.isFollowing
                            ? (_isHovered && !widget.isLoading
                                  ? AppColors.error
                                  : AppColors.accentPink)
                            : (_isHovered && !widget.isLoading
                                  ? Colors.white
                                  : AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Shimmer overlay when loading - covers entire button including padding
            if (widget.isLoading && _shimmerAnimation != null)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppColors.radiusSmall),
                  child: AnimatedBuilder(
                    animation: _shimmerAnimation!,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment(_shimmerAnimation!.value, 0),
                            end: Alignment(_shimmerAnimation!.value + 1, 0),
                            colors: [
                              Colors.transparent,
                              AppColors.primary.withValues(alpha: 0.2),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
