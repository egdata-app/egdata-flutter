import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/epic_manifest.dart';
import '../models/game_info.dart';
import '../models/manifest_health_issue.dart';
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

  ManifestHealthReport analyzeManifestHealth(List<GameInfo> allGames) {
    final issues = <ManifestHealthIssue>[];

    final byInstallPath = <String, List<GameInfo>>{};
    for (final game in allGames) {
      final key = game.installLocation.toLowerCase().replaceAll('/', '\\');
      byInstallPath.putIfAbsent(key, () => []).add(game);
    }

    for (final entry in byInstallPath.entries) {
      if (entry.value.length < 2) {
        continue;
      }

      final namespaces = entry.value
          .map((game) {
            final mainNamespace = game.mainGameCatalogNamespace.trim();
            if (mainNamespace.isNotEmpty) {
              return mainNamespace.toLowerCase();
            }
            return game.catalogNamespace.trim().toLowerCase();
          })
          .where((namespace) => namespace.isNotEmpty)
          .toSet();

      // Multiple manifests in one install folder are expected for base game + DLC
      // bundles under the same namespace, so don't flag those as issues.
      if (namespaces.length <= 1 && namespaces.isNotEmpty) {
        continue;
      }

      final hasAddonStyleEntry = entry.value.any(
        (game) =>
            game.mainGameCatalogItemId.trim().isNotEmpty ||
            game.appCategories.any(
              (category) => category.toLowerCase() == 'addons',
            ),
      );

      for (final game in entry.value) {
        issues.add(
          ManifestHealthIssue(
            type: ManifestHealthIssueType.duplicateInstallLocation,
            title: 'Duplicate install location',
            description: hasAddonStyleEntry
                ? '${game.displayName} shares this install folder with ${entry.value.length - 1} other entries. This is often expected for a base game with add-ons.'
                : '${game.displayName} shares this install folder with ${entry.value.length - 1} other manifest entries.',
            installationGuid: game.installationGuid,
          ),
        );
      }
    }

    final baseCatalogIds = allGames
        .map((game) => game.catalogItemId.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    for (final game in allGames) {
      if (game.mainGameCatalogItemId.isNotEmpty &&
          !baseCatalogIds.contains(game.mainGameCatalogItemId.trim())) {
        issues.add(
          ManifestHealthIssue(
            type: ManifestHealthIssueType.orphanAddon,
            title: 'Orphan add-on',
            description:
                '${game.displayName} references a base game that is not currently installed.',
            installationGuid: game.installationGuid,
          ),
        );
      }

      if (game.manifestLocation != null && game.manifestLocation!.isNotEmpty) {
        final exists = File(game.manifestLocation!).existsSync();
        if (!exists) {
          issues.add(
            ManifestHealthIssue(
              type: ManifestHealthIssueType.staleManifestLocation,
              title: 'Stale manifest path',
              description:
                  '${game.displayName} points to a manifest file path that no longer exists.',
              installationGuid: game.installationGuid,
            ),
          );
        }
      }
    }

    return ManifestHealthReport(issues: issues);
  }

  Future<int> autoRepairManifestLocations(List<GameInfo> games) async {
    var repaired = 0;

    for (final game in games) {
      if (game.itemFilePath == null || game.itemFilePath!.isEmpty) {
        continue;
      }

      final itemFile = File(game.itemFilePath!);
      if (!await itemFile.exists()) {
        continue;
      }

      final currentManifestLocation = game.manifestLocation ?? '';
      if (currentManifestLocation.isNotEmpty &&
          await File(currentManifestLocation).exists()) {
        continue;
      }

      final egstoreDir = Directory(p.join(game.installLocation, '.egstore'));
      if (!await egstoreDir.exists()) {
        continue;
      }

      final manifestCandidates = await _findManifestCandidates(egstoreDir);
      if (manifestCandidates.isEmpty) {
        continue;
      }

      final bestCandidate = _selectBestManifestCandidate(
        game,
        manifestCandidates,
      );
      if (bestCandidate == null) {
        continue;
      }

      final content = await itemFile.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      json['ManifestLocation'] = bestCandidate.path;
      await itemFile.writeAsString(jsonEncode(json));
      repaired++;
    }

    return repaired;
  }

  Future<List<File>> _findManifestCandidates(Directory egstoreDir) async {
    final manifestCandidates = <File>[];
    await for (final entity in egstoreDir.list(recursive: true)) {
      if (entity is File && entity.path.toLowerCase().endsWith('.manifest')) {
        manifestCandidates.add(entity);
      }
    }
    return manifestCandidates;
  }

  File? _selectBestManifestCandidate(GameInfo game, List<File> candidates) {
    if (candidates.isEmpty) {
      return null;
    }
    if (candidates.length == 1) {
      return candidates.first;
    }

    final previousName = game.manifestLocation == null
        ? ''
        : p.basename(game.manifestLocation!).toLowerCase();
    if (previousName.isNotEmpty) {
      for (final candidate in candidates) {
        if (p.basename(candidate.path).toLowerCase() == previousName) {
          return candidate;
        }
      }
    }

    final installationGuid = game.installationGuid.toLowerCase();
    if (installationGuid.isNotEmpty) {
      for (final candidate in candidates) {
        if (p
            .basenameWithoutExtension(candidate.path)
            .toLowerCase()
            .contains(installationGuid)) {
          return candidate;
        }
      }
    }

    final appName = game.appName.toLowerCase();
    if (appName.isNotEmpty) {
      for (final candidate in candidates) {
        if (p
            .basenameWithoutExtension(candidate.path)
            .toLowerCase()
            .contains(appName)) {
          return candidate;
        }
      }
    }

    candidates.sort((a, b) {
      final aTime = a.statSync().modified;
      final bTime = b.statSync().modified;
      return bTime.compareTo(aTime);
    });

    return candidates.first;
  }
}
