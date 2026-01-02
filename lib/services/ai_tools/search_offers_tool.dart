import 'package:langchain/langchain.dart';
import '../api_service.dart';

/// Create search_offers tool
Tool createSearchOffersTool(ApiService apiService, String country) {
  return Tool.fromFunction<Map<String, dynamic>, Map<String, dynamic>>(
    name: 'search_offers',
    description:
        'Search games with filters (offerType, seller, tags, price range, discounts). Returns game titles and IDs.',
    inputJsonSchema: <String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{
        'query': <String, dynamic>{
          'type': 'string',
          'description': 'Search query for game titles',
        },
        'offerType': <String, dynamic>{
          'type': 'string',
          'description': 'Type: BASE_GAME, DLC, BUNDLE, EDITION, DEMO, etc.',
        },
        'tags': <String, dynamic>{
          'type': 'array',
          'items': <String, dynamic>{'type': 'string'},
          'description': 'Genre/category tags (e.g., ["RPG", "Action"])',
        },
        'onSale': <String, dynamic>{
          'type': 'boolean',
          'description': 'Filter for games currently on sale',
        },
        'priceMin': <String, dynamic>{
          'type': 'integer',
          'description': 'Minimum price in cents (e.g., 1000 for \$10)',
        },
        'priceMax': <String, dynamic>{
          'type': 'integer',
          'description': 'Maximum price in cents (e.g., 2000 for \$20)',
        },
        'limit': <String, dynamic>{
          'type': 'integer',
          'description': 'Max results (default: 10, max: 10)',
        },
      },
    },
    func: (toolInput) async => await searchOffers(apiService, country, toolInput),
  );
}

/// Implement search_offers
Future<Map<String, dynamic>> searchOffers(
  ApiService apiService,
  String country,
  Map<String, dynamic> args,
) async {
  try {
    final query = args['query'] as String?;
    final offerTypeStr = args['offerType'] as String?;
    final onSale = args['onSale'] as bool?;
    final priceMin = args['priceMin'] as num?;
    final priceMax = args['priceMax'] as num?;
    final tagsList = args['tags'] as List?;
    final limit = (args['limit'] as num?)?.toInt() ?? 10;

    SearchOfferType? offerType;
    if (offerTypeStr != null) {
      offerType = SearchOfferType.values.firstWhere(
        (e) => e.value == offerTypeStr,
        orElse: () => SearchOfferType.baseGame,
      );
    }

    List<String>? tags;
    if (tagsList != null && tagsList.isNotEmpty) {
      tags = tagsList.map((e) => e.toString()).toList();
    }

    PriceRange? priceRange;
    if (priceMin != null || priceMax != null) {
      priceRange = PriceRange(min: priceMin?.toInt(), max: priceMax?.toInt());
    }

    final searchRequest = SearchRequest(
      title: query,
      offerType: offerType,
      onSale: onSale,
      price: priceRange,
      tags: tags,
      limit: limit.clamp(1, 10),
      sortBy: onSale == true
          ? SearchSortBy.discountPercent
          : SearchSortBy.lastModifiedDate,
      sortDir: SearchSortDir.desc,
    );

    final searchResponse = await apiService.search(
      searchRequest,
      country: country,
    );

    final results = searchResponse.offers.map((offer) {
      final price = offer.price?.totalPrice;
      final originalPrice = price?.originalPrice ?? 0;
      final discountPrice = price?.discountPrice ?? originalPrice;
      final discount = price?.discountPercent ?? 0;

      return {
        'offerId': offer.id,
        'title': offer.title,
        'offerType': offer.offerType,
        'originalPrice': '\$${(originalPrice / 100).toStringAsFixed(2)}',
        'discountPrice': discountPrice != originalPrice
            ? '\$${(discountPrice / 100).toStringAsFixed(2)}'
            : null,
        'discount': discount,
        'releaseDate': offer.releaseDate?.toIso8601String(),
        'developer': offer.seller?.name,
      };
    }).toList();

    return {
      'results': results,
      'total': searchResponse.total,
      'count': results.length,
    };
  } catch (e) {
    return {'error': e.toString(), 'results': []};
  }
}
