import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../models/followed_game.dart';
import '../models/notification_topics.dart';
import '../services/api_service.dart';
import '../services/analytics_service.dart';
import '../services/follow_service.dart';
import '../services/push_service.dart';
import '../utils/platform_utils.dart';
import '../widgets/follow_button.dart';
import '../widgets/notification_topic_selector.dart';
import '../widgets/progressive_image.dart';
import '../widgets/price_history_widget.dart';
import '../widgets/mobile_offer_detail_header.dart';

class MobileOfferDetailPage extends StatefulWidget {
  final String offerId;
  final String? initialTitle;
  final String? initialImageUrl;
  final FollowService followService;
  final PushService? pushService;
  final String country;

  const MobileOfferDetailPage({
    super.key,
    required this.offerId,
    required this.followService,
    this.pushService,
    this.initialTitle,
    this.initialImageUrl,
    this.country = 'US',
  });

  @override
  State<MobileOfferDetailPage> createState() => _MobileOfferDetailPageState();
}

class _MobileOfferDetailPageState extends State<MobileOfferDetailPage> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  // Data state
  Offer? _offer;
  TotalPrice? _price;
  OfferFeatures? _features;
  List<AchievementSet>? _achievements;
  OfferHltb? _hltb;
  OfferMedia? _media;
  List<Offer>? _relatedOffers;

  // Loading state
  bool _isLoadingOffer = true;
  String? _error;

  // Scroll state for collapsing header - use ValueNotifier to avoid full rebuilds
  final ValueNotifier<double> _scrollOffset = ValueNotifier<double>(0);

  // Following state
  bool _isFollowing = false;
  bool _isFollowLoading = false;

  // Cached image URLs to avoid recomputation
  String? _cachedWideImageUrl;
  String? _cachedTallImageUrl;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadData();
    _checkFollowStatus();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollOffset.dispose();
    _apiService.dispose();
    super.dispose();
  }

  void _onScroll() {
    _scrollOffset.value = _scrollController.offset;
  }

  void _updateCachedImageUrls() {
    if (_offer != null) {
      _cachedWideImageUrl = _getWideImageUrl(_offer!);
      _cachedTallImageUrl = _getThumbnailUrl(_offer);
    }
  }

  void _checkFollowStatus() {
    _isFollowing = widget.followService.isFollowing(widget.offerId);
  }

  Future<void> _toggleFollow() async {
    if (_offer == null || _isFollowLoading) return;

    setState(() => _isFollowLoading = true);

    try {
      if (_isFollowing) {
        // Unfollow: unsubscribe from all topics and delete from database
        final topics = await widget.followService.getNotificationTopics(widget.offerId);
        if (topics.isNotEmpty && widget.pushService != null && PlatformUtils.isMobile) {
          await widget.pushService!.unsubscribeFromTopics(topics: topics);
        }
        await widget.followService.unfollowGame(widget.offerId);
        // Track unfollow
        await AnalyticsService().logFollowGame(
          gameId: widget.offerId,
          gameName: _offer!.title,
          followed: false,
        );
      } else {
        // Follow: save to database and auto-subscribe to "all" topic
        final game = FollowedGame(
          offerId: widget.offerId,
          title: _offer!.title,
          namespace: _offer!.namespace,
          thumbnailUrl: _getWideImageUrl(_offer!) ?? _getThumbnailUrl(_offer!),
          followedAt: DateTime.now(),
        );
        await widget.followService.followGame(game);

        // Auto-subscribe to "all notifications" by default on mobile
        if (widget.pushService != null && PlatformUtils.isMobile) {
          final allTopic = OfferNotificationTopic.all.getTopicForOffer(widget.offerId);
          await _updateTopics([allTopic]);
        }

        // Track follow
        await AnalyticsService().logFollowGame(
          gameId: widget.offerId,
          gameName: _offer!.title,
          followed: true,
        );
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

    final currentTopics = await widget.followService.getNotificationTopics(widget.offerId);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => NotificationTopicSelector(
        offerId: widget.offerId,
        currentTopics: currentTopics,
        onTopicsChanged: _updateTopics,
      ),
    );
  }

  Future<void> _updateTopics(List<String> newTopics) async {
    setState(() => _isFollowLoading = true);

    try {
      final currentTopics = await widget.followService.getNotificationTopics(widget.offerId);

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
      await widget.followService.updateNotificationTopics(widget.offerId, newTopics);
    } finally {
      if (mounted) {
        setState(() => _isFollowLoading = false);
      }
    }
  }

  Future<void> _loadData() async {
    // Load main offer data first
    try {
      final results = await Future.wait([
        _apiService.getOffer(widget.offerId),
        _apiService.getOfferPrice(widget.offerId, country: widget.country),
      ]);

      if (mounted) {
        setState(() {
          _offer = results[0] as Offer;
          _price = results[1] as TotalPrice?;
          _isLoadingOffer = false;
        });
        _updateCachedImageUrls();
        // Track game view
        if (_offer != null) {
          AnalyticsService().logGameView(
            gameId: widget.offerId,
            gameName: _offer!.title,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoadingOffer = false;
        });
      }
      return;
    }

    // Load additional details in parallel
    try {
      final results = await Future.wait([
        _apiService
            .getOfferFeatures(widget.offerId)
            .catchError(
              (_) =>
                  OfferFeatures(launcher: '', features: [], epicFeatures: []),
            ),
        _apiService
            .getOfferAchievements(widget.offerId)
            .catchError((_) => <AchievementSet>[]),
        _apiService.getOfferHltb(widget.offerId).catchError((_) => null),
        _apiService.getOfferMedia(widget.offerId).catchError((_) => null),
        _apiService
            .getOfferRelated(widget.offerId)
            .catchError((_) => <Offer>[]),
      ]);

      if (mounted) {
        setState(() {
          _features = results[0] as OfferFeatures;
          _achievements = results[1] as List<AchievementSet>;
          _hltb = results[2] as OfferHltb?;
          _media = results[3] as OfferMedia?;
          _relatedOffers = results[4] as List<Offer>;
        });
      }
    } catch (e) {
      // Ignore errors loading additional details - main offer is already shown
    }
  }

  String? _getWideImageUrl(Offer offer) {
    if (offer.keyImages.isEmpty) return null;
    // Prefer wide images for hero
    final wideTypes = [
      'DieselStoreFrontWide',
      'OfferImageWide',
      'DieselGameBoxWide',
      'Featured',
    ];
    for (final type in wideTypes) {
      final img = offer.keyImages.where((i) => i.type == type).firstOrNull;
      if (img != null) return img.url;
    }
    // Fallback to any image
    return offer.keyImages.first.url;
  }

  String? _getThumbnailUrl(Offer? offer) {
    if (offer == null || offer.keyImages.isEmpty) return null;
    final thumbnail = offer.keyImages
        .where((img) => img.type == 'Thumbnail')
        .firstOrNull;
    if (thumbnail != null) return thumbnail.url;
    final boxTall = offer.keyImages
        .where((img) => img.type == 'DieselGameBoxTall')
        .firstOrNull;
    if (boxTall != null) return boxTall.url;
    return offer.keyImages.first.url;
  }

  Future<void> _openInBrowser() async {
    final url = Uri.parse('https://egdata.app/offers/${widget.offerId}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openEpicStore() async {
    final slug = _offer?.productSlug ?? _offer?.urlSlug;
    if (slug == null) return;
    final url = Uri.parse('https://store.epicgames.com/p/$slug');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final expandedHeight = MediaQuery.of(context).size.width * 0.5625; // 16:9
    final collapsedHeight = kToolbarHeight + statusBarHeight;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background gradient
          Container(decoration: AppColors.mobileRadialGradientBackground),
          Container(decoration: AppColors.mobileAccentGlowBackground),
          // Content
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Collapsing header
              MobileOfferDetailHeader(
                expandedHeight: expandedHeight,
                collapsedHeight: collapsedHeight,
                statusBarHeight: statusBarHeight,
                scrollOffset: _scrollOffset,
                wideImageUrl: _cachedWideImageUrl ?? widget.initialImageUrl,
                tallImageUrl: _cachedTallImageUrl,
                title: _offer?.title ?? widget.initialTitle,
                developerName: _offer?.developerDisplayName,
                onBack: () => Navigator.of(context).pop(),
                onOpenInBrowser: _openInBrowser,
              ),
              // Content
              if (_isLoadingOffer)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (_error != null)
                SliverFillRemaining(child: _buildErrorState())
              else
                SliverToBoxAdapter(child: _buildContent()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: AppColors.error.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Failed to load offer',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              setState(() {
                _error = null;
                _isLoadingOffer = true;
              });
              _loadData();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action buttons row
          _buildActionButtons(),
          const SizedBox(height: 24),

          // Price history (includes current price)
          if (_price != null) ...[
            PriceHistoryWidget(
              offerId: widget.offerId,
              country: widget.country,
            ),
            const SizedBox(height: 24),
          ],

          // Description
          if (_offer?.description.isNotEmpty == true) ...[
            _buildSection('About', _buildDescription()),
            const SizedBox(height: 24),
          ],

          // Features
          if (_features != null &&
              (_features!.features.isNotEmpty ||
                  _features!.epicFeatures.isNotEmpty)) ...[
            _buildSection('Features', _buildFeatures()),
            const SizedBox(height: 24),
          ],

          // How Long To Beat
          if (_hltb != null && _hltb!.gameTimes.isNotEmpty) ...[
            _buildSection('How Long To Beat', _buildHltb()),
            const SizedBox(height: 24),
          ],

          // Achievements
          if (_achievements != null && _achievements!.isNotEmpty) ...[
            _buildSection('Achievements', _buildAchievements()),
            const SizedBox(height: 24),
          ],

          // Screenshots
          if (_media != null && _media!.images.isNotEmpty) ...[
            _buildSection('Screenshots', _buildScreenshots()),
            const SizedBox(height: 24),
          ],

          // Related offers
          if (_relatedOffers != null && _relatedOffers!.isNotEmpty) ...[
            _buildSection('Related', _buildRelatedOffers()),
            const SizedBox(height: 24),
          ],

          // Details
          _buildSection('Details', _buildDetails()),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Follow button
        Expanded(
          child: FollowButton(
            isFollowing: _isFollowing,
            isLoading: _isFollowLoading,
            onToggle: _toggleFollow,
            onLongPress: PlatformUtils.isMobile ? _showTopicSelector : null,
          ),
        ),
        const SizedBox(width: 12),
        // Epic Store button
        if (_offer?.productSlug != null || _offer?.urlSlug != null)
          Expanded(
            child: GestureDetector(
              onTap: _openEpicStore,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_rounded,
                      size: 18,
                      color: AppColors.background,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Epic Store',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.background,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      _offer!.description,
      style: const TextStyle(
        fontSize: 14,
        height: 1.6,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildFeatures() {
    final allFeatures = [..._features!.features, ..._features!.epicFeatures];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: allFeatures.map((feature) {
        final icon = _getFeatureIcon(feature);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                feature,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  IconData _getFeatureIcon(String feature) {
    final lower = feature.toLowerCase();
    if (lower.contains('single')) return Icons.person_rounded;
    if (lower.contains('multi') ||
        lower.contains('coop') ||
        lower.contains('co-op')) {
      return Icons.people_rounded;
    }
    if (lower.contains('controller')) return Icons.gamepad_rounded;
    if (lower.contains('cloud')) return Icons.cloud_rounded;
    if (lower.contains('achievement')) return Icons.emoji_events_rounded;
    if (lower.contains('online')) return Icons.public_rounded;
    return Icons.check_circle_rounded;
  }

  Widget _buildHltb() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: _hltb!.gameTimes.map((time) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time.category,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  time.time,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAchievements() {
    final allAchievements = _achievements!
        .expand((set) => set.achievements)
        .toList();
    final displayCount = allAchievements.length > 6
        ? 6
        : allAchievements.length;
    final totalXp = allAchievements.fold<int>(0, (sum, a) => sum + a.xp);

    return GestureDetector(
      onTap: () => _showAchievementsBottomSheet(allAchievements),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: AppColors.warning,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${allAchievements.length} Achievements',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '$totalXp XP total',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                  size: 24,
                ),
              ],
            ),
            // Achievement grid preview
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.9,
              ),
              itemCount: displayCount,
              itemBuilder: (context, index) {
                final achievement = allAchievements[index];
                return _buildAchievementTile(achievement, compact: true);
              },
            ),
            // "View all" hint if more achievements
            if (allAchievements.length > 6) ...[
              const SizedBox(height: 10),
              Center(
                child: Text(
                  '+${allAchievements.length - 6} more',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementTile(
    Achievement achievement, {
    bool compact = false,
  }) {
    final tier = AchievementTierExtension.fromXp(achievement.xp);
    final iconSize = compact ? 48.0 : 56.0;
    final fallbackIconSize = compact ? 28.0 : 36.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: tier.color.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with tier glow effect
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: tier.color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: achievement.unlockedIconLink.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: achievement.unlockedIconLink,
                      width: iconSize,
                      height: iconSize,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: iconSize,
                        height: iconSize,
                        color: AppColors.surfaceLight,
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: iconSize,
                        height: iconSize,
                        color: AppColors.surfaceLight,
                        child: Icon(
                          Icons.emoji_events_rounded,
                          size: fallbackIconSize,
                          color: tier.color,
                        ),
                      ),
                    )
                  : Container(
                      width: iconSize,
                      height: iconSize,
                      color: AppColors.surfaceLight,
                      child: Icon(
                        Icons.emoji_events_rounded,
                        size: fallbackIconSize,
                        color: tier.color,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          // Tier + XP label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: tier.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${achievement.xp} XP',
              style: TextStyle(
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w700,
                color: tier.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAchievementsBottomSheet(List<Achievement> achievements) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _AchievementsBottomSheet(achievements: achievements),
    );
  }

  Widget _buildScreenshots() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _media!.images.length,
        itemExtent: 332, // 320 width + 12 padding for better scroll performance
        itemBuilder: (context, index) {
          final image = _media!.images[index];
          return Padding(
            padding: EdgeInsets.only(
              right: index < _media!.images.length - 1 ? 12 : 0,
            ),
            child: GestureDetector(
              onTap: () => _openScreenshotCarousel(index),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 320, // 16:9 aspect ratio with 180 height
                  height: 180,
                  child: CachedNetworkImage(
                    imageUrl: image.src,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.surfaceLight,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.surfaceLight,
                      child: const Icon(
                        Icons.broken_image_rounded,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openScreenshotCarousel(int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _ScreenshotCarousel(
          images: _media!.images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Widget _buildRelatedOffers() {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _relatedOffers!.length,
        itemExtent: 132, // 120 width + 12 padding for better scroll performance
        itemBuilder: (context, index) {
          final offer = _relatedOffers![index];
          // Cache thumbnail URL to avoid calling _getThumbnailUrl multiple times
          final thumbnailUrl = _getThumbnailUrl(offer);
          return Padding(
            padding: EdgeInsets.only(
              right: index < _relatedOffers!.length - 1 ? 12 : 0,
            ),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MobileOfferDetailPage(
                      offerId: offer.id,
                      followService: widget.followService,
                      pushService: widget.pushService,
                      initialTitle: offer.title,
                      initialImageUrl: thumbnailUrl,
                      country: widget.country,
                    ),
                  ),
                );
              },
              child: SizedBox(
                width: 120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 120,
                        height: 100,
                        child: thumbnailUrl != null
                            ? ProgressiveImage(
                                imageUrl: thumbnailUrl,
                                fit: BoxFit.cover,
                                placeholderWidth: 20,
                                finalWidth: 200,
                              )
                            : Container(
                                color: AppColors.surfaceLight,
                                child: const Icon(
                                  Icons.videogame_asset_rounded,
                                  color: AppColors.textMuted,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Title
                    Text(
                      offer.title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Type badge
                    Text(
                      _formatOfferType(offer.offerType),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatOfferType(String type) {
    switch (type) {
      case 'BASE_GAME':
        return 'Base Game';
      case 'DLC':
        return 'DLC';
      case 'ADD_ON':
        return 'Add-On';
      case 'BUNDLE':
        return 'Bundle';
      case 'EDITION':
        return 'Edition';
      case 'DEMO':
        return 'Demo';
      default:
        return type.replaceAll('_', ' ');
    }
  }

  Widget _buildDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          if (_offer?.developerDisplayName != null)
            _buildDetailRow('Developer', _offer!.developerDisplayName!),
          if (_offer?.publisherDisplayName != null)
            _buildDetailRow('Publisher', _offer!.publisherDisplayName!),
          if (_offer?.releaseDate != null)
            _buildDetailRow('Release Date', _formatDate(_offer!.releaseDate!)),
          _buildDetailRow('Type', _formatOfferType(_offer!.offerType)),
          if (_offer?.refundType != null)
            _buildDetailRow(
              'Refund Policy',
              _offer!.refundType!.replaceAll('_', ' ').toLowerCase(),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// Screenshot carousel viewer
class _ScreenshotCarousel extends StatefulWidget {
  final List<MediaImage> images;
  final int initialIndex;

  const _ScreenshotCarousel({required this.images, required this.initialIndex});

  @override
  State<_ScreenshotCarousel> createState() => _ScreenshotCarouselState();
}

class _ScreenshotCarouselState extends State<_ScreenshotCarousel> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // PageView for swiping between screenshots
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return Center(
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: CachedNetworkImage(
                    imageUrl: widget.images[index].src,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(
                        Icons.broken_image_rounded,
                        color: Colors.white54,
                        size: 64,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // Download button (top left)
          Positioned(
            top: topPadding + 8,
            left: 8,
            child: GestureDetector(
              onTap: _downloadCurrentImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.download_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          // Close button (top right)
          Positioned(
            top: topPadding + 8,
            right: 8,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          // Thumbnail preview strip at bottom
          Positioned(
            bottom: bottomPadding + 16,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image counter
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Thumbnail strip
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: widget.images.length,
                    itemBuilder: (context, index) {
                      final isActive = index == _currentIndex;
                      return GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          width: 80,
                          margin: EdgeInsets.only(
                            right: index < widget.images.length - 1 ? 8 : 0,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isActive
                                  ? AppColors.primary
                                  : Colors.white.withValues(alpha: 0.3),
                              width: isActive ? 3 : 1.5,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: CachedNetworkImage(
                              imageUrl: widget.images[index].src,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  Container(color: Colors.grey.shade800),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey.shade800,
                                child: const Icon(
                                  Icons.broken_image_rounded,
                                  color: Colors.white54,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadCurrentImage() async {
    final url = Uri.parse(widget.images[_currentIndex].src);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}

// Achievements bottom sheet with filters
enum AchievementSortBy { name, xp, tier }

enum AchievementFilter { all, visible, hidden }

enum AchievementTier { platinum, gold, silver, bronze }

extension AchievementTierExtension on AchievementTier {
  String get label {
    switch (this) {
      case AchievementTier.platinum:
        return 'Platinum';
      case AchievementTier.gold:
        return 'Gold';
      case AchievementTier.silver:
        return 'Silver';
      case AchievementTier.bronze:
        return 'Bronze';
    }
  }

  Color get color {
    switch (this) {
      case AchievementTier.platinum:
        return const Color(0xFFE5E4E2); // Platinum silver
      case AchievementTier.gold:
        return const Color(0xFFFFD700); // Gold
      case AchievementTier.silver:
        return const Color(0xFFC0C0C0); // Silver
      case AchievementTier.bronze:
        return const Color(0xFFCD7F32); // Bronze
    }
  }

  int get sortOrder {
    switch (this) {
      case AchievementTier.platinum:
        return 0;
      case AchievementTier.gold:
        return 1;
      case AchievementTier.silver:
        return 2;
      case AchievementTier.bronze:
        return 3;
    }
  }

  static AchievementTier fromXp(int xp) {
    if (xp >= 250) return AchievementTier.platinum;
    if (xp >= 100) return AchievementTier.gold;
    if (xp >= 50) return AchievementTier.silver;
    return AchievementTier.bronze;
  }
}

class _AchievementsBottomSheet extends StatefulWidget {
  final List<Achievement> achievements;

  const _AchievementsBottomSheet({required this.achievements});

  @override
  State<_AchievementsBottomSheet> createState() =>
      _AchievementsBottomSheetState();
}

class _AchievementsBottomSheetState extends State<_AchievementsBottomSheet> {
  AchievementSortBy _sortBy = AchievementSortBy.tier;
  AchievementFilter _filter = AchievementFilter.all;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Cached filtered list to avoid recomputation
  List<Achievement>? _cachedFilteredAchievements;
  // Cache keys to detect when we need to recompute
  AchievementSortBy? _cachedSortBy;
  AchievementFilter? _cachedFilter;
  String? _cachedSearchQuery;
  // Cached total XP
  late final int _totalXp;

  @override
  void initState() {
    super.initState();
    _totalXp = widget.achievements.fold<int>(0, (sum, a) => sum + a.xp);
  }

  List<Achievement> get _filteredAchievements {
    // Return cached result if nothing changed
    if (_cachedFilteredAchievements != null &&
        _cachedSortBy == _sortBy &&
        _cachedFilter == _filter &&
        _cachedSearchQuery == _searchQuery) {
      return _cachedFilteredAchievements!;
    }

    var list = widget.achievements.toList();

    // Apply filter
    if (_filter == AchievementFilter.visible) {
      list = list.where((a) => !a.hidden).toList();
    } else if (_filter == AchievementFilter.hidden) {
      list = list.where((a) => a.hidden).toList();
    }

    // Apply search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list
          .where(
            (a) =>
                a.unlockedDisplayName.toLowerCase().contains(query) ||
                a.unlockedDescription.toLowerCase().contains(query) ||
                a.flavorText.toLowerCase().contains(query),
          )
          .toList();
    }

    // Apply sort
    switch (_sortBy) {
      case AchievementSortBy.name:
        list.sort(
          (a, b) => a.unlockedDisplayName.compareTo(b.unlockedDisplayName),
        );
        break;
      case AchievementSortBy.xp:
        list.sort((a, b) => b.xp.compareTo(a.xp));
        break;
      case AchievementSortBy.tier:
        // Sort by tier (Platinum first), then by XP within tier
        list.sort((a, b) {
          final tierA = AchievementTierExtension.fromXp(a.xp);
          final tierB = AchievementTierExtension.fromXp(b.xp);
          final tierCompare = tierA.sortOrder.compareTo(tierB.sortOrder);
          if (tierCompare != 0) return tierCompare;
          return b.xp.compareTo(a.xp);
        });
        break;
    }

    // Cache the result
    _cachedFilteredAchievements = list;
    _cachedSortBy = _sortBy;
    _cachedFilter = _filter;
    _cachedSearchQuery = _searchQuery;

    return list;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final filtered = _filteredAchievements;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: AppColors.warning,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.achievements.length} Achievements',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '$_totalXp XP total',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search achievements...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textMuted,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear_rounded,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Filter dropdown
                _buildFilterChip(
                  label: _filter == AchievementFilter.all
                      ? 'All'
                      : _filter == AchievementFilter.visible
                      ? 'Visible'
                      : 'Hidden',
                  icon: Icons.filter_list_rounded,
                  onTap: () => _showFilterMenu(),
                ),
                const SizedBox(width: 8),
                // Sort dropdown
                _buildFilterChip(
                  label: _sortBy == AchievementSortBy.tier
                      ? 'By tier'
                      : _sortBy == AchievementSortBy.xp
                      ? 'Most XP'
                      : 'A-Z',
                  icon: Icons.sort_rounded,
                  onTap: () => _showSortMenu(),
                ),
                const SizedBox(width: 8),
                // Results count
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${filtered.length} results',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Achievement list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: AppColors.textMuted.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No achievements found',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: bottomPadding + 16,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final achievement = filtered[index];
                      return _buildAchievementListItem(achievement);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Filter by',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            _buildMenuOption(
              'All achievements',
              AchievementFilter.all,
              _filter,
              (f) {
                setState(() => _filter = f);
                Navigator.pop(context);
              },
            ),
            _buildMenuOption(
              'Visible only',
              AchievementFilter.visible,
              _filter,
              (f) {
                setState(() => _filter = f);
                Navigator.pop(context);
              },
            ),
            _buildMenuOption('Hidden only', AchievementFilter.hidden, _filter, (
              f,
            ) {
              setState(() => _filter = f);
              Navigator.pop(context);
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showSortMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Sort by',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            _buildMenuOption(
              'By tier (Platinum first)',
              AchievementSortBy.tier,
              _sortBy,
              (s) {
                setState(() => _sortBy = s);
                Navigator.pop(context);
              },
            ),
            _buildMenuOption('Most XP', AchievementSortBy.xp, _sortBy, (s) {
              setState(() => _sortBy = s);
              Navigator.pop(context);
            }),
            _buildMenuOption('Name (A-Z)', AchievementSortBy.name, _sortBy, (
              s,
            ) {
              setState(() => _sortBy = s);
              Navigator.pop(context);
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption<T>(
    String label,
    T value,
    T current,
    Function(T) onSelect,
  ) {
    final isSelected = value == current;
    return ListTile(
      onTap: () => onSelect(value),
      leading: Icon(
        isSelected
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_off_rounded,
        color: isSelected ? AppColors.primary : AppColors.textMuted,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildAchievementListItem(Achievement achievement) {
    final tier = AchievementTierExtension.fromXp(achievement.xp);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Achievement icon with tier border
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: tier.color, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: achievement.unlockedIconLink.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: achievement.unlockedIconLink,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 56,
                            height: 56,
                            color: AppColors.surfaceLight,
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 56,
                            height: 56,
                            color: AppColors.surfaceLight,
                            child: Icon(
                              Icons.emoji_events_rounded,
                              size: 32,
                              color: tier.color,
                            ),
                          ),
                        )
                      : Container(
                          width: 56,
                          height: 56,
                          color: AppColors.surfaceLight,
                          child: Icon(
                            Icons.emoji_events_rounded,
                            size: 32,
                            color: tier.color,
                          ),
                        ),
                ),
              ),
              // Hidden badge
              if (achievement.hidden)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      Icons.visibility_off_rounded,
                      size: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Achievement info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.unlockedDisplayName.isNotEmpty
                      ? achievement.unlockedDisplayName
                      : achievement.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (achievement.unlockedDescription.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    achievement.unlockedDescription,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Tier badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: tier.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: tier.color.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.emoji_events_rounded,
                            size: 12,
                            color: tier.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tier.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: tier.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // XP badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${achievement.xp} XP',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    // Completion percentage (if available)
                    if (achievement.completedPercent > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${achievement.completedPercent.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
