import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../models/followed_game.dart';
import '../models/notification_topics.dart';
import '../models/settings.dart';
import '../services/api_service.dart';
import '../services/analytics_service.dart';
import '../services/chat_session_service.dart';
import '../services/follow_service.dart';
import '../services/push_service.dart';
import '../utils/platform_utils.dart';
import '../widgets/ask_ai_bottom_sheet.dart';
import '../widgets/follow_button.dart';
import '../widgets/notification_topic_selector.dart';
import '../widgets/progressive_image.dart';
import '../widgets/price_history_widget.dart';
import '../widgets/mobile_offer_detail_header.dart';
import '../widgets/offer_ratings_card.dart';
import '../widgets/base_game_banner.dart';
import '../widgets/screenshot_carousel.dart';
import '../widgets/achievements_bottom_sheet.dart';
import '../widgets/offer_giveaway_banner.dart';
import '../widgets/age_rating_badge.dart';
import '../widgets/offer_changelog_card.dart';
import '../widgets/skeleton_loading.dart';
import 'mobile_chat_page.dart';

class MobileOfferDetailPage extends StatefulWidget {
  final String offerId;
  final String? initialTitle;
  final String? initialImageUrl;
  final FollowService followService;
  final PushService? pushService;
  final ChatSessionService? chatService;
  final AppSettings? settings;
  final String country;

