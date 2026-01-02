import 'package:langchain/langchain.dart';
import '../api_service.dart';

/// Create get_free_games tool
Tool createGetFreeGamesTool(ApiService apiService) {
  return Tool.fromFunction<Map<String, dynamic>, Map<String, dynamic>>(
    name: 'get_free_games',
    description:
        'Get currently active free game giveaways from Epic Games Store.',
    inputJsonSchema: <String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{},
    },
    func: (toolInput) async => await getFreeGames(apiService),
  );
}

/// Implement get_free_games
Future<Map<String, dynamic>> getFreeGames(ApiService apiService) async {
  try {
    final freeGames = await apiService.getFreeGames();
    final now = DateTime.now();

    final active = freeGames
        .where((g) {
          if (g.giveaway == null) return false;
          return now.isAfter(g.giveaway!.startDate) &&
              now.isBefore(g.giveaway!.endDate);
        })
        .map((game) {
          return {
            'offerId': game.id,
            'title': game.title,
            'description': game.description,
            'startDate': game.giveaway?.startDate.toIso8601String(),
            'endDate': game.giveaway?.endDate.toIso8601String(),
          };
        })
        .toList();

    return {'games': active, 'count': active.length};
  } catch (e) {
    return {'error': e.toString(), 'games': []};
  }
}
