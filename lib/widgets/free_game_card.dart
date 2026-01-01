import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../database/collections/free_game_entry.dart';
import '../models/followed_game.dart';
import '../models/notification_topics.dart';
import '../services/follow_service.dart';
import '../services/push_service.dart';
import '../utils/platform_utils.dart';
import 'follow_button.dart';
import 'notification_topic_selector.dart';
import 'progressive_image.dart';

class FreeGameCard extends StatefulWidget {
  final FreeGameEntry game;
  final FollowService followService;
  final PushService? pushService;
  final bool isActive;
  final VoidCallback? onTap;

  const FreeGameCard({
    super.key,
    required this.game,
    required this.followService,
    this.pushService,
    required this.isActive,
    this.onTap,
  });

  @override
  State<FreeGameCard> createState() => _FreeGameCardState();
}

class _FreeGameCardState extends State<FreeGameCard> {
  bool _isFollowing = false;
  bool _isFollowLoading = false;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.followService.isFollowing(widget.game.offerId);
  }

  @override
  void didUpdateWidget(FreeGameCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game.offerId != widget.game.offerId) {
      _isFollowing = widget.followService.isFollowing(widget.game.offerId);
    }
  }

  String _formatTimeRemaining(DateTime endDate) {
    final now = DateTime.now();
    final difference = endDate.difference(now);

    if (difference.isNegative) return 'Expired';

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;

    if (days > 0) {
      return '${days}d ${hours}h left';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m left';
    } else {
      return '${minutes}m left';
    }
  }

  String _formatStartDate(DateTime startDate) {
    final now = DateTime.now();
    final difference = startDate.difference(now);

    if (difference.isNegative) return 'Now';

    final days = difference.inDays;
    final hours = difference.inHours % 24;

    if (days > 0) {
      return 'In ${days}d ${hours}h';
    } else if (hours > 0) {
      final minutes = difference.inMinutes % 60;
      return 'In ${hours}h ${minutes}m';
    } else {
      final minutes = difference.inMinutes % 60;
      return 'In ${minutes}m';
    }
  }

  Future<void> _openInBrowser() async {
    final url = Uri.parse('https://egdata.app/offers/${widget.game.offerId}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _toggleFollow() async {
    if (_isFollowLoading) return;

    setState(() => _isFollowLoading = true);

    try {
      if (_isFollowing) {
        // Unfollow: unsubscribe from all topics and delete from database
        final topics = await widget.followService.getNotificationTopics(widget.game.offerId);
        if (topics.isNotEmpty && widget.pushService != null && PlatformUtils.isMobile) {
          await widget.pushService!.unsubscribeFromTopics(topics: topics);
        }
        await widget.followService.unfollowGame(widget.game.offerId);
      } else {
        // Follow: save to database and auto-subscribe to "all" topic
        final game = FollowedGame(
          offerId: widget.game.offerId,
          title: widget.game.title,
          namespace: widget.game.namespace,
          thumbnailUrl: widget.game.thumbnailUrl,
          followedAt: DateTime.now(),
        );
        await widget.followService.followGame(game);

        // Auto-subscribe to "all notifications" by default on mobile
        if (widget.pushService != null && PlatformUtils.isMobile) {
          final allTopic = OfferNotificationTopic.all.getTopicForOffer(widget.game.offerId);
          await _updateTopics([allTopic]);
        }
      }
      setState(() {
        _isFollowing = !_isFollowing;
      });
    } finally {
      setState(() => _isFollowLoading = false);
    }
  }

  Future<void> _showTopicSelector() async {
    if (!_isFollowing || !PlatformUtils.isMobile) return;

    final currentTopics = await widget.followService.getNotificationTopics(widget.game.offerId);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => NotificationTopicSelector(
        offerId: widget.game.offerId,
        currentTopics: currentTopics,
        onTopicsChanged: _updateTopics,
      ),
    );
  }

  Future<void> _updateTopics(List<String> newTopics) async {
    setState(() => _isFollowLoading = true);

    try {
      final currentTopics = await widget.followService.getNotificationTopics(widget.game.offerId);

      // Calculate topics to add and remove
      final toAdd = newTopics.where((t) => !currentTopics.contains(t)).toList();
      final toRemove = currentTopics.where((t) => !newTopics.contains(t)).toList();

      // Update FCM subscriptions
      if (widget.pushService != null && PlatformUtils.isMobile) {
        if (toAdd.isNotEmpty) {
          await widget.pushService!.subscribeToTopics(topics: toAdd);
        }
        if (toRemove.isNotEmpty) {
          await widget.pushService!.unsubscribeFromTopics(topics: toRemove);
        }
      }

      // Update database
      await widget.followService.updateNotificationTopics(widget.game.offerId, newTopics);
    } finally {
      if (mounted) {
        setState(() => _isFollowLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap ?? _openInBrowser,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Game thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                bottomLeft: Radius.circular(15),
              ),
              child: SizedBox(
                width: 120,
                height: 100,
                child: widget.game.thumbnailUrl != null
                    ? ProgressiveImage(
                        imageUrl: widget.game.thumbnailUrl!,
                        fit: BoxFit.cover,
                        placeholderWidth: 20,
                        finalWidth: 240,
                      )
                    : _buildPlaceholder(),
              ),
            ),
            // Game info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.game.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Time badge - simplified without platform text
                    IntrinsicWidth(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: widget.isActive
                              ? AppColors.success.withValues(alpha: 0.15)
                              : AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.isActive
                                  ? Icons.access_time_rounded
                                  : Icons.schedule_rounded,
                              size: 12,
                              color: widget.isActive
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.isActive
                                  ? (widget.game.endDate != null
                                      ? _formatTimeRemaining(widget.game.endDate!)
                                      : 'Available')
                                  : (widget.game.startDate != null
                                      ? _formatStartDate(widget.game.startDate!)
                                      : 'Coming soon'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: widget.isActive
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Follow button
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: FollowButton(
                isFollowing: _isFollowing,
                isLoading: _isFollowLoading,
                onToggle: _toggleFollow,
                onLongPress: PlatformUtils.isMobile ? _showTopicSelector : null,
                compact: true,
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
          size: 32,
        ),
      ),
    );
  }
}
