import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../main.dart';

/// A progressive image loader that first shows a tiny blurred placeholder,
/// then loads the full-resolution image.
///
/// Uses Epic CDN's resize parameters: ?w={width}&resize=true
class ProgressiveImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  /// Width for the placeholder image (tiny, will be blurred)
  final int placeholderWidth;

  /// Width for the final image (0 = original size)
  final int finalWidth;

  const ProgressiveImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderWidth = 10,
    this.finalWidth = 400,
  });

  /// Adds resize parameters to Epic CDN URLs
  String _getResizedUrl(String url, int targetWidth) {
    if (targetWidth <= 0) return url;

    // Check if it's an Epic CDN URL
    if (!url.contains('epicgames.com')) return url;

    // Remove existing query params and add resize
    final baseUrl = url.split('?').first;
    return '$baseUrl?w=$targetWidth&resize=true';
  }

  @override
  Widget build(BuildContext context) {
    final placeholderUrl = _getResizedUrl(imageUrl, placeholderWidth);
    final finalUrl = _getResizedUrl(imageUrl, finalWidth);

    Widget result = SizedBox.expand(
      child: CachedNetworkImage(
        imageUrl: finalUrl,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 300),
        placeholder: (context, url) => _BlurredPlaceholder(
          imageUrl: placeholderUrl,
          fit: fit,
        ),
        errorWidget: (context, url, error) => _buildErrorPlaceholder(),
      ),
    );

    if (borderRadius != null) {
      result = ClipRRect(borderRadius: borderRadius!, child: result);
    }

    return result;
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: AppColors.surfaceLight,
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

/// Blurred placeholder that loads a tiny version of the image
class _BlurredPlaceholder extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;

  const _BlurredPlaceholder({required this.imageUrl, required this.fit});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background color
        Container(color: AppColors.surfaceLight),
        // Tiny blurred image
        CachedNetworkImage(
          imageUrl: imageUrl,
          fit: fit,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          placeholder: (context, url) => const SizedBox.shrink(),
          errorWidget: (context, url, error) => const SizedBox.shrink(),
          imageBuilder: (context, imageProvider) => ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Image(image: imageProvider, fit: fit),
          ),
        ),
      ],
    );
  }
}
