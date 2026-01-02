import 'package:flutter/material.dart';
import '../main.dart';
import '../models/api/offer_ratings.dart';
import '../models/api/offer_tops.dart';

class OfferRatingsCard extends StatelessWidget {
  final OfferRatings? ratings;
  final OfferTops? tops;

  const OfferRatingsCard({super.key, this.ratings, this.tops});

  /// Check if there's any data to display
  bool get hasData =>
      (ratings != null && ratings!.recommendPercentage != null) ||
      (tops != null && tops!.hasRankings);

  @override
  Widget build(BuildContext context) {
    // Don't show card if there's no data
    if (!hasData) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Critic Ratings (if available)
          if (ratings?.recommendPercentage != null) ...[
            _buildCriticRating(),
            if (tops?.hasRankings == true) const SizedBox(height: 16),
          ],

          // Top Rankings (if available)
          if (tops?.hasRankings == true) _buildTopRankings(),
        ],
      ),
    );
  }

  Widget _buildCriticRating() {
    final percentage = ratings!.recommendPercentage!;
    final criticAverage = ratings!.criticAverage;
    final criticRating = ratings!.criticRating;
    final reviewCount = ratings!.reviews?.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Critic average score and rating text
        if (criticAverage != null) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$criticAverage',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (criticRating != null)
                      Text(
                        criticRating,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    const Text(
                      'Critic Score',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // Recommendation percentage
        Row(
          children: [
            Text(
              '$percentage%',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                height: 1.0,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Critics Recommend',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 6,
            backgroundColor: AppColors.surfaceLight,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        const SizedBox(height: 6),

        // Review count and OpenCritic link
        Text(
          'Based on $reviewCount critic ${reviewCount == 1 ? 'review' : 'reviews'}',
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildTopRankings() {
    final sortedRankings = tops!.sortedRankings;
    // Show top 3 rankings only to keep card compact
    final displayRankings = sortedRankings.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "Top Rankings" label if we're also showing critic rating
        if (ratings?.recommendPercentage != null) ...[
          const Text(
            'Top Rankings',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Rankings list
        ...displayRankings.map((entry) {
          final collectionName = tops!.getCollectionName(entry.key);
          final position = entry.value; // Already 1-indexed (1 = first place)

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                // Trophy icon with color based on position
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _getRankColor(position).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.emoji_events_rounded,
                    size: 16,
                    color: _getRankColor(position),
                  ),
                ),
                const SizedBox(width: 10),

                // Ranking text
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      children: [
                        TextSpan(
                          text: '#$position ',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextSpan(text: 'in $collectionName'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),

        // Show "and X more" if there are additional rankings
        if (sortedRankings.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '+${sortedRankings.length - 3} more ranking${sortedRankings.length - 3 == 1 ? '' : 's'}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }

  /// Get trophy color based on ranking position (1-indexed: 1 = first place)
  Color _getRankColor(int position) {
    if (position == 1) return const Color(0xFFFFD700); // Gold
    if (position <= 3) return const Color(0xFFC0C0C0); // Silver
    if (position <= 10) return const Color(0xFFCD7F32); // Bronze
    return AppColors.primary; // Default cyan
  }
}
