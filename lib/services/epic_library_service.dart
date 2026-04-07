import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/epic_library_item.dart';
import 'epic_auth_service.dart';

class EpicLibraryService {
  final EpicAuthService authService;

  EpicLibraryService({required this.authService});

  String _getPlatform() {
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'Mac';
    return 'Windows'; // Default fallback
  }

  Future<List<EpicLibraryItem>> getLibrary() async {
    if (!authService.isAuthenticated) {
      throw Exception('Not authenticated');
    }

    final platform = _getPlatform();
    final url = 'https://launcher-public-service-prod06.ol.epicgames.com/launcher/api/public/assets/$platform?label=Live';

    var response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer ${authService.accessToken}',
      },
    );

    if (response.statusCode == 401) {
      // Try to refresh
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

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => EpicLibraryItem.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch library: ${response.statusCode} - ${response.body}');
    }
  }
}
