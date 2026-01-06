import 'package:flutter/material.dart';
import '../main.dart';
import '../models/api/genre.dart';
import 'progressive_image.dart';

/// A card widget that displays a genre with stacked game cover images
class GenreCard extends StatelessWidget {
  final GenreWithOffers genreWithOffers;
  final VoidCallback? onTap;

  const GenreCard({super.key, required this.genreWithOffers, this.onTap});

  @override
  Widget build(BuildContext context) {
    final offers = genreWithOffers.offers;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stacked images section - takes most of the space
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Center(child: _buildStackedImages(offers)),
              ),
            ),
            // Genre name
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Text(
                genreWithOffers.genre.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStackedImages(List<GenreOffer> offers) {
    if (offers.isEmpty) {
      return _buildPlaceholder();
    }

    // We'll show up to 2 stacked images
    final imagesToShow = offers.take(2).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final availableWidth = constraints.maxWidth;

        // Image sizes relative to available space
        final frontHeight = availableHeight * 0.95;
        final frontWidth = frontHeight * 0.72; // Poster aspect ratio
        final backHeight = availableHeight * 0.85;
        final backWidth = backHeight * 0.72;

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Back image (rotated left, behind)
            if (imagesToShow.length > 1)
              Positioned(
                left: (availableWidth - frontWidth) / 2 - backWidth * 0.35,
                child: Transform.rotate(
                  angle: -0.18,
                  child: _buildImageCard(
                    imagesToShow[1],
                    width: backWidth,
                    height: backHeight,
                  ),
                ),
              ),
            // Front image (rotated right, on top)
            Positioned(
              right: (availableWidth - frontWidth) / 2 - frontWidth * 0.25,
              child: Transform.rotate(
                angle: 0.12,
                child: _buildImageCard(
                  imagesToShow[0],
                  width: frontWidth,
                  height: frontHeight,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImageCard(
    GenreOffer offer, {
    required double width,
    required double height,
  }) {
    final imageUrl = offer.image?.url;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: imageUrl != null
            ? ProgressiveImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholderWidth: 10,
                finalWidth: 200,
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(
          Icons.videogame_asset_rounded,
          color: AppColors.textMuted,
          size: 32,
        ),
      ),
    );
  }
}
