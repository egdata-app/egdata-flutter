import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import '../models/upload_status.dart';
import '../models/game_info.dart';
import '../models/epic_library_item.dart';
import 'analytics_service.dart';
import 'manifest_scanner.dart';
import 'epic_library_service.dart';
import 'epic_manifest_service.dart';

class UploadService {
  static const String _uploadUrl =
      'https://egdata-builds-api.snpm.workers.dev/upload-manifest';

  final ManifestScanner _scanner = ManifestScanner();

  Future<UploadStatus> uploadManifest(GameInfo game) async {
    try {
      // Use the new method that leverages pre-stored paths
      final manifestData = await _scanner.getManifestDataFromGame(game).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException(
          'Reading manifest timed out for ${game.displayName}',
        ),
      );

      if (manifestData == null) {
        return UploadStatus(
          status: UploadStatusType.failed,
          message:
              'Could not find manifest file for ${game.displayName}. '
              'Check if the game is still installed.',
        );
      }

      final (itemContent, manifestBytes) = manifestData;

      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));

      // Add the item JSON as a field
      request.fields['item'] = itemContent;

      // Add OS field
      request.fields['os'] = Platform.isWindows ? 'Windows' : 'Mac';

      // Add manifest file
      request.files.add(
        http.MultipartFile.fromBytes(
          'manifest',
          manifestBytes,
          filename: '${game.installationGuid}.manifest',
          contentType: MediaType('application', 'octet-stream'),
        ),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException(
          'Upload timed out for ${game.displayName}',
        ),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return UploadStatus.fromJson(json);
      } else if (response.statusCode == 409) {
        // 409 Conflict - manifest already exists in the database
        return UploadStatus(
          status: UploadStatusType.alreadyUploaded,
          message: 'Manifest already exists',
          manifestHash: game.manifestHash,
        );
      } else {
        return UploadStatus(
          status: UploadStatusType.failed,
          message: 'Upload failed with status ${response.statusCode}',
        );
      }
    } catch (e) {
      return UploadStatus(
        status: UploadStatusType.failed,
        message: 'Upload error: $e',
      );
    }
  }

  Future<Map<String, UploadStatus>> uploadAllManifests(
    List<GameInfo> games, {
    void Function(GameInfo game, UploadStatus status)? onProgress,
  }) async {
    final results = <String, UploadStatus>{};
    List<GameInfo> gamesToUpload = games;

    // Upload all manifests (including DLC/add-ons), even if the UI list is grouped.
    try {
      gamesToUpload = await _scanner.scanGames(groupByMainGame: false);
    } catch (_) {
      // Fall back to provided list if a full rescan fails.
    }

    for (final game in gamesToUpload) {
      final status = await uploadManifest(game);
      results[game.installationGuid] = status;
      onProgress?.call(game, status);
    }

    // Track upload analytics
    final successCount = results.values
        .where(
          (s) =>
              s.status == UploadStatusType.uploaded ||
              s.status == UploadStatusType.alreadyUploaded,
        )
        .length;
    final success = successCount == results.length;

    if (results.isNotEmpty) {
      await AnalyticsService().logManifestUpload(
        count: results.length,
        success: success,
      );
    }

    return results;
  }

  Future<UploadStatus> uploadCloudManifest(
      EpicLibraryItem item, List<int> manifestBytes) async {
    try {
      final mockItem = {
        'InstallLocation': 'C:\\Program Files\\Epic Games\\${item.appName}',
        'AppName': item.appName,
        'CatalogItemId': item.catalogItemId,
        'CatalogNamespace': item.namespace,
        'InstallationGuid': item.assetId,
        'DisplayName': item.appName,
        'AppVersionString': item.buildVersion ?? '1.0.0',
        'MainGameCatalogNamespace': item.namespace,
        'MainGameCatalogItemId': item.catalogItemId,
        'MainGameAppName': item.appName,
        'AppCategories': ['games']
      };

      final itemContent = jsonEncode(mockItem);

      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));

      request.fields['item'] = itemContent;
      request.fields['os'] = Platform.isWindows ? 'Windows' : 'Mac';

      request.files.add(
        http.MultipartFile.fromBytes(
          'manifest',
          manifestBytes,
          filename: '${item.assetId}.manifest',
          contentType: MediaType('application', 'octet-stream'),
        ),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException(
          'Upload timed out for ${item.appName}',
        ),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return UploadStatus.fromJson(json);
      } else if (response.statusCode == 409) {
        return UploadStatus(
          status: UploadStatusType.alreadyUploaded,
          message: 'Manifest already exists',
        );
      } else {
        return UploadStatus(
          status: UploadStatusType.failed,
          message: 'Upload failed with status ${response.statusCode}',
        );
      }
    } catch (e) {
      return UploadStatus(
        status: UploadStatusType.failed,
        message: 'Upload error: $e',
      );
    }
  }

  Future<Map<String, UploadStatus>> syncCloudLibrary({
    required EpicLibraryService libraryService,
    required EpicManifestService manifestService,
    void Function(EpicLibraryItem item, UploadStatus status)? onProgress,
  }) async {
    final results = <String, UploadStatus>{};

    try {
      final library = await libraryService.getLibrary();

      for (final item in library) {
        try {
          final manifestBytes = await manifestService.getManifestForLibraryItem(item);
          if (manifestBytes != null) {
            final status = await uploadCloudManifest(item, manifestBytes);
            results[item.assetId] = status;
            onProgress?.call(item, status);
          } else {
            final skipStatus = UploadStatus(
              status: UploadStatusType.failed,
              message: 'No cloud manifest found',
            );
            results[item.assetId] = skipStatus;
            onProgress?.call(item, skipStatus);
          }
        } catch (e) {
          final failStatus = UploadStatus(
            status: UploadStatusType.failed,
            message: 'Error processing manifest: $e',
          );
          results[item.assetId] = failStatus;
          onProgress?.call(item, failStatus);
        }
      }

      final successCount = results.values
          .where((s) =>
              s.status == UploadStatusType.uploaded ||
              s.status == UploadStatusType.alreadyUploaded)
          .length;
      final success = successCount > 0 && successCount == results.length;

      if (results.isNotEmpty) {
        await AnalyticsService().logManifestUpload(
          count: results.length,
          success: success,
        );
      }

    } catch (e) {
      print('Cloud sync failed: $e');
    }

    return results;
  }
}
