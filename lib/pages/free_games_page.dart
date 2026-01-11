import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluquery/fluquery.dart';
import '../main.dart';
import '../database/database_service.dart';
import '../models/settings.dart';
import '../services/api_service.dart';
import '../services/chat_session_service.dart';
import '../services/follow_service.dart';
import '../services/push_service.dart';
import '../services/sync_service.dart';
import '../widgets/free_game_card.dart';
import 'mobile_offer_detail_page.dart';

class FreeGamesPage extends HookWidget {
  final FollowService followService;
  final SyncService syncService;
  final DatabaseService db;
  final PushService? pushService;
  final ChatSessionService? chatService;
  final AppSettings? settings;

  const FreeGamesPage({
    super.key,
    required this.followService,
    required this.syncService,
    required this.db,
    this.pushService,
    this.chatService,
    this.settings,
  });

  Future<List<FreeGameEntry>> _fetchFreeGames() async {
    final apiService = ApiService();
    final allGames = await apiService.getFreeGames();

    // Convert FreeGame API models to FreeGameEntry for the card widget
    return allGames.map((game) {
      // Find thumbnail from key images
      String? thumbnail;
      for (final type in ['OfferImageWide', 'DieselStoreFrontWide', 'DieselGameBoxTall']) {
        final image = game.keyImages.where((img) => img.type == type).firstOrNull;
        if (image != null) {
          thumbnail = image.url;
          break;
        }
      }
      if (thumbnail == null && game.keyImages.isNotEmpty) {
        thumbnail = game.keyImages.first.url;
      }

      return FreeGameEntry()
        ..offerId = game.id
        ..title = game.title
        ..namespace = game.namespace
        ..thumbnailUrl = thumbnail
        ..startDate = game.giveaway?.startDate
        ..endDate = game.giveaway?.endDate
        ..platforms = ['epic'] // Default to Epic platform
        ..syncedAt = DateTime.now()
        ..notifiedNewGame = false;
    }).toList();
  }

  void _navigateToOffer(BuildContext context, FreeGameEntry game) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MobileOfferDetailPage(
          offerId: game.offerId,
          followService: followService,
          pushService: pushService,
          chatService: chatService,
          settings: settings,
          initialTitle: game.title,
          initialImageUrl: game.thumbnailUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Query for free games with 1-minute stale time and automatic refetch
    final freeGamesQuery = useQuery<List<FreeGameEntry>, Object>(
      queryKey: ['free-games-page'],
      queryFn: (_) => _fetchFreeGames(),
      staleTime: StaleTime(const Duration(minutes: 1)),
      refetchInterval: const Duration(minutes: 1),
    );

    // Extract active and upcoming games
    final allGames = freeGamesQuery.data ?? [];
    final activeGames = useMemoized(
      () => allGames.where((g) => g.isActive).toList(),
      [allGames],
    );
    final upcomingGames = useMemoized(
      () => allGames.where((g) => g.isUpcoming).toList(),
      [allGames],
    );

    return RefreshIndicator(
      onRefresh: () async {
        await freeGamesQuery.refetch();
      },
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.card_giftcard_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Free Games',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Claim free games from Epic Games Store',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (freeGamesQuery.isFetching)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Loading state
          if (freeGamesQuery.isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (freeGamesQuery.isError)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Failed to load free games',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pull down to retry',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Active games section
            if (activeGames.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Available Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${activeGames.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final game = activeGames[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FreeGameCard(
                        game: game,
                        followService: followService,
                        pushService: pushService,
                        isActive: true,
                        onTap: () => _navigateToOffer(context, game),
                      ),
                    );
                  }, childCount: activeGames.length),
                ),
              ),
            ],

            // Upcoming games section
            if (upcomingGames.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Coming Soon',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${upcomingGames.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final game = upcomingGames[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FreeGameCard(
                        game: game,
                        followService: followService,
                        pushService: pushService,
                        isActive: false,
                        onTap: () => _navigateToOffer(context, game),
                      ),
                    );
                  }, childCount: upcomingGames.length),
                ),
              ),
            ],

            // Empty state
            if (activeGames.isEmpty && upcomingGames.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.card_giftcard_rounded,
                        size: 64,
                        color: AppColors.textMuted.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No free games available',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pull down to refresh',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Bottom padding for bottom navigation bar
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ],
      ),
    );
  }
}
