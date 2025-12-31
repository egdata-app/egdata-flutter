import 'dart:convert';
import 'package:http/http.dart' as http;

class SearchResult {
  final String id;
  final String title;
  final String? namespace;
  final String? thumbnailUrl;
  final int? originalPrice;
  final int? discountPrice;
  final String? currencyCode;

  SearchResult({
    required this.id,
    required this.title,
    this.namespace,
    this.thumbnailUrl,
    this.originalPrice,
    this.discountPrice,
    this.currencyCode,
  });

  bool get isOnSale =>
      originalPrice != null &&
      discountPrice != null &&
      discountPrice! < originalPrice!;

  int get discountPercent {
    if (!isOnSale || originalPrice == 0) return 0;
    return ((1 - (discountPrice! / originalPrice!)) * 100).round();
  }

  String get formattedPrice {
    if (discountPrice == null || discountPrice == 0) return 'Free';
    final price = discountPrice! / 100;
    return '\$${price.toStringAsFixed(2)}';
  }

  String get formattedOriginalPrice {
    if (originalPrice == null || originalPrice == 0) return 'Free';
    final price = originalPrice! / 100;
    return '\$${price.toStringAsFixed(2)}';
  }

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    final keyImages = json['keyImages'] as List<dynamic>? ?? [];
    String? thumbnail;

    for (final type in [
      'OfferImageWide',
      'DieselStoreFrontWide',
      'DieselGameBoxTall',
      'Thumbnail'
    ]) {
      final image = keyImages
          .cast<Map<String, dynamic>>()
          .where((img) => img['type'] == type)
          .firstOrNull;
      if (image != null) {
        thumbnail = image['url'] as String?;
        break;
      }
    }
    if (thumbnail == null && keyImages.isNotEmpty) {
      thumbnail = (keyImages.first as Map<String, dynamic>)['url'] as String?;
    }

    final price = json['price'] as Map<String, dynamic>?;
    final totalPrice = price?['totalPrice'] as Map<String, dynamic>?;

    return SearchResult(
      id: json['id'] as String,
      title: json['title'] as String,
      namespace: json['namespace'] as String?,
      thumbnailUrl: thumbnail,
      originalPrice: totalPrice?['originalPrice'] as int?,
      discountPrice: totalPrice?['discountPrice'] as int?,
      currencyCode: totalPrice?['currencyCode'] as String?,
    );
  }
}

class SearchService {
  static const String _baseUrl = 'https://api.egdata.app';
  final http.Client _client;

  // Simple in-memory cache
  final Map<String, List<SearchResult>> _cache = {};
  final Map<String, DateTime> _cacheTime = {};
  static const _cacheDuration = Duration(minutes: 5);

  SearchService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<SearchResult>> searchOffers(String query) async {
    if (query.trim().isEmpty) return [];

    final cacheKey = query.toLowerCase().trim();

    // Check cache
    if (_cache.containsKey(cacheKey)) {
      final cachedTime = _cacheTime[cacheKey];
      if (cachedTime != null &&
          DateTime.now().difference(cachedTime) < _cacheDuration) {
        return _cache[cacheKey]!;
      }
    }

    try {
      final uri = Uri.parse('$_baseUrl/offers/search').replace(
        queryParameters: {'query': query, 'limit': '20'},
      );

      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List<dynamic>? ?? data as List<dynamic>;
        final results = elements
            .cast<Map<String, dynamic>>()
            .map((e) => SearchResult.fromJson(e))
            .toList();

        // Cache results
        _cache[cacheKey] = results;
        _cacheTime[cacheKey] = DateTime.now();

        return results;
      }
    } catch (e) {
      // Search failed, return empty
    }

    return [];
  }

  Future<SearchResult?> getOfferDetails(String offerId) async {
    try {
      final uri = Uri.parse('$_baseUrl/offers/$offerId');
      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return SearchResult.fromJson(data);
      }
    } catch (e) {
      // Failed to get details
    }

    return null;
  }

  void dispose() {
    _client.close();
    _cache.clear();
    _cacheTime.clear();
  }
}