  const MobileOfferDetailPage({
    super.key,
    required this.offerId,
    required this.followService,
    this.pushService,
    this.chatService,
    this.settings,
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
  OfferFeatures? _features;
  List<AchievementSet>? _achievements;
  OfferHltb? _hltb;
  OfferMedia? _media;
  List<Offer>? _relatedOffers;
  OfferRatings? _ratings;
  OfferTops? _tops;
  Offer? _baseGame;
  List<Giveaway>? _giveaways;
  AgeRatings? _ageRatings;
  List<ChangelogItem>? _changelogPreview;
  int _changelogTotal = 0;

  // Loading state
  bool _isLoadingOffer = true;
  bool _isLoadingDetails = true; // For additional details (features, media, etc.)
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
      final offer = await _apiService.getOffer(widget.offerId);

      if (mounted) {
        setState(() {
          _offer = offer;
          _isLoadingOffer = false;
        });
        _updateCachedImageUrls();
        // Track game view with offer ID as parameter
        if (_offer != null) {
          AnalyticsService().logGameView(
            gameId: widget.offerId,
            gameName: _offer!.title,
            offerType: _offer!.offerType,
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
    // Note: base game requires the offer's namespace, so we load it separately
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
        _apiService.getOfferRatings(widget.offerId).catchError((_) => null),
        _apiService.getOfferTops(widget.offerId).catchError((_) => null),
        _apiService
            .getOfferGiveaways(widget.offerId)
            .catchError((_) => <Giveaway>[]),
        _apiService.getOfferAgeRatings(widget.offerId).catchError((_) => null),
        _apiService
            .getOfferChangelog(widget.offerId, page: 1, limit: 5)
            .catchError(
              (_) => ChangelogResponse(
                elements: [],
                page: 1,
                limit: 5,
                totalCount: 0,
                totalPages: 0,
                hasNextPage: false,
                hasPreviousPage: false,
              ),
            ),
      ]);

      if (mounted) {
        setState(() {
          _features = results[0] as OfferFeatures;
          _achievements = results[1] as List<AchievementSet>;
          _hltb = results[2] as OfferHltb?;
          _media = results[3] as OfferMedia?;
          _relatedOffers = results[4] as List<Offer>;
          _ratings = results[5] as OfferRatings?;
          _tops = results[6] as OfferTops?;
          _giveaways = results[7] as List<Giveaway>;
          _ageRatings = results[8] as AgeRatings?;
          final changelogResponse = results[9] as ChangelogResponse;
          _changelogPreview = changelogResponse.elements;
          _changelogTotal = changelogResponse.totalCount;
          _isLoadingDetails = false;
        });
      }

      // Load base game using the offer's sandbox/namespace (only if not already a base game)
      if (_offer != null && _offer!.offerType != 'BASE_GAME') {
        try {
          final baseGame = await _apiService
              .getBaseGameBySandbox(_offer!.namespace)
              .catchError((_) => null);

          if (mounted && baseGame != null && baseGame.id != _offer!.id) {
            setState(() {
              _baseGame = baseGame;
            });
          }
        } catch (e) {
          // Ignore - base game is optional
        }
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

  void _showAskAIBottomSheet() {
    if (_offer == null) return;
    if (widget.chatService == null || widget.settings == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AskAIBottomSheet(
        offerTitle: _offer!.title,
        offerId: widget.offerId,
        offerType: _offer!.offerType,
        chatService: widget.chatService!,
        onContinueInChat: _continueInChat,
      ),
    );
  }

  void _continueInChat(AskAIContinueResult result) {
    if (widget.chatService == null || widget.settings == null) return;

    // Navigate to the chat page with the existing session
    // The session already has the initial exchange, so we pass
    // existingMessages to pre-populate the chat
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MobileChatPage(
          settings: widget.settings!,
          apiService: _apiService,
          chatService: widget.chatService!,
          session: result.session,
          followService: widget.followService,
          pushService: widget.pushService,
          existingUserMessage: result.userMessage,
          existingAiResponse: result.aiResponse,
          existingReferencedOffers: result.referencedOffers,
        ),
      ),
    );
  }

  void _navigateToBaseGame(Offer baseGame) {
    // Cache the thumbnail URL for the base game
    final thumbnailUrl = _getThumbnailUrl(baseGame);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MobileOfferDetailPage(
          offerId: baseGame.id,
          followService: widget.followService,
          pushService: widget.pushService,
          chatService: widget.chatService,
          settings: widget.settings,
          initialTitle: baseGame.title,
          initialImageUrl: thumbnailUrl,
          country: widget.country,
        ),
      ),
    );
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
                onAskAI: widget.chatService != null && widget.settings != null
                    ? _showAskAIBottomSheet
                    : null,
              ),
              // Content
              if (_error != null)
                SliverFillRemaining(child: _buildErrorState())
              else if (_isLoadingOffer)
                const SliverToBoxAdapter(child: OfferDetailSkeleton())
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(_buildSliverChildren()),
                  ),
                ),
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

  List<Widget> _buildSliverChildren() {
    return [
      // Action buttons row
      if (_isLoadingDetails)
        const SkeletonActionButtons()
      else
        _buildActionButtons(),
      const SizedBox(height: 24),

      // Giveaway banner (shows if game was/is free)
      if (_giveaways != null && _giveaways!.isNotEmpty) ...[
        OfferGiveawayBanner(giveaways: _giveaways!),
        const SizedBox(height: 24),
      ],

      // Base game banner (for DLC/Add-ons)
      if (_baseGame != null) ...[
        BaseGameBanner(
          baseGame: _baseGame!,
          onTap: () => _navigateToBaseGame(_baseGame!),
        ),
        const SizedBox(height: 24),
      ],

      // Ratings card
      if (_isLoadingDetails)
        const SkeletonRatingsCard()
      else
        OfferRatingsCard(
          ratings: _ratings,
          tops: _tops,
        ),
      if (_isLoadingDetails || _ratings != null || _tops != null)
        const SizedBox(height: 24),

      // Price history (includes current price)
      if (_isLoadingDetails)
        const SkeletonPriceHistory()
      else
        PriceHistoryWidget(
          offerId: widget.offerId,
          country: widget.country,
        ),
      const SizedBox(height: 24),

      // Description
      if (_offer?.description.isNotEmpty == true) ...[
        _buildSection('About', _buildDescription()),
        const SizedBox(height: 24),
      ],

      // Features
      if (_isLoadingDetails ||
          (_features != null &&
              (_features!.features.isNotEmpty ||
                  _features!.epicFeatures.isNotEmpty))) ...[
        if (_isLoadingDetails)
          _buildSection('Features', const SkeletonFeatures())
        else
          _buildSection('Features', _buildFeatures()),
        const SizedBox(height: 24),
      ],

      // Genres/Tags
      if (_offer != null && _offer!.tags.isNotEmpty) ...[
        _buildSection('Genres', _buildGenres()),
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
      if (_isLoadingDetails ||
          (_media != null && _media!.images.isNotEmpty)) ...[
        if (_isLoadingDetails)
          _buildSection(
            'Screenshots',
            const SkeletonHorizontalList(itemWidth: 320, itemHeight: 180),
          )
        else
          _buildSection('Screenshots', _buildScreenshots()),
        const SizedBox(height: 24),
      ],

      // Related offers
      if (_isLoadingDetails ||
          (_relatedOffers != null && _relatedOffers!.isNotEmpty)) ...[
        if (_isLoadingDetails)
          _buildSection(
            'Related',
            const SkeletonHorizontalList(itemWidth: 120, itemHeight: 160),
          )
        else
          _buildSection('Related', _buildRelatedOffers()),
        const SizedBox(height: 24),
      ],

      // Changelog
      if (_changelogPreview != null && _changelogPreview!.isNotEmpty) ...[
        OfferChangelogCard(
          offerId: widget.offerId,
          preview: _changelogPreview!,
          totalCount: _changelogTotal,
        ),
        const SizedBox(height: 24),
      ],

      // Details
      if (_isLoadingDetails)
        _buildSection('Details', const SkeletonDetails())
      else
        _buildSection('Details', _buildDetails()),
      const SizedBox(height: 40),
    ];
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

  Widget _buildGenres() {
    final tags = _offer!.tags;
    final maxVisible = 6;
    final hasMore = tags.length > maxVisible;
    final visibleTags = hasMore ? tags.take(maxVisible).toList() : tags;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: visibleTags.map((tag) => _buildGenreChip(tag.name)).toList(),
        ),
        if (hasMore) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _showAllGenres(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Show all ${tags.length} genres',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGenreChip(String name) {
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
          const Icon(
            Icons.sell_rounded,
            size: 14,
            color: AppColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showAllGenres() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _GenresBottomSheet(tags: _offer!.tags),
    );
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
          AchievementsBottomSheet(achievements: achievements),
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
        builder: (context) => ScreenshotCarousel(
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
                      chatService: widget.chatService,
                      settings: widget.settings,
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
          if (_ageRatings != null) _buildAgeRatingRow(),
        ],
      ),
    );
  }

  Widget _buildAgeRatingRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Age Rating',
            style: TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: AgeRatingBadge(
              ageRatings: _ageRatings!,
              userCountry: widget.country,
            ),
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
    return DateFormat.yMMMd().format(date);
  }
}

class _GenresBottomSheet extends StatelessWidget {
  final List<Tag> tags;

  const _GenresBottomSheet({required this.tags});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.sell_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'All Genres (${tags.length})',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // Tags list
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.sell_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tag.name,
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}

