import 'package:langchain/langchain.dart';
import '../api_service.dart';

/// Create search_sellers tool
Tool createSearchSellersTool(ApiService apiService, String country) {
  return Tool.fromFunction<Map<String, dynamic>, Map<String, dynamic>>(
    name: 'search_sellers',
    description:
        'Find publishers/developers by name to get seller IDs for filtering.',
    inputJsonSchema: <String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{
        'query': <String, dynamic>{
          'type': 'string',
          'description': 'Publisher or developer name to search for',
        },
      },
      'required': ['query'],
    },
    func: (toolInput) async => await searchSellers(apiService, country, toolInput),
  );
}

/// Implement search_sellers
Future<Map<String, dynamic>> searchSellers(
  ApiService apiService,
  String country,
  Map<String, dynamic> args,
) async {
  try {
    final query = args['query'] as String;

    // Search for games by this seller/publisher
    final searchRequest = SearchRequest(title: query, limit: 10);

    final result = await apiService.search(searchRequest, country: country);

    // Extract unique sellers from results
    final sellersMap = <String, String>{};
    for (final offer in result.offers) {
      if (offer.seller != null) {
        sellersMap[offer.seller!.id] = offer.seller!.name;
      }
    }

    return {
      'sellers': sellersMap.entries
          .map((entry) => {'sellerId': entry.key, 'name': entry.value})
          .toList(),
    };
  } catch (e) {
    return {'error': e.toString(), 'sellers': []};
  }
}
