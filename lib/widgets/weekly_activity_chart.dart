import 'package:flutter/material.dart';
import '../main.dart';

class WeeklyActivityChart extends StatelessWidget {
  final Map<String, Duration> playtimeByGame;
  final Map<String, String> gameNames;
  final Map<String, String?> gameThumbnails;

  const WeeklyActivityChart({
    super.key,
    required this.playtimeByGame,
    required this.gameNames,
    required this.gameThumbnails,
  });

  @override
  Widget build(BuildContext context) {
    if (playtimeByGame.isEmpty) {
      return _buildEmptyState();
    }

    // Sort by playtime descending and take top 5
    final sortedEntries = playtimeByGame.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topGames = sortedEntries.take(5).toList();

    // Find max playtime for scaling
    final maxPlaytime = topGames.first.value.inMinutes.toDouble();
    if (maxPlaytime == 0) return _buildEmptyState();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: topGames.map((entry) {
          final gameId = entry.key;
          final duration = entry.value;
          final gameName = gameNames[gameId] ?? 'Unknown';
          final thumbnail = gameThumbnails[gameId];
          final barWidthPercent = duration.inMinutes / maxPlaytime;

          return Padding(
            padding: EdgeInsets.only(
              bottom: entry != topGames.last ? 12 : 0,
            ),
            child: _buildGameBar(
              gameName: gameName,
              thumbnail: thumbnail,
              duration: duration,
              barWidthPercent: barWidthPercent,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGameBar({
    required String gameName,
    String? thumbnail,
    required Duration duration,
    required double barWidthPercent,
  }) {
    return Row(
      children: [
        // Thumbnail
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(4),
          ),
          clipBehavior: Clip.antiAlias,
          child: thumbnail != null
              ? Image.network(
                  thumbnail,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.games_rounded,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                )
              : const Icon(
                  Icons.games_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
        ),
        const SizedBox(width: 12),
        // Game name and bar
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      gameName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDuration(duration),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Progress bar
              LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      // Background
                      Container(
                        height: 8,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      // Fill
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                        height: 8,
                        width: constraints.maxWidth * barWidthPercent,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primaryLight,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 32,
              color: AppColors.textMuted,
            ),
            SizedBox(height: 8),
            Text(
              'No playtime data yet',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Play some games to see your weekly activity',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
