import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluquery/fluquery.dart';
import '../main.dart';
import '../database/database_service.dart';
import '../models/settings.dart';
import '../services/api_service.dart';
import '../services/follow_service.dart';
import '../services/push_service.dart';
import '../services/sync_service.dart';
import '../widgets/progressive_image.dart';
import '../widgets/free_games_notification_prompt_dialog.dart';
import 'mobile_offer_detail_page.dart';

class MobileDashboardPage extends HookWidget {
  final FollowService followService;
  final SyncService syncService;
  final DatabaseService db;
  final AppSettings settings;
  final PushService? pushService;
  final ValueChanged<AppSettings> onSettingsChanged;

  const MobileDashboardPage({
    super.key,
    required this.followService,
    required this.syncService,
    required this.db,
    required this.settings,
    this.pushService,
    required this.onSettingsChanged,
  });

  Future<List<FreeGame>> _fetchActiveFreeGames() async {
    final apiService = ApiService();
    final allGames = await apiService.getFreeGames();

    // Filter for active free games (currently within giveaway period)
    final now = DateTime.now();
    return allGames.where((g) {
      if (g.giveaway == null) return false;
      return now.isAfter(g.giveaway!.startDate) &&
          now.isBefore(g.giveaway!.endDate);
    }).toList();
  }

  Future<HomepageStats> _fetchHomepageStats(String country) async {
    final apiService = ApiService();
    return apiService.getHomepageStats(country: country);
  }

  Future<FreeGamesStats> _fetchFreeGamesStats(String country) async {
    final apiService = ApiService();
    return apiService.getFreeGamesStats(country: country);
  }

  Future<List<FollowedGameEntry>> _fetchGamesOnSale() async {
    await followService.loadFollowedGames();
    final entries = await db.getAllFollowedGames();
    return entries.where((g) => g.isOnSale).toList();
  }

