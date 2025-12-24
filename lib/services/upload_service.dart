import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import '../models/upload_status.dart';
import '../models/game_info.dart';
import 'manifest_scanner.dart';

class UploadService {
  static const String _uploadUrl =
      'https://egdata-builds-api.snpm.workers.dev/upload-manifest';

  final ManifestScanner _scanner = ManifestScanner();

  Future<UploadStatus> uploadManifest(GameInfo game) async {
    try {
      // Use the new method that leverages pre-stored paths
      final manifestData = await _scanner.getManifestDataFromGame(game);

      if (manifestData == null) {
        return UploadStatus(
          status: UploadStatusType.failed,
          message: 'Could not find manifest file for ${game.displayName}. '
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
      request.files.add(http.MultipartFile.fromBytes(
        'manifest',
        manifestBytes,
        filename: '${game.installationGuid}.manifest',
        contentType: MediaType('application', 'octet-stream'),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
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
    void Function(String gameName, UploadStatus status)? onProgress,
  }) async {
    final results = <String, UploadStatus>{};

    for (final game in games) {
      final status = await uploadManifest(game);
      results[game.installationGuid] = status;
      onProgress?.call(game.displayName, status);
    }

    return results;
  }
}
