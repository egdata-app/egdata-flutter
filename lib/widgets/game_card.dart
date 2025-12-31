import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../models/followed_game.dart';
import '../services/follow_service.dart';
import 'follow_button.dart';

class GameCard extends StatefulWidget {
  final String offerId;
  final String title;
  final String? namespace;
  final String? thumbnailUrl;
  final int? originalPrice;
  final int? discountPrice;
  final FollowService followService;

  const GameCard({
    super.key,
    required this.offerId,
    required this.title,
    this.namespace,
    this.thumbnailUrl,
    this.originalPrice,
    this.discountPrice,
    required this.followService,
  });

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> {
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.followService.isFollowing(widget.offerId);
  }

  @override
  void didUpdateWidget(GameCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.offerId != widget.offerId) {
      _isFollowing = widget.followService.isFollowing(widget.offerId);
    }
  }

  bool get isOnSale =>
      widget.originalPrice != null &&
      widget.discountPrice != null &&
      widget.discountPrice! < widget.originalPrice! &&
      widget.originalPrice! > 0;

  bool get isFree => widget.discountPrice == null || widget.discountPrice == 0;

  int get discountPercent {
    if (!isOnSale || widget.originalPrice == 0) return 0;
    return ((1 - (widget.discountPrice! / widget.originalPrice!)) * 100).round();
  }

  String get formattedPrice {
    if (isFree) return 'Free';
    final price = widget.discountPrice! / 100;
    return '\$${price.toStringAsFixed(2)}';
  }

  String get formattedOriginalPrice {
    if (widget.originalPrice == null || widget.originalPrice == 0) return '';
    final price = widget.originalPrice! / 100;
    return '\$${price.toStringAsFixed(2)}';
  }

  Future<void> _openInBrowser() async {
    final url = Uri.parse('https://egdata.app/offers/${widget.offerId}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _toggleFollow() async {
    if (_isFollowing) {
      await widget.followService.unfollowGame(widget.offerId);
    } else {
      final game = FollowedGame(
        offerId: widget.offerId,
        title: widget.title,
        namespace: widget.namespace,
        thumbnailUrl: widget.thumbnailUrl,
        followedAt: DateTime.now(),
      );
      await widget.followService.followGame(game);
    }
    setState(() {
      _isFollowing = !_isFollowing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openInBrowser,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Game thumbnail
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                    child: SizedBox.expand(
                      child: widget.thumbnailUrl != null
                          ? Image.network(
                              widget.thumbnailUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildPlaceholder(),
                            )
                          : _buildPlaceholder(),
                    ),
                  ),
                  // Discount badge
                  if (isOnSale)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '-$discountPercent%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  // Follow button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: FollowButton(
                      isFollowing: _isFollowing,
                      onToggle: _toggleFollow,
                      compact: true,
                    ),
                  ),
                ],
              ),
            ),
            // Game info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Price row
                    if (widget.originalPrice != null || widget.discountPrice != null)
                      Row(
                        children: [
                          if (isOnSale) ...[
                            Text(
                              formattedOriginalPrice,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMuted,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            formattedPrice,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isFree
                                  ? AppColors.success
                                  : isOnSale
                                      ? AppColors.success
                                      : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surfaceLight,
      child: const Center(
        child: Icon(
          Icons.videogame_asset_rounded,
          color: AppColors.textMuted,
          size: 40,
        ),
      ),
    );
  }
}
