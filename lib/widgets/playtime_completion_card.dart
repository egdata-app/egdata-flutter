import 'package:flutter/material.dart';
import '../models/api/api.dart';
import '../services/playtime_service.dart';
import '../main.dart';

class PlaytimeCompletionCard extends StatelessWidget {
  final String offerId;
  final OfferIgdb? igdb;
  final OfferHltb? hltb;
  final PlaytimeService? playtimeService;
  final bool isStandalone;

  const PlaytimeCompletionCard({
    super.key,
    required this.offerId,
    this.igdb,
    this.hltb,
    this.playtimeService,
    this.isStandalone = true,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Duration>(
      future:
          playtimeService?.getTotalPlaytime(offerId) ??
          Future.value(Duration.zero),
      builder: (context, snapshot) {
        final totalPlaytime = snapshot.data ?? Duration.zero;

        // Skip if no data
        if (igdb == null && hltb == null) {
          return const SizedBox.shrink();
        }

        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isStandalone) ...[
              Row(
                children: [
                  const Icon(
                    Icons.analytics_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Playtime Analytics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (totalPlaytime > Duration.zero) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _formatDuration(totalPlaytime),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
            ],
            _buildCompletionStats(totalPlaytime),
          ],
        );

        if (!isStandalone) return content;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(20),
          child: content,
        );
      },
    );
  }

  Widget _buildCompletionStats(Duration totalPlaytime) {
    final List<Widget> children = [];
    final playtimeHours = totalPlaytime.inMinutes / 60.0;

    // Use IGDB timeToBeat if available, otherwise HLTB
    if (igdb?.timeToBeat != null) {
      final ttb = igdb!.timeToBeat!;
      if (ttb.normallyHours > 0) {
        children.add(
          _buildProgressRow(
            'Main Story',
            playtimeHours,
            ttb.normallyHours,
            Icons.play_circle_outline_rounded,
          ),
        );
      }
      if (ttb.completelyHours > 0) {
        children.add(const SizedBox(height: 16));
        children.add(
          _buildProgressRow(
            'Completionist',
            playtimeHours,
            ttb.completelyHours,
            Icons.stars_rounded,
          ),
        );
      }
    } else if (hltb != null && hltb!.gameTimes.isNotEmpty) {
      for (final time in hltb!.gameTimes) {
        final targetHours = parseHltbTime(time.time);
        if (targetHours > 0) {
          if (children.isNotEmpty) children.add(const SizedBox(height: 16));
          children.add(
            _buildProgressRow(
              time.category,
              playtimeHours,
              targetHours,
              getIconForCategory(time.category),
            ),
          );
        }
      }
    }

    if (children.isEmpty) {
      return const Text(
        'No completion data available for this game yet.',
        style: TextStyle(color: AppColors.textMuted, fontSize: 14),
      );
    }

    return Column(children: children);
  }

  static double parseHltbTime(String timeStr) {
    // Example: "10.5h", "45m", "1h 30m"
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

  static IconData getIconForCategory(String category) {
    category = category.toLowerCase();
    if (category.contains('main')) return Icons.play_circle_outline_rounded;
    if (category.contains('extra')) return Icons.add_circle_outline_rounded;
    if (category.contains('complete')) return Icons.stars_rounded;
    return Icons.timer_outlined;
  }

  Widget _buildProgressRow(
    String label,
    double current,
    double target,
    IconData icon,
  ) {
    final progress = (current / target).clamp(0.0, 1.0);
    final percentage = (progress * 100).toInt();
    final isCompleted = progress >= 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              '${target.toStringAsFixed(1)}h',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              height: 6,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            if (current > 0)
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isCompleted
                          ? [
                              AppColors.success,
                              AppColors.success.withValues(alpha: 0.7),
                            ]
                          : [
                              AppColors.primary,
                              AppColors.primary.withValues(alpha: 0.7),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isCompleted ? 'Completed!' : '$percentage% completed',
              style: TextStyle(
                color: isCompleted ? AppColors.success : AppColors.textMuted,
                fontSize: 10,
                fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (!isCompleted && target > current)
              Text(
                '~${(target - current).toStringAsFixed(1)}h left',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m total';
    }
    return '${minutes}m total';
  }
}
