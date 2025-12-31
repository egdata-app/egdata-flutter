import 'api_service.dart';

class GameProcessApiService {
  final ApiService _api;

  GameProcessApiService({ApiService? api}) : _api = api ?? ApiService();

  /// Fetches process names for a game from the items API
  /// Uses /items/{catalogItemId} endpoint to get ProcessNames from customAttributes
  /// Returns list of executable names (e.g., ["game.exe", "launcher.exe"])
  Future<List<String>> fetchProcessNames(String catalogItemId) async {
    try {
      final item = await _api.getItem(catalogItemId);
      return item.processNames;
    } catch (e) {
      return [];
    }
  }
}
