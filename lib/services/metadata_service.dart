import '../models/game_metadata.dart' as metadata;
import 'api_service.dart';

class MetadataService {
  final ApiService _api;
  final Map<String, metadata.GameMetadata> _cache = {};

  MetadataService({ApiService? api}) : _api = api ?? ApiService();

  Future<metadata.GameMetadata?> fetchMetadata(String catalogItemId) async {
    if (_cache.containsKey(catalogItemId)) {
      return _cache[catalogItemId];
    }

    try {
      final item = await _api.getItem(catalogItemId);

      final result = metadata.GameMetadata(
        id: item.id,
        title: item.title ?? '',
        description: item.description,
        developer: item.developer,
        publisher: item.publisher,
        keyImages: item.keyImages
            .map((img) => metadata.KeyImage(type: img.type, url: img.url))
            .toList(),
      );

      _cache[catalogItemId] = result;
      return result;
    } catch (e) {
      // Failed to fetch metadata
      return null;
    }
  }

  void clearCache() {
    _cache.clear();
  }
}
