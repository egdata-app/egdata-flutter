import 'package:flutter/material.dart';
import '../main.dart';
import '../database/database_service.dart';
import '../models/settings.dart';
import '../services/follow_service.dart';
import '../services/push_service.dart';
import '../services/sync_service.dart';
import '../widgets/free_game_card.dart';
import 'mobile_offer_detail_page.dart';

class FreeGamesPage extends StatefulWidget {
  final FollowService followService;
  final SyncService syncService;
  final DatabaseService db;
  final PushService? pushService;

  const FreeGamesPage({
    super.key,
    required this.followService,
    required this.syncService,
    required this.db,
    this.pushService,
  });

  @override
  State<FreeGamesPage> createState() => _FreeGamesPageState();
}

class _FreeGamesPageState extends State<FreeGamesPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<FreeGameEntry> _activeGames = [];
  List<FreeGameEntry> _upcomingGames = [];
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadFreeGames();
  }

  Future<void> _loadFreeGames() async {
    setState(() => _isLoading = true);
    try {
      final allGames = await widget.db.getAllFreeGames();
      setState(() {
        _activeGames = allGames.where((g) => g.isActive).toList();
        _upcomingGames = allGames.where((g) => g.isUpcoming).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);
    try {
      // Use performSync to sync free games from the API
      await widget.syncService.performSync(
        AppSettings(), // Use default settings for sync
      );
      await _loadFreeGames();
    } finally {
      setState(() => _isRefreshing = false);
    }
  }

  void _navigateToOffer(FreeGameEntry game) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MobileOfferDetailPage(
          offerId: game.offerId,
          followService: widget.followService,
          pushService: widget.pushService,
          initialTitle: game.title,
          initialImageUrl: game.thumbnailUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return RefreshIndicator(
      onRefresh: _onRefresh,
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
                  if (_isRefreshing)
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
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else ...[
            // Active games section
            if (_activeGames.isNotEmpty) ...[
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
                          '${_activeGames.length}',
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
                    final game = _activeGames[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FreeGameCard(
                        game: game,
                        followService: widget.followService,
                        pushService: widget.pushService,
                        isActive: true,
                        onTap: () => _navigateToOffer(game),
                      ),
                    );
                  }, childCount: _activeGames.length),
                ),
              ),
            ],

            // Upcoming games section
            if (_upcomingGames.isNotEmpty) ...[
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
                          '${_upcomingGames.length}',
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
                    final game = _upcomingGames[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FreeGameCard(
                        game: game,
                        followService: widget.followService,
                        pushService: widget.pushService,
                        isActive: false,
                        onTap: () => _navigateToOffer(game),
                      ),
                    );
                  }, childCount: _upcomingGames.length),
                ),
              ),
            ],

            // Empty state
            if (_activeGames.isEmpty && _upcomingGames.isEmpty)
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

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ],
      ),
    );
  }
}
