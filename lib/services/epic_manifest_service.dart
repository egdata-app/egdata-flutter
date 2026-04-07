import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/epic_library_item.dart';
import 'epic_auth_service.dart';

class EpicManifestService {
  final EpicAuthService authService;

  EpicManifestService({required this.authService});

  String _getPlatform() {
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'Mac';
    return 'Windows';
  }

  Future<List<int>?> getManifestForLibraryItem(EpicLibraryItem item) async {
    if (!authService.isAuthenticated) {
      throw Exception('Not authenticated');
    }

    final platform = _getPlatform();
    final url = 'https://launcher-public-service-prod06.ol.epicgames.com/launcher/api/public/assets/v2/platform/$platform/namespace/${item.namespace}/catalogItem/${item.catalogItemId}/app/${item.appName}/label/Live';

    var response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer ${authService.accessToken}',
      },
    );

    if (response.statusCode == 401) {
      final refreshed = await authService.refreshTokens();
      if (refreshed) {
        response = await http.get(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer ${authService.accessToken}',
          },
        );
      } else {
        throw Exception('Session expired');
      }
    }

    if (response.statusCode == 404) {
      // No manifest available for this item (maybe not a game, or no build exists for the platform)
      return null;
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final elements = data['elements'] as List<dynamic>?;
      if (elements == null || elements.isEmpty) return null;

      final firstElement = elements.first as Map<String, dynamic>;
      final manifests = firstElement['manifests'] as List<dynamic>?;
      if (manifests == null || manifests.isEmpty) return null;

      final firstManifest = manifests.first as Map<String, dynamic>;
      final uriString = firstManifest['uri'] as String?;
      if (uriString == null) return null;

      var uri = Uri.parse(uriString);
      final queryParams = firstManifest['queryParams'] as List<dynamic>?;
      
      if (queryParams != null && queryParams.isNotEmpty) {
        final queryParamsMap = <String, String>{};
        for (final param in queryParams) {
          queryParamsMap[param['name']] = param['value'];
        }
        uri = uri.replace(queryParameters: queryParamsMap);
      }

      final downloadResponse = await http.get(uri);
      if (downloadResponse.statusCode == 200) {
        return downloadResponse.bodyBytes;
      } else {
        throw Exception('Failed to download manifest: ${downloadResponse.statusCode}');
      }
    } else {
      throw Exception('Failed to fetch manifest info: ${response.statusCode} - ${response.body}');
    }
  }
}
