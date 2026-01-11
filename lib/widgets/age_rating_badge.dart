import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../models/api/age_rating.dart';
import '../utils/image_utils.dart';

class AgeRatingBadge extends StatelessWidget {
  final AgeRatings ageRatings;
  final String? userCountry;

  const AgeRatingBadge({
    super.key,
    required this.ageRatings,
    this.userCountry,
  });

  /// Get the primary rating to display (user's country or first available)
  AgeRating? get primaryRating {
    // Try to get rating based on user's country
    if (userCountry != null) {
      final countryRating = _getRatingForCountry(userCountry!);
      if (countryRating != null) return countryRating;
    }

    // Fallback to first available rating
    if (ageRatings.hasRatings) {
      return ageRatings.ratings.values.first;
    }

    return null;
  }

  /// Get rating for a specific country
  AgeRating? _getRatingForCountry(String country) {
    // Map countries to rating systems
    switch (country.toUpperCase()) {
      case 'US':
      case 'CA':
      case 'MX':
        return ageRatings.getRating('ESRB');
      case 'DE':
        return ageRatings.getRating('USK');
      case 'JP':
        return ageRatings.getRating('CERO');
      case 'KR':
        return ageRatings.getRating('GRAC');
      case 'AU':
      case 'NZ':
        return ageRatings.getRating('ACB');
      case 'BR':
        return ageRatings.getRating('CLASSIND');
      default:
        // European countries use PEGI
        return ageRatings.getRating('PEGI');
    }
  }

  @override
  Widget build(BuildContext context) {
    final rating = primaryRating;
    if (rating == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => _showAllRatings(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rating image
            if (rating.ratingImage != null)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    // 32x32 rating badge
                    imageUrl: ImageUtils.getOptimizedUrl(
                      rating.ratingImage!,
                      width: 64,
                      height: 64,
                      fit: 'contain',
                    ),
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const SizedBox(),
                    errorWidget: (context, url, error) => const SizedBox(),
                  ),
                ),
              )
            else
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    rating.ageControl?.toString() ?? '?',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 8),

            // Rating text
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  rating.compactDisplay,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (rating.ageDisplay != null)
                  Text(
                    rating.ageDisplay!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),

            // Show more icon if multiple ratings
            if (ageRatings.systems.length > 1) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.expand_more_rounded,
                size: 16,
                color: AppColors.textMuted,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAllRatings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _AllRatingsBottomSheet(ageRatings: ageRatings),
    );
  }
}

class _AllRatingsBottomSheet extends StatelessWidget {
  final AgeRatings ageRatings;

  const _AllRatingsBottomSheet({required this.ageRatings});

  @override
  Widget build(BuildContext context) {
    final sortedSystems = ageRatings.systems.toList()
      ..sort((a, b) {
        // Sort by system priority
        const priority = ['ESRB', 'PEGI', 'USK', 'CERO', 'GRAC', 'ACB', 'CLASSIND'];
        final aIndex = priority.indexOf(a);
        final bIndex = priority.indexOf(b);
        if (aIndex != -1 && bIndex != -1) return aIndex.compareTo(bIndex);
        if (aIndex != -1) return -1;
        if (bIndex != -1) return 1;
        return a.compareTo(b);
      });

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
                  Icons.info_outline_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Age Ratings',
                  style: TextStyle(
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

          // Ratings list
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              itemCount: sortedSystems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final system = sortedSystems[index];
                final rating = ageRatings.getRating(system);
                if (rating == null) return const SizedBox.shrink();

                return _buildRatingCard(rating);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard(AgeRating rating) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating image
          if (rating.rectangularRatingImage != null)
            Container(
              width: 60,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  // 60x80 rectangular rating image
                  imageUrl: ImageUtils.getOptimizedUrl(
                    rating.rectangularRatingImage!,
                    width: 120,
                    height: 160,
                    fit: 'contain',
                  ),
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Container(
                    color: AppColors.surfaceLight,
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.surfaceLight,
                    child: const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
              width: 60,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  rating.ageControl?.toString() ?? '?',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 16),

          // Rating info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // System name
                Text(
                  rating.systemDisplayName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),

                // Rating
                Text(
                  rating.compactDisplay,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                // Age display
                if (rating.ageDisplay != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    rating.ageDisplay!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],

                // Descriptor
                if (rating.descriptor != null && rating.descriptor!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      rating.descriptor!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
