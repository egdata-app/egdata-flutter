import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/epic_library_item.dart';
import 'epic_auth_service.dart';

/// Reads the user's owned library from Epic.
///
/// Uses the documented `library-service` endpoint (see
/// https://github.com/LeleDerGrasshalmi/FortniteEndpointsDocumentation/blob/main/EpicGames/LibraryService/LibraryItems.md)
/// instead of the legacy launcher assets endpoint, because it supports:
///   - `excludeNs=ue` to drop Unreal Engine assets server-side
///   - `platform` filtering
///   - cursor pagination, so we don't fetch the whole library in one
///     request (Epic caps the library response, and large libraries
///     used to silently truncate)
///   - a `recordType` field that lets us filter out non-APPLICATION
///     records (subscriptions, entitlements without an installable app)
class EpicLibraryService {
  static const String _baseHost = 'library-service.live.use1a.on.epicgames.com';
  static const String _path = '/library/api/public/items';
  static const int _pageLimit = 200;

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
    final items = <EpicLibraryItem>[];
    String? cursor;

    while (true) {
      final params = <String, String>{
        'includeMetadata': 'true',
        'platform': platform,
        'excludeNs': 'ue',
        'limit': '$_pageLimit',
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      };
      final uri = Uri.https(_baseHost, _path, params);

      var response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer ${authService.accessToken}'},
      );

      if (response.statusCode == 401) {
        final refreshed = await authService.refreshTokens();
        if (!refreshed) {
          throw Exception('Session expired');
        }
        response = await http.get(
          uri,
          headers: {'Authorization': 'Bearer ${authService.accessToken}'},
        );
      }

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch library: ${response.statusCode} - ${response.body}',
        );
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final records = body['records'] as List<dynamic>? ?? const [];
      for (final raw in records) {
        if (raw is! Map<String, dynamic>) continue;
        // Skip non-application records (SUBSCRIPTION, etc.) — they have
        // no installable app and just waste a metadata round-trip.
        final recordType =
            (raw['recordType'] as String?)?.toUpperCase() ?? 'APPLICATION';
        if (recordType != 'APPLICATION') continue;

        final appName = (raw['appName'] as String?) ?? '';
        final catalogItemId = (raw['catalogItemId'] as String?) ?? '';
        if (appName.isEmpty || catalogItemId.isEmpty) continue;

        items.add(
          EpicLibraryItem(
            appName: appName,
            title: (raw['title'] as String?) ?? '',
            catalogItemId: catalogItemId,
            namespace: (raw['namespace'] as String?) ?? '',
            // library-service has no `assetId` — use productId as a
            // stable per-account identifier, falling back to appName.
            assetId: (raw['productId'] as String?) ?? appName,
            buildVersion: null,
          ),
        );
      }

      final metadata = body['responseMetadata'] as Map<String, dynamic>?;
      final nextCursor = metadata?['nextCursor'] as String?;
      if (nextCursor == null || nextCursor.isEmpty) break;
      cursor = nextCursor;
    }

    return items;
  }
}
