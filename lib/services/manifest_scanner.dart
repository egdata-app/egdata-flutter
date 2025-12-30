import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/epic_manifest.dart';
import '../models/game_info.dart';
import '../models/game_metadata.dart';
import 'metadata_service.dart';

class ManifestScanner {
  final MetadataService _metadataService = MetadataService();

  String getManifestsPath() {
    if (Platform.isWindows) {
      return r'C:\ProgramData\Epic\EpicGamesLauncher\Data\Manifests';
    } else if (Platform.isMacOS) {
      final home = _getMacOSHomeDirectory();
      return p.join(home, 'Library', 'Application Support', 'Epic',
          'EpicGamesLauncher', 'Data', 'Manifests');
    }
    throw UnsupportedError('Platform not supported');
  }

  String _getMacOSHomeDirectory() {
    // Try HOME environment variable first
    final home = Platform.environment['HOME'];
    if (home != null && home.isNotEmpty && home.startsWith('/')) {
      return home;
    }

    // Fallback: use /Users/<username> pattern
    final user = Platform.environment['USER'] ?? Platform.environment['LOGNAME'];
    if (user != null && user.isNotEmpty) {
      return '/Users/$user';
    }

    // Last resort fallback
    throw UnsupportedError('Could not determine home directory on macOS');
  }

  Future<List<GameInfo>> scanGames() async {
    final manifestsPath = getManifestsPath();
    final dir = Directory(manifestsPath);

    if (!await dir.exists()) {
      return [];
    }

    final List<GameInfo> games = [];

    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.item')) {
        try {
          final gameInfo = await _parseManifestFile(entity);
          if (gameInfo != null) {
            games.add(gameInfo);
          }
        } catch (e) {
          // Skip invalid manifest files
        }
      }
    }

    return games;
  }

  Future<GameInfo?> _parseManifestFile(File itemFile) async {
    final content = await itemFile.readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;
    final manifest = EpicGameManifest.fromJson(json);

    // Find corresponding .manifest file to get the hash
    String? manifestHash;
    String? manifestLocation = manifest.manifestLocation;

    // Check if ManifestLocation exists and file is accessible
    if (manifestLocation.isNotEmpty) {
      final manifestFile = File(manifestLocation);
      if (await manifestFile.exists()) {
        manifestHash = p.basenameWithoutExtension(manifestLocation);
      } else {
        // ManifestLocation doesn't exist, try to find .manifest in .egstore folder
        final egstoreDir = Directory(p.join(manifest.installLocation, '.egstore'));
        if (await egstoreDir.exists()) {
          await for (final entity in egstoreDir.list()) {
            if (entity is File && entity.path.endsWith('.manifest')) {
              manifestLocation = entity.path;
              manifestHash = p.basenameWithoutExtension(entity.path);
              break;
            }
          }
        }
      }
    }

    // Fetch metadata
    GameMetadata? metadata;
    if (manifest.catalogItemId.isNotEmpty) {
      metadata = await _metadataService.fetchMetadata(manifest.catalogItemId);
    }

    return GameInfo(
      displayName: manifest.displayName,
      appName: manifest.appName,
      installLocation: manifest.installLocation,
      installSize: manifest.installSize,
      version: manifest.appVersionString,
      catalogNamespace: manifest.catalogNamespace,
      catalogItemId: manifest.catalogItemId,
      installationGuid: manifest.installationGuid,
      manifestHash: manifestHash,
      manifestLocation: manifestLocation,
      itemFilePath: itemFile.path,
      launchExecutable: manifest.launchExecutable.isNotEmpty
          ? manifest.launchExecutable
          : null,
      metadata: metadata,
    );
  }

  Future<(String itemContent, List<int> manifestBytes)?> getManifestData(
      String installationGuid) async {
    final manifestsPath = getManifestsPath();
    final dir = Directory(manifestsPath);

    if (!await dir.exists()) {
      return null;
    }

    // Find the .item file for this game
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.item')) {
        final content = await entity.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;

        if (json['InstallationGuid'] == installationGuid) {
          // Try ManifestLocation first
          String? manifestLocation = json['ManifestLocation'] as String?;
          File? manifestFile;

          if (manifestLocation != null && manifestLocation.isNotEmpty) {
            manifestFile = File(manifestLocation);
            if (!await manifestFile.exists()) {
              manifestFile = null;
            }
          }

          // If ManifestLocation doesn't work, try .egstore folder
          if (manifestFile == null) {
            final installLocation = json['InstallLocation'] as String?;
            if (installLocation != null) {
              final egstoreDir = Directory(p.join(installLocation, '.egstore'));
              if (await egstoreDir.exists()) {
                await for (final egEntity in egstoreDir.list()) {
                  if (egEntity is File && egEntity.path.endsWith('.manifest')) {
                    manifestFile = egEntity;
                    break;
                  }
                }
              }
            }
          }

          if (manifestFile != null && await manifestFile.exists()) {
            final manifestBytes = await manifestFile.readAsBytes();
            return (content, manifestBytes);
          }
        }
      }
    }

    return null;
  }

  /// Get manifest data using pre-stored paths from GameInfo
  Future<(String itemContent, List<int> manifestBytes)?> getManifestDataFromGame(
      GameInfo game) async {
    // Use stored item file path
    if (game.itemFilePath != null) {
      final itemFile = File(game.itemFilePath!);
      if (await itemFile.exists()) {
        final content = await itemFile.readAsString();

        // Use stored manifest location
        if (game.manifestLocation != null) {
          final manifestFile = File(game.manifestLocation!);
          if (await manifestFile.exists()) {
            final manifestBytes = await manifestFile.readAsBytes();
            return (content, manifestBytes);
          }
        }

        // Fallback: search .egstore folder
        final egstoreDir = Directory(p.join(game.installLocation, '.egstore'));
        if (await egstoreDir.exists()) {
          await for (final entity in egstoreDir.list()) {
            if (entity is File && entity.path.endsWith('.manifest')) {
              final manifestBytes = await entity.readAsBytes();
              return (content, manifestBytes);
            }
          }
        }
      }
    }

    // Fallback to old method
    return getManifestData(game.installationGuid);
  }
}
