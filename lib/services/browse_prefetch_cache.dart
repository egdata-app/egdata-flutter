import '../models/api/search.dart';

/// Simple in-memory cache for prefetched browse data.
/// Used to avoid loading state on first visit to browse page.
class BrowsePrefetchCache {
  static final BrowsePrefetchCache instance = BrowsePrefetchCache._();

  BrowsePrefetchCache._();

  SearchResponse? _cachedResponse;
  String? _cachedCountry;
  DateTime? _cachedAt;

  /// Cache duration - data is considered stale after this
  static const _cacheDuration = Duration(minutes: 5);

  /// Store prefetched data
  void setData({
    required String country,
    required SearchResponse response,
  }) {
    _cachedResponse = response;
    _cachedCountry = country;
    _cachedAt = DateTime.now();
  }

  /// Get cached data if valid (same country, not expired)
  /// Returns null if cache is invalid or expired
  SearchResponse? getData({required String country}) {
    if (_cachedResponse == null || _cachedCountry != country) {
      return null;
    }

    // Check if cache is still valid
    if (_cachedAt != null) {
      final age = DateTime.now().difference(_cachedAt!);
      if (age > _cacheDuration) {
        // Cache expired, clear it
        clear();
        return null;
      }
    }

    return _cachedResponse;
  }

  /// Consume and clear the cache (one-time use)
  SearchResponse? consumeData({required String country}) {
    final data = getData(country: country);
    if (data != null) {
      clear();
    }
    return data;
  }

  /// Clear the cache
  void clear() {
    _cachedResponse = null;
    _cachedCountry = null;
    _cachedAt = null;
  }
}
