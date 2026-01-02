import 'package:langchain/langchain.dart';
import '../api_service.dart';

/// Create get_top_sellers tool
Tool createGetTopSellersTool(ApiService apiService, String country) {
  return Tool.fromFunction<Map<String, dynamic>, Map<String, dynamic>>(
    name: 'get_top_sellers',
    description:
        'Get best-selling games (returns titles and IDs only, use get_offer_price for pricing).',
    inputJsonSchema: <String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{
        'count': <String, dynamic>{
          'type': 'integer',
          'description': 'Number of results (max: 50)',
        },
      },
    },
    func: (toolInput) async => await getTopSellers(apiService, country, toolInput),
  );
}

/// Implement get_top_sellers
Future<Map<String, dynamic>> getTopSellers(
  ApiService apiService,
  String country,
  Map<String, dynamic> args,
) async {
  try {
    final count = (args['count'] as num?)?.toInt() ?? 10;

    // Use search API to get recent popular games
    final searchRequest = SearchRequest(
      offerType: SearchOfferType.baseGame,
      sortBy: SearchSortBy.lastModifiedDate,
      sortDir: SearchSortDir.desc,
      limit: count.clamp(1, 50),
    );

    final result = await apiService.search(searchRequest, country: country);

    return {
      'games': result.offers
          .map((offer) => {'offerId': offer.id, 'title': offer.title})
          .toList(),
    };
  } catch (e) {
    return {'error': e.toString(), 'games': []};
  }
}
