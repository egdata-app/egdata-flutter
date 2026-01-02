import 'package:flutter/material.dart';
import '../main.dart';
import '../models/api/offer.dart';
import '../widgets/progressive_image.dart';

class BaseGameBanner extends StatelessWidget {
  final Offer baseGame;
  final VoidCallback onTap;

  const BaseGameBanner({
    super.key,
    required this.baseGame,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = _getThumbnailUrl();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          // Subtle glow effect
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            // Base game thumbnail
            if (thumbnailUrl != null)
              Container(
                width: 60,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ProgressiveImage(
                    imageUrl: thumbnailUrl,
                    fit: BoxFit.cover,
                    placeholderWidth: 20,
                    finalWidth: 100,
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
                child: const Icon(
                  Icons.videogame_asset_rounded,
                  color: AppColors.textMuted,
                  size: 32,
                ),
              ),
            const SizedBox(width: 12),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Label
                  Row(
                    children: [
                      Icon(
                        Icons.extension_rounded,
                        size: 14,
                        color: AppColors.primary.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Check Base Game',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Base game title
                  Text(
                    baseGame.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Developer
                  if (baseGame.seller?.name != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      baseGame.seller!.name,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Arrow icon
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  String? _getThumbnailUrl() {
    if (baseGame.keyImages.isEmpty) return null;

    // Prefer tall/thumbnail images for the banner
    final preferredTypes = ['DieselGameBoxTall', 'Thumbnail', 'OfferImageTall'];

    for (final type in preferredTypes) {
      final img = baseGame.keyImages.where((i) => i.type == type).firstOrNull;
      if (img != null) return img.url;
    }

    // Fallback to first available image
    return baseGame.keyImages.first.url;
  }
}