  void _openGame(BuildContext context, String offerId, {String? title, String? imageUrl}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MobileOfferDetailPage(
          offerId: offerId,
          followService: followService,
          initialTitle: title,
          initialImageUrl: imageUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final queryClient = useQueryClient();

    // Query for free games
    final freeGamesQuery = useQuery<List<FreeGame>, Object>(
      queryKey: ['free-games'],
      queryFn: (_) => _fetchActiveFreeGames(),
      staleTime: StaleTime(const Duration(minutes: 5)),
    );

    // Query for homepage stats
    final homepageStatsQuery = useQuery<HomepageStats, Object>(
      queryKey: ['homepage-stats', settings.country],
      queryFn: (_) => _fetchHomepageStats(settings.country),
      staleTime: StaleTime(const Duration(minutes: 5)),
    );

    // Query for free games stats
    final freeGamesStatsQuery = useQuery<FreeGamesStats, Object>(
      queryKey: ['free-games-stats', settings.country],
      queryFn: (_) => _fetchFreeGamesStats(settings.country),
      staleTime: StaleTime(const Duration(minutes: 5)),
    );

    // Query for games on sale
    final gamesOnSaleQuery = useQuery<List<FollowedGameEntry>, Object>(
      queryKey: ['games-on-sale'],
      queryFn: (_) => _fetchGamesOnSale(),
      staleTime: StaleTime(const Duration(minutes: 1)),
    );

    // Listen to followed games stream and invalidate query
    useEffect(() {
      final sub = followService.followedGamesStream.listen((_) {
        queryClient.invalidateQueries(queryKey: ['games-on-sale']);
      });
      return sub.cancel;
    }, []);

    // Show free games notification prompt for new users
    useEffect(() {
      Future<void> showPromptIfNeeded() async {
        // Only show if:
        // 1. User hasn't seen the prompt yet
        // 2. Push service is available
        // 3. User is not already subscribed
        if (!settings.hasSeenFreeGamesNotificationPrompt &&
            pushService != null &&
            pushService!.isAvailable &&
            !settings.pushNotificationsEnabled) {
          // Wait a bit for the page to load before showing dialog
          await Future.delayed(const Duration(milliseconds: 500));

          if (context.mounted) {
            final shouldEnable = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (context) => const FreeGamesNotificationPromptDialog(),
            );

            // Mark as seen regardless of user choice
            final updatedSettings = settings.copyWith(
              hasSeenFreeGamesNotificationPrompt: true,
            );

            if (shouldEnable == true && pushService != null) {
              // User accepted - subscribe to push notifications with free-games topic
              final result = await pushService!.subscribe(
                topics: [PushTopics.freeGames],
              );

              if (result.success) {
                // Update settings to mark as subscribed
                onSettingsChanged(updatedSettings.copyWith(
                  pushNotificationsEnabled: true,
                ));
              } else {
                // Failed to subscribe, just mark as seen
                onSettingsChanged(updatedSettings);
              }
            } else {
              // User declined, just mark as seen
              onSettingsChanged(updatedSettings);
            }
          }
        }
      }

      showPromptIfNeeded();
      return null;
    }, [settings.hasSeenFreeGamesNotificationPrompt, settings.pushNotificationsEnabled]);

    // Handle loading state
    final isLoading = freeGamesQuery.isLoading ||
        homepageStatsQuery.isLoading ||
        freeGamesStatsQuery.isLoading ||
        gamesOnSaleQuery.isLoading;

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    // Extract data
    final activeFreeGames = freeGamesQuery.data ?? [];
    final homepageStats = homepageStatsQuery.data;
    final freeGamesStats = freeGamesStatsQuery.data;
    final gamesOnSale = gamesOnSaleQuery.data ?? [];

    // Refresh handler
    Future<void> handleRefresh() async {
      await Future.wait([
        freeGamesQuery.refetch(),
        homepageStatsQuery.refetch(),
        freeGamesStatsQuery.refetch(),
        gamesOnSaleQuery.refetch(),
      ]);
    }

    return RefreshIndicator(
      onRefresh: handleRefresh,
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.home_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Your Epic Games companion',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Stats row - Homepage stats
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.storefront_rounded,
                    label: 'Offers',
                    value: _formatNumber(homepageStats?.offers ?? 0),
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.card_giftcard_rounded,
                    label: 'Giveaways',
                    value: _formatNumber(homepageStats?.giveaways ?? 0),
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.percent_rounded,
                    label: 'On Sale',
                    value: _formatNumber(homepageStats?.activeDiscounts ?? 0),
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Free games stats row
            if (freeGamesStats != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.redeem_rounded,
                            color: AppColors.success,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Free Games Program',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMiniStat(
                            'Total Giveaways',
                            _formatNumber(freeGamesStats!.totalGiveaways),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: AppColors.border,
                        ),
                        Expanded(
                          child: _buildMiniStat(
                            'Total Offers',
                            _formatNumber(freeGamesStats!.totalOffers),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: AppColors.border,
                        ),
                        Expanded(
                          child: _buildMiniStat(
                            'Publishers',
                            _formatNumber(freeGamesStats!.sellers),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.savings_rounded,
                            color: AppColors.success,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Total value: ${freeGamesStats!.totalValue.formattedOriginalPrice}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 28),

            // Free games section
            if (activeFreeGames.isNotEmpty) ...[
              _buildSectionHeader(
                'Free Now',
                Icons.card_giftcard_rounded,
                AppColors.success,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: activeFreeGames.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final game = activeFreeGames[index];
                    return _buildFreeGameCard(context, game);
                  },
                ),
              ),
              const SizedBox(height: 28),
            ],

            // Games on sale section
            if (gamesOnSale.isNotEmpty) ...[
              _buildSectionHeader(
                'Followed Games On Sale',
                Icons.local_offer_rounded,
                AppColors.warning,
              ),
              const SizedBox(height: 12),
              ...gamesOnSale
                  .take(5)
                  .map(
                    (game) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildSaleCard(context, game),
                    ),
                  ),
              const SizedBox(height: 16),
            ],

            // Empty state
            if (activeFreeGames.isEmpty && gamesOnSale.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.explore_rounded,
                      size: 48,
                      color: AppColors.textMuted.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Nothing here yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check out free games or follow games to track sales',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  String? _getThumbnailUrl(FreeGame game) {
    if (game.keyImages.isEmpty) return null;

    // Prefer Thumbnail, then DieselGameBoxTall, then any image
    final thumbnail =
        game.keyImages.where((img) => img.type == 'Thumbnail').firstOrNull;
    if (thumbnail != null) return thumbnail.url;

    final boxTall =
        game.keyImages.where((img) => img.type == 'DieselGameBoxTall').firstOrNull;
    if (boxTall != null) return boxTall.url;

    return game.keyImages.first.url;
  }

  Widget _buildFreeGameCard(BuildContext context, FreeGame game) {
    final thumbnailUrl = _getThumbnailUrl(game);
    return GestureDetector(
      onTap: () => _openGame(context, game.id, title: game.title, imageUrl: thumbnailUrl),
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(13),
                  topRight: Radius.circular(13),
                ),
                child: thumbnailUrl != null
                    ? ProgressiveImage(
                        imageUrl: thumbnailUrl,
                        fit: BoxFit.cover,
                        placeholderWidth: 20,
                        finalWidth: 400,
                      )
                    : _buildPlaceholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'FREE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaleCard(BuildContext context, FollowedGameEntry game) {
    return GestureDetector(
      onTap: () => _openGame(context, game.offerId, title: game.title, imageUrl: game.thumbnailUrl),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 56,
                height: 56,
                child: game.thumbnailUrl != null
                    ? ProgressiveImage(
                        imageUrl: game.thumbnailUrl!,
                        fit: BoxFit.cover,
                        placeholderWidth: 10,
                        finalWidth: 120,
                      )
                    : _buildPlaceholder(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        game.formattedOriginalPrice,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        game.formattedCurrentPrice,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '-${game.discountPercent}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
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
          size: 24,
        ),
      ),
    );
  }
}
