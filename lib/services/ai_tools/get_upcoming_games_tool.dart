import 'package:langchain/langchain.dart';
import '../api_service.dart';

/// Create get_upcoming_games tool
Tool createGetUpcomingGamesTool(ApiService apiService, String country) {
  return Tool.fromFunction<Map<String, dynamic>, Map<String, dynamic>>(
    name: 'get_upcoming_games',
    description: 'Get upcoming game releases with release dates.',
    inputJsonSchema: <String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{
        'limit': <String, dynamic>{
          'type': 'integer',
          'description': 'Number of results per page',
        },
      },
    },
    func: (toolInput) async => await getUpcomingGames(apiService, country, toolInput),
  );
}

/// Implement get_upcoming_games
Future<Map<String, dynamic>> getUpcomingGames(
  ApiService apiService,
  String country,
  Map<String, dynamic> args,
) async {
  try {
    final limit = (args['limit'] as num?)?.toInt() ?? 10;

    // Use search API with upcoming sort
    final searchRequest = SearchRequest(
      offerType: SearchOfferType.baseGame,
      sortBy: SearchSortBy.upcoming,
      sortDir: SearchSortDir.asc,
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
