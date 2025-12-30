import 'dart:convert';
import 'package:http/http.dart' as http;

class GameProcessApiService {
  static const String _baseUrl = 'https://api.egdata.app';

  /// Fetches process names for a game from the items API
  /// Uses /items/{catalogItemId} endpoint to get ProcessNames from customAttributes
  /// Returns list of executable names (e.g., ["game.exe", "launcher.exe"])
  Future<List<String>> fetchProcessNames(String catalogItemId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/items/$catalogItemId'),
      );

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) return [];

      final processNames = <String>{};

      // Extract from customAttributes
      final customAttributes = data['customAttributes'];
      if (customAttributes != null && customAttributes is List) {
        for (final attr in customAttributes) {
          if (attr is! Map<String, dynamic>) continue;

          final key = attr['key'] as String?;
          final value = attr['value'] as String?;

          if (key == null || value == null || value.isEmpty) continue;

          // ProcessNames, MainWindowProcessName, and BackgroundProcessNames
          if (key == 'ProcessNames' ||
              key == 'MainWindowProcessName' ||
              key == 'BackgroundProcessNames') {
            processNames.addAll(value.split(',').map((s) => s.trim()));
          }
        }
      }

      return processNames.toList();
    } catch (e) {
      return [];
    }
  }
}
