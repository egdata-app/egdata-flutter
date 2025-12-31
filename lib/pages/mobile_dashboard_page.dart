import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../database/database_service.dart';
import '../models/followed_game.dart';
import '../services/api_service.dart';
import '../services/follow_service.dart';
import '../services/sync_service.dart';

class MobileDashboardPage extends StatefulWidget {
  final FollowService followService;
  final SyncService syncService;
  final DatabaseService db;

  const MobileDashboardPage({
    super.key,
    required this.followService,
    required this.syncService,
    required this.db,
  });

  @override
  State<MobileDashboardPage> createState() => _MobileDashboardPageState();
}

class _MobileDashboardPageState extends State<MobileDashboardPage> {
  final ApiService _apiService = ApiService();
  List<FreeGame> _activeFreeGames = [];
  List<FollowedGame> _followedGames = [];
  List<FollowedGameEntry> _gamesOnSale = []; // Use DB entry for price info
  bool _isLoading = true;
  StreamSubscription? _followedSub;

  @override
  void initState() {
    super.initState();
    _loadData();
    _followedSub = widget.followService.followedGamesStream.listen((games) {
      setState(() {
        _followedGames = games;
      });
      _loadGamesOnSale();
    });
  }

  Future<void> _loadGamesOnSale() async {
    final entries = await widget.db.getAllFollowedGames();
    setState(() {
      _gamesOnSale = entries.where((g) => g.isOnSale).toList();
    });
  }

  @override
  void dispose() {
    _followedSub?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final allGames = await _apiService.getFreeGames();
      await widget.followService.loadFollowedGames();
      await _loadGamesOnSale();

      // Filter for active free games (currently within giveaway period)
      final now = DateTime.now();
      final activeGames = allGames.where((g) {
        if (g.giveaway == null) return false;
        return now.isAfter(g.giveaway!.startDate) &&
            now.isBefore(g.giveaway!.endDate);
      }).toList();

      setState(() {
        _activeFreeGames = activeGames;
        _followedGames = widget.followService.followedGames;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openGame(String offerId) async {
    final url = Uri.parse('https://egdata.app/offers/$offerId');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
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

            // Stats row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.card_giftcard_rounded,
                    label: 'Free Games',
                    value: '${_activeFreeGames.length}',
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.favorite_rounded,
                    label: 'Following',
                    value: '${_followedGames.length}',
                    color: AppColors.accentPink,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.local_offer_rounded,
                    label: 'On Sale',
                    value: '${_gamesOnSale.length}',
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Free games section
            if (_activeFreeGames.isNotEmpty) ...[
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
                  itemCount: _activeFreeGames.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final game = _activeFreeGames[index];
                    return _buildFreeGameCard(game);
                  },
                ),
              ),
              const SizedBox(height: 28),
            ],

            // Games on sale section
            if (_gamesOnSale.isNotEmpty) ...[
              _buildSectionHeader(
                'Followed Games On Sale',
                Icons.local_offer_rounded,
                AppColors.warning,
              ),
              const SizedBox(height: 12),
              ..._gamesOnSale
                  .take(5)
                  .map(
                    (game) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildSaleCard(game),
                    ),
                  ),
              const SizedBox(height: 16),
            ],

            // Empty state
            if (_activeFreeGames.isEmpty && _gamesOnSale.isEmpty)
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

  Widget _buildFreeGameCard(FreeGame game) {
    final thumbnailUrl = _getThumbnailUrl(game);
    return GestureDetector(
      onTap: () => _openGame(game.id),
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
                    ? Image.network(
                        thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
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

  Widget _buildSaleCard(FollowedGameEntry game) {
    return GestureDetector(
      onTap: () => _openGame(game.offerId),
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
                    ? Image.network(
                        game.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
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
