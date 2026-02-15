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
      return p.join(
        home,
        'Library',
        'Application Support',
        'Epic',
        'EpicGamesLauncher',
        'Data',
        'Manifests',
      );
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
    final user =
        Platform.environment['USER'] ?? Platform.environment['LOGNAME'];
    if (user != null && user.isNotEmpty) {
      return '/Users/$user';
    }

    // Last resort fallback
    throw UnsupportedError('Could not determine home directory on macOS');
  }

  Future<List<GameInfo>> scanGames({bool groupByMainGame = true}) async {
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

    if (!groupByMainGame) {
      return games;
    }

    return groupGamesByMainGame(games);
  }

  static List<GameInfo> groupGamesByMainGame(List<GameInfo> games) {
    if (games.isEmpty) return [];

    final grouped = <String, GameInfo>{};
    for (final game in games) {
      final groupKey = _buildGroupKey(game);
      final existing = grouped[groupKey];
      if (existing == null || _isBetterRepresentative(game, existing)) {
        grouped[groupKey] = game;
      }
    }

    final result = grouped.values.toList();
    result.sort(
      (a, b) =>
          a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
    );
    return result;
  }

  static String _buildGroupKey(GameInfo game) {
    final mainCatalogItemId = game.mainGameCatalogItemId.trim();
    final mainCatalogNamespace = game.mainGameCatalogNamespace.trim();
    final mainAppName = game.mainGameAppName.trim();

    if (mainCatalogItemId.isNotEmpty) {
      return 'main:${mainCatalogNamespace.toLowerCase()}:${mainCatalogItemId.toLowerCase()}:${mainAppName.toLowerCase()}';
    }

    final catalogItemId = game.catalogItemId.trim();
    final catalogNamespace = game.catalogNamespace.trim();
    if (catalogItemId.isNotEmpty) {
      return 'catalog:${catalogNamespace.toLowerCase()}:${catalogItemId.toLowerCase()}';
    }

    final installLocation = game.installLocation.trim();
    if (installLocation.isNotEmpty) {
      return 'path:${installLocation.toLowerCase().replaceAll('/', '\\')}';
    }

    return 'guid:${game.installationGuid.toLowerCase()}';
  }

  static bool _isBetterRepresentative(
    GameInfo candidate,
    GameInfo currentBest,
  ) {
    final candidateIsMainGame = _isMainGameEntry(candidate);
    final bestIsMainGame = _isMainGameEntry(currentBest);
    if (candidateIsMainGame != bestIsMainGame) {
      return candidateIsMainGame;
    }

    final candidateHasExecutable =
        candidate.launchExecutable != null &&
        candidate.launchExecutable!.trim().isNotEmpty;
    final bestHasExecutable =
        currentBest.launchExecutable != null &&
        currentBest.launchExecutable!.trim().isNotEmpty;
    if (candidateHasExecutable != bestHasExecutable) {
      return candidateHasExecutable;
    }

    final candidateIsAddon = _isAddonEntry(candidate);
    final bestIsAddon = _isAddonEntry(currentBest);
    if (candidateIsAddon != bestIsAddon) {
      return !candidateIsAddon;
    }

    if (candidate.installSize != currentBest.installSize) {
      return candidate.installSize > currentBest.installSize;
    }

    return candidate.displayName.toLowerCase().compareTo(
          currentBest.displayName.toLowerCase(),
        ) <
        0;
  }

  static bool _isMainGameEntry(GameInfo game) {
    final mainCatalogItemId = game.mainGameCatalogItemId.trim();
    final mainAppName = game.mainGameAppName.trim();

    final catalogMatches =
        mainCatalogItemId.isNotEmpty &&
        game.catalogItemId.trim() == mainCatalogItemId;
    final appMatches =
        mainAppName.isNotEmpty && game.appName.trim() == mainAppName;

    return catalogMatches || appMatches;
  }

  static bool _isAddonEntry(GameInfo game) {
    for (final category in game.appCategories) {
      if (category.toLowerCase() == 'addons') {
        return true;
      }
    }
    return false;
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
        final egstoreDir = Directory(
          p.join(manifest.installLocation, '.egstore'),
        );
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
      mainGameCatalogNamespace: manifest.mainGameCatalogNamespace,
      mainGameCatalogItemId: manifest.mainGameCatalogItemId,
      mainGameAppName: manifest.mainGameAppName,
      appCategories: manifest.appCategories,
      metadata: metadata,
    );
  }

  Future<(String itemContent, List<int> manifestBytes)?> getManifestData(
    String installationGuid,
  ) async {
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
  Future<(String itemContent, List<int> manifestBytes)?>
  getManifestDataFromGame(GameInfo game) async {
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
