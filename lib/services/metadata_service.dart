import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/game_metadata.dart';

class MetadataService {
  static const String _baseUrl = 'https://api.egdata.app';
  final Map<String, GameMetadata> _cache = {};

  Future<GameMetadata?> fetchMetadata(String catalogItemId) async {
    if (_cache.containsKey(catalogItemId)) {
      return _cache[catalogItemId];
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/items/$catalogItemId'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final metadata = GameMetadata.fromJson(json);
        _cache[catalogItemId] = metadata;
        return metadata;
      }
    } catch (e) {
      // Failed to fetch metadata
    }

    return null;
  }

  void clearCache() {
    _cache.clear();
  }
}
