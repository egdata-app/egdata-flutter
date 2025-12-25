import 'package:flutter/material.dart';
import '../main.dart';
import '../models/search_result.dart';
import 'follow_button.dart';

class SearchResultTile extends StatefulWidget {
  final SearchResult result;
  final bool isFollowing;
  final VoidCallback onFollowToggle;

  const SearchResultTile({
    super.key,
    required this.result,
    required this.isFollowing,
    required this.onFollowToggle,
  });

  @override
  State<SearchResultTile> createState() => _SearchResultTileState();
}

class _SearchResultTileState extends State<SearchResultTile> {
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
              const SizedBox(width: 12),
              // Game info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.result.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (widget.result.developer != null)
                      Text(
                        widget.result.developer!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 6),
                    _buildPriceRow(),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Follow button
              FollowButton(
                isFollowing: widget.isFollowing,
                onToggle: widget.onFollowToggle,
                compact: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameImage() {
    return Container(
      width: 48,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: widget.result.thumbnailUrl != null
            ? Image.network(
                widget.result.thumbnailUrl!,
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
      child: const Center(
        child: Icon(
          Icons.games_rounded,
          size: 20,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildPriceRow() {
    if (widget.result.isFree) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'FREE',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.success,
          ),
        ),
      );
    }

    if (widget.result.hasDiscount) {
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              widget.result.formattedDiscountPrice ?? '',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            widget.result.formattedPrice ?? '',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      );
    }

    if (widget.result.formattedPrice != null) {
      return Text(
        widget.result.formattedPrice!,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.textSecondary,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
