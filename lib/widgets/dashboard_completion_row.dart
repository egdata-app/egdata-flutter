import 'package:flutter/material.dart';
import '../services/playtime_service.dart';
import '../services/api_service.dart';
import '../main.dart';

class DashboardCompletionRow extends StatefulWidget {
  final PlaytimeService playtimeService;

  const DashboardCompletionRow({super.key, required this.playtimeService});

  @override
  State<DashboardCompletionRow> createState() => _DashboardCompletionRowState();
}

class _DashboardCompletionRowState extends State<DashboardCompletionRow> {
  bool _isLoading = true;
  List<_CompletionGameData> _games = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final sessions = await widget.playtimeService.getRecentSessions(
        limit: 20,
      );
      if (sessions.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final uniqueGameIds = sessions
          .map((s) => s.gameId)
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      final api = ApiService();
      final validGames = <_CompletionGameData>[];

      // Fetch names, thumbnails, and IGDB data
      final namesMap = await widget.playtimeService.getGameNamesForStats({
        for (var id in uniqueGameIds) id: Duration.zero,
      });
      final thumbnailsMap = await widget.playtimeService
          .getGameThumbnailsForStats({
            for (var id in uniqueGameIds) id: Duration.zero,
          });

      for (final id in uniqueGameIds) {
        try {
          // 1. Get the offer for this item
          final offer = await api.getItemOffer(id).catchError((_) => null);
          if (offer == null) continue;

          // 2. Fetch completion data using the offerId
          final results = await Future.wait([
            api.getOfferIgdb(offer.id).catchError((_) => null),
            api.getOfferHltb(offer.id).catchError((_) => null),
          ]);

          final igdb = results[0] as OfferIgdb?;
          final hltb = results[1] as OfferHltb?;

          double targetHours = 0;
          if (igdb?.timeToBeat != null && igdb!.timeToBeat!.normallyHours > 0) {
            targetHours = igdb.timeToBeat!.normallyHours;
          } else if (hltb != null && hltb.gameTimes.isNotEmpty) {
            // Find main story time or first available
            final mainStory = hltb.gameTimes.firstWhere(
              (t) => t.category.toLowerCase().contains('main'),
              orElse: () => hltb.gameTimes.first,
            );
            targetHours = _parseHltbTime(mainStory.time);
          }

          if (targetHours > 0) {
            validGames.add(
              _CompletionGameData(
                offerId: id, // Keep itemId for tracking playtime
                igdb: igdb,
                hltb: hltb,
                targetHours: targetHours,
                gameName: namesMap[id] ?? 'Unknown Game',
                thumbnail: thumbnailsMap[id],
              ),
            );
          }
        } catch (_) {
          // Ignore failures for individual games
        }

        if (validGames.length >= 4) break; // Only need up to 4 valid games
      }

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

  double _parseHltbTime(String timeStr) {
    final regex = RegExp(r'(\d+(\.\d+)?)\s*h');
    final match = regex.firstMatch(timeStr);
    if (match != null) {
      return double.tryParse(match.group(1)!) ?? 0;
    }

    final minRegex = RegExp(r'(\d+)\s*m');
    final minMatch = minRegex.firstMatch(timeStr);
    if (minMatch != null) {
      return (double.tryParse(minMatch.group(1)!) ?? 0) / 60.0;
    }

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Optional: return a shimmer or just shrink while loading
      return const SizedBox.shrink();
    }

    if (_games.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Icon(Icons.flag_rounded, color: AppColors.success, size: 20),
              SizedBox(width: 10),
              Text(
                'Completion Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: _games.map((data) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _GameCompletionCard(
                  data: data,
                  playtimeService: widget.playtimeService,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _CompletionGameData {
  final String offerId;
  final OfferIgdb? igdb;
  final OfferHltb? hltb;
  final double targetHours;
  final String gameName;
  final String? thumbnail;

  _CompletionGameData({
    required this.offerId,
    this.igdb,
    this.hltb,
    required this.targetHours,
    required this.gameName,
    this.thumbnail,
  });
}

class _GameCompletionCard extends StatelessWidget {
  final _CompletionGameData data;
  final PlaytimeService playtimeService;

  const _GameCompletionCard({
    required this.data,
    required this.playtimeService,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Duration>(
      future: playtimeService.getTotalPlaytime(data.offerId),
      builder: (context, snapshot) {
        final total = snapshot.data ?? Duration.zero;
        final currentHours = total.inMinutes / 60.0;
        final targetHours = data.targetHours;
        final progress = (currentHours / targetHours).clamp(0.0, 1.0);
        final isCompleted = progress >= 1.0;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (data.thumbnail != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        data.thumbnail!,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.image, size: 32),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      data.gameName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Main Story',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                  Text(
                    '${targetHours.toStringAsFixed(0)}h',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Stack(
                children: [
                  Container(
                    height: 4,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.success
                            : AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  color: isCompleted
                      ? AppColors.success
                      : AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
