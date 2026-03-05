import 'package:flutter/material.dart';
import '../main.dart';
import '../services/playtime_service.dart';
import '../widgets/playtime_completion_card.dart';
import '../services/api_service.dart';

class PlaytimePage extends StatefulWidget {
  final PlaytimeService? playtimeService;

  const PlaytimePage({super.key, this.playtimeService});

  @override
  State<PlaytimePage> createState() => _PlaytimePageState();
}

class _PlaytimePageState extends State<PlaytimePage> {
  bool _isLoading = true;
  List<_PlaytimeGameData> _games = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.playtimeService == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final playtimes = await widget.playtimeService!.getAllPlaytimeStats();
      if (playtimes.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final uniqueGameIds = playtimes.keys.toList();
      final api = ApiService();
      final validGames = <_PlaytimeGameData>[];

      final namesMap = await widget.playtimeService!.getGameNamesForStats(
        playtimes,
      );
      final thumbnailsMap = await widget.playtimeService!
          .getGameThumbnailsForStats(playtimes);

      for (final id in uniqueGameIds) {
        try {
          final offer = await api.getItemOffer(id).catchError((_) => null);
          OfferIgdb? igdb;
          OfferHltb? hltb;

          if (offer != null) {
            final results = await Future.wait([
              api.getOfferIgdb(offer.id).catchError((_) => null),
              api.getOfferHltb(offer.id).catchError((_) => null),
            ]);
            igdb = results[0] as OfferIgdb?;
            hltb = results[1] as OfferHltb?;
          }

          validGames.add(
            _PlaytimeGameData(
              offerId: id,
              igdb: igdb,
              hltb: hltb,
              gameName: namesMap[id] ?? 'Unknown Game',
              thumbnail: thumbnailsMap[id],
              totalPlaytime: playtimes[id] ?? Duration.zero,
            ),
          );
        } catch (_) {
          // Add basic entry if API fails
          validGames.add(
            _PlaytimeGameData(
              offerId: id,
              gameName: namesMap[id] ?? 'Unknown Game',
              thumbnail: thumbnailsMap[id],
              totalPlaytime: playtimes[id] ?? Duration.zero,
            ),
          );
        }
      }

      // Sort by total playtime descending
      validGames.sort((a, b) => b.totalPlaytime.compareTo(a.totalPlaytime));

      if (mounted) {
        setState(() {
          _games = validGames;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_games.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timer_off_rounded,
              size: 64,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Playtime Data',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Launch a game to start tracking your playtime',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(28, 24, 28, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Playtime & Completion',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Track your progress across all games',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                children: _games.map((game) {
                  return SizedBox(
                    width: _getCardWidth(context),
                    child: _buildGameCard(game),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Account for sidebar and padding
    final availableWidth = screenWidth - 280 - 56;
    if (availableWidth > 1200) return (availableWidth - 48) / 4;
    if (availableWidth > 800) return (availableWidth - 32) / 3;
    if (availableWidth > 400) return (availableWidth - 16) / 2;
    return availableWidth;
  }

  Widget _buildGameCard(_PlaytimeGameData game) {
    bool hasHltbData = false;
    if (game.hltb != null && game.hltb!.gameTimes.isNotEmpty) {
      for (final t in game.hltb!.gameTimes) {
        if (PlaytimeCompletionCard.parseHltbTime(t.time) > 0) {
          hasHltbData = true;
          break;
        }
      }
    }

    final hasCompletionData =
        (game.igdb?.timeToBeat?.normallyHours ?? 0) > 0 || hasHltbData;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (game.thumbnail != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    game.thumbnail!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) =>
                        const Icon(Icons.image, size: 40),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.gameName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (game.totalPlaytime > Duration.zero) ...[
                      const SizedBox(height: 2),
                      Text(
                        _formatDuration(game.totalPlaytime),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (hasCompletionData) ...[
            const SizedBox(height: 20),
            // Minimalist completion info
            PlaytimeCompletionCard(
              offerId: game.offerId,
              igdb: game.igdb,
              hltb: game.hltb,
              playtimeService: widget.playtimeService,
              isStandalone: false,
            ),
          ] else ...[
            const SizedBox(height: 20),
            Text(
              'No completion data found',
              style: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.5),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m played';
    }
    return '${minutes}m played';
  }
}

class _PlaytimeGameData {
  final String offerId;
  final OfferIgdb? igdb;
  final OfferHltb? hltb;
  final String gameName;
  final String? thumbnail;
  final Duration totalPlaytime;

  _PlaytimeGameData({
    required this.offerId,
    this.igdb,
    this.hltb,
    required this.gameName,
    this.thumbnail,
    required this.totalPlaytime,
  });
}
