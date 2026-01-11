/// Utility class for handling Epic Games CDN image URLs with Cloudflare image optimization.
///
/// Uses Cloudflare's image transformation service to optimize images:
/// https://developers.cloudflare.com/images/transform-images/transform-via-url/
class ImageUtils {
  /// Base URL for the Cloudflare CDN proxy
  static const String _cdnBase = 'https://cdn.egdata.app/cdn-cgi/image';

  /// Checks if a URL is from Epic Games CDN
  static bool isEpicCdnUrl(String url) {
    return url.contains('cdn1.epicgames.com') ||
        url.contains('cdn2.epicgames.com') ||
        url.contains('epicgames.com');
  }

  /// Creates an optimized image URL using Cloudflare CDN.
  ///
  /// [url] - The original Epic Games CDN URL
  /// [width] - Target width in pixels (optional)
  /// [height] - Target height in pixels (optional)
  /// [quality] - Image quality 1-100 (default: 85)
  /// [fit] - How to fit the image: 'cover', 'contain', 'scale-down', 'crop', 'pad' (default: 'cover')
  ///
  /// Returns the original URL if it's not from Epic Games CDN.
  static String getOptimizedUrl(
    String url, {
    int? width,
    int? height,
    int quality = 85,
    String fit = 'cover',
  }) {
    if (!isEpicCdnUrl(url)) {
      return url;
    }

    // Build options string
    final options = <String>[];

    if (width != null && width > 0) {
      options.add('width=$width');
    }
    if (height != null && height > 0) {
      options.add('height=$height');
    }
    options.add('quality=$quality');
    options.add('fit=$fit');
    options.add('format=auto'); // Auto-select best format (WebP, AVIF, etc.)

    final optionsString = options.join(',');
    return '$_cdnBase/$optionsString/$url';
  }

  /// Creates a tiny placeholder URL for progressive loading.
  ///
  /// [url] - The original Epic Games CDN URL
  /// [width] - Placeholder width (default: 20px)
  ///
  /// Returns a very small, low-quality version for blur placeholder effect.
  static String getPlaceholderUrl(String url, {int width = 20}) {
    return getOptimizedUrl(
      url,
      width: width,
      quality: 30,
      fit: 'cover',
    );
  }

  /// Creates a thumbnail URL optimized for small displays.
  ///
  /// [url] - The original Epic Games CDN URL
  /// [size] - Target size in pixels (default: 100)
  static String getThumbnailUrl(String url, {int size = 100}) {
    return getOptimizedUrl(
      url,
      width: size,
      height: size,
      quality: 80,
      fit: 'cover',
    );
  }

  /// Creates a card image URL for medium-sized displays.
  ///
  /// [url] - The original Epic Games CDN URL
  /// [width] - Target width (default: 300)
  static String getCardUrl(String url, {int width = 300}) {
    return getOptimizedUrl(
      url,
      width: width,
      quality: 85,
      fit: 'cover',
    );
  }

  /// Creates a hero/banner image URL for large displays.
  ///
  /// [url] - The original Epic Games CDN URL
  /// [width] - Target width (default: 1200)
  static String getHeroUrl(String url, {int width = 1200}) {
    return getOptimizedUrl(
      url,
      width: width,
      quality: 90,
      fit: 'cover',
    );
  }

  /// Creates a full-resolution image URL for detail views/galleries.
  ///
  /// [url] - The original Epic Games CDN URL
  /// [maxWidth] - Maximum width (default: 1920)
  ///
  /// Uses high quality but still applies format optimization.
  static String getFullResUrl(String url, {int maxWidth = 1920}) {
    return getOptimizedUrl(
      url,
      width: maxWidth,
      quality: 95,
      fit: 'scale-down', // Don't upscale, only downscale if larger
    );
  }

  /// Creates an image URL with specific dimensions for a widget.
  ///
  /// Considers device pixel ratio for crisp images on high-DPI displays.
  ///
  /// [url] - The original Epic Games CDN URL
  /// [displayWidth] - The logical width in the UI
  /// [displayHeight] - The logical height in the UI (optional)
  /// [pixelRatio] - Device pixel ratio (default: 2.0 for retina)
  static String getWidgetUrl(
    String url, {
    required int displayWidth,
    int? displayHeight,
    double pixelRatio = 2.0,
  }) {
    final physicalWidth = (displayWidth * pixelRatio).round();
    final physicalHeight =
        displayHeight != null ? (displayHeight * pixelRatio).round() : null;

    return getOptimizedUrl(
      url,
      width: physicalWidth,
      height: physicalHeight,
      quality: 85,
      fit: 'cover',
    );
  }
}
