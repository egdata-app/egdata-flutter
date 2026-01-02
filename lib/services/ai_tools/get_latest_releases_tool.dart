import 'package:langchain/langchain.dart';
import '../api_service.dart';

/// Create get_latest_releases tool
Tool createGetLatestReleasesTool(ApiService apiService, String country) {
  return Tool.fromFunction<Map<String, dynamic>, Map<String, dynamic>>(
    name: 'get_latest_releases',
    description: 'Get recently released games.',
    inputJsonSchema: <String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{
        'limit': <String, dynamic>{
          'type': 'integer',
          'description': 'Number of results per page',
        },
      },
    },
    func: (toolInput) async => await getLatestReleases(apiService, country, toolInput),
  );
}

/// Implement get_latest_releases
Future<Map<String, dynamic>> getLatestReleases(
  ApiService apiService,
  String country,
  Map<String, dynamic> args,
) async {
  try {
    final limit = (args['limit'] as num?)?.toInt() ?? 10;

    // Use search API sorted by release date
    final searchRequest = SearchRequest(
      offerType: SearchOfferType.baseGame,
      sortBy: SearchSortBy.releaseDate,
      sortDir: SearchSortDir.desc,
      limit: limit,
    );

    final result = await apiService.search(searchRequest, country: country);

    return {
      'games': result.offers
          .map(
            (offer) => {
              'offerId': offer.id,
              'title': offer.title,
              'releaseDate': offer.releaseDate?.toIso8601String(),
            },
          )
          .toList(),
    };
  } catch (e) {
    return {'error': e.toString(), 'games': []};
  }
}
