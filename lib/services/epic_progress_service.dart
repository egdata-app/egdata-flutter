import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/epic_progress.dart';
import 'epic_auth_service.dart';

typedef EpicProgressProofProbe =
    Future<EpicProgressProofResult> Function(EpicAuthService authService);

class EpicProgressService {
  static const Duration defaultSnapshotStaleAfter = Duration(minutes: 30);
  static const String _libraryHost =
      'library-service.live.use1a.on.epicgames.com';
  static const String _allPlaytimePathPrefix =
      '/library/api/public/playtime/account';
  static const String _storeGraphqlEndpoint =
      'https://store.epicgames.com/graphql';
  static const String _launcherUserAgent =
      'EpicGamesLauncher/18.8.0-44107768+++Portal+Release-Live Windows/10.0.26100.1.256.64bit';
  static const String _playerProductAchievementsQuery = r'''
query playerProfileAchievementsByProductId(
  $epicAccountId: String!
  $productId: String!
) {
  PlayerProfile {
    playerProfile(epicAccountId: $epicAccountId) {
      productAchievements(productId: $productId) {
        __typename
        ... on PlayerProductAchievementsResponseSuccess {
          data {
            epicAccountId
            sandboxId
            totalXP
            totalUnlocked
            achievementSets {
              achievementSetId
              isBase
              totalUnlocked
              totalXP
            }
            playerAwards {
              awardType
              unlockedDateTime
              achievementSetId
            }
            playerAchievements {
              playerAchievement {
                achievementName
                epicAccountId
                progress
                sandboxId
                unlocked
                unlockDate
                XP
                achievementSetId
                isBase
              }
            }
          }
        }
      }
    }
  }
}
''';

  final EpicAuthService authService;
  final EpicProgressProofProbe? proofProbe;
  final http.Client _client;

  EpicProgressProofResult? _cachedProof;
  Map<String, Duration>? _cachedPlaytimeByArtifactId;
  Map<String, EpicGameProgress> _cachedProgressByCatalogItemId = const {};
  Set<String> _cachedCatalogItemIds = const {};
  Set<String> _cachedAchievementCatalogItemIds = const {};
  DateTime? _cachedSnapshotAt;

  EpicProgressService({
    required this.authService,
    this.proofProbe,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<EpicProgressProofResult> verifyOfficialProgressAccess({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedProof != null) return _cachedProof!;

    await authService.loadTokens();
    if (!authService.isAuthenticated) {
      _cachedProof = EpicProgressProofResult.unauthenticated();
      return _cachedProof!;
    }

    final probe = proofProbe;
    if (probe != null) {
      _cachedProof = await probe(authService);
      return _cachedProof!;
    }

    try {
      final playtime = await _fetchAllPlaytimeByArtifactId(
        forceRefresh: forceRefresh,
      );
      _cachedProof =
          EpicProgressProofResult.blockedByMissingAchievementProductProbe(
            playtimeRecords: playtime.length,
          );
    } catch (e) {
      _cachedProof = EpicProgressProofResult.blockedByPlaytimeProbeFailure(
        failure: e.toString(),
      );
    }
    return _cachedProof!;
  }

  Future<EpicProgressSnapshot> loadProgressSnapshot(
    Iterable<String> catalogItemIds, {
    Map<String, String> artifactIdByCatalogItemId = const {},
    Map<String, String> productIdByCatalogItemId = const {},
    int achievementProductLimit = 50,
    bool forceRefresh = false,
    Duration staleAfter = defaultSnapshotStaleAfter,
  }) async {
    await authService.loadTokens();
    if (!authService.isAuthenticated) {
      return EpicProgressSnapshot(
        proof: EpicProgressProofResult.unauthenticated(),
      );
    }

    final catalogIds = catalogItemIds
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (catalogIds.isEmpty) {
      final proof = await verifyOfficialProgressAccess(
        forceRefresh: forceRefresh,
      );
      return EpicProgressSnapshot(proof: proof);
    }

    final cachedSnapshot = _cachedSnapshotFor(
      catalogIds,
      productIdByCatalogItemId: productIdByCatalogItemId,
      achievementProductLimit: achievementProductLimit,
      forceRefresh: forceRefresh,
      staleAfter: staleAfter,
    );
    if (cachedSnapshot != null) return cachedSnapshot;

    Map<String, Duration> playtimeByArtifactId;
    try {
      playtimeByArtifactId = await _fetchAllPlaytimeByArtifactId(
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      return EpicProgressSnapshot(
        proof: EpicProgressProofResult.blockedByPlaytimeProbeFailure(
          failure: e.toString(),
        ),
      );
    }

    final byArtifactLower = playtimeByArtifactId.map(
      (artifactId, playtime) => MapEntry(artifactId.toLowerCase(), playtime),
    );
    final gamesByCatalogItemId = <String, EpicGameProgress>{};
    for (final catalogItemId in catalogIds) {
      final artifactId = artifactIdByCatalogItemId[catalogItemId]?.trim();
      final lookupId = (artifactId == null || artifactId.isEmpty)
          ? catalogItemId
          : artifactId;
      final playtime = byArtifactLower[lookupId.toLowerCase()];
      if (playtime == null) continue;
      gamesByCatalogItemId[catalogItemId] = EpicGameProgress(
        catalogItemId: catalogItemId,
        artifactId: lookupId,
        officialPlaytime: playtime,
        syncedAt: DateTime.now(),
      );
    }

    EpicProgressProofResult proof =
        EpicProgressProofResult.blockedByMissingAchievementProductProbe(
          playtimeRecords: playtimeByArtifactId.length,
        );
    final productEntries = productIdByCatalogItemId.entries
        .where((entry) => catalogIds.contains(entry.key))
        .where((entry) => entry.value.trim().isNotEmpty)
        .take(achievementProductLimit)
        .toList(growable: false);

    if (productEntries.isNotEmpty) {
      var checked = 0;
      var withData = 0;
      try {
        for (final entry in productEntries) {
          checked++;
          final achievementProgress = await _fetchPlayerProductAchievements(
            catalogItemId: entry.key,
            productId: entry.value.trim(),
          );
          if (achievementProgress == null) continue;
          withData++;
          final existing = gamesByCatalogItemId[entry.key];
          gamesByCatalogItemId[entry.key] = EpicGameProgress(
            catalogItemId: entry.key,
            artifactId: existing?.artifactId,
            productId: achievementProgress.productId,
            officialPlaytime: existing?.officialPlaytime,
            unlockedAchievements: achievementProgress.unlockedAchievements,
            totalAchievements: achievementProgress.totalAchievements,
            achievementPercent: achievementProgress.achievementPercent,
            syncedAt: DateTime.now(),
          );
        }
        proof = EpicProgressProofResult.available(
          playtimeRecords: playtimeByArtifactId.length,
          achievementProductsChecked: checked,
          achievementProductsWithData: withData,
        );
      } catch (e) {
        proof = EpicProgressProofResult.blockedByAchievementProbeFailure(
          playtimeRecords: playtimeByArtifactId.length,
          failure: e.toString(),
        );
      }
    }

    _cachedProof = proof;
    _cachedSnapshotAt = DateTime.now();
    _cachedCatalogItemIds = {..._cachedCatalogItemIds, ...catalogIds};
    _cachedAchievementCatalogItemIds = {
      ..._cachedAchievementCatalogItemIds,
      ...productEntries.map((entry) => entry.key),
    };
    _cachedProgressByCatalogItemId = {
      ..._cachedProgressByCatalogItemId,
      ...gamesByCatalogItemId,
    };
    return EpicProgressSnapshot(
      proof: proof,
      gamesByCatalogItemId: gamesByCatalogItemId,
    );
  }

  EpicProgressSnapshot? _cachedSnapshotFor(
    List<String> catalogIds, {
    required Map<String, String> productIdByCatalogItemId,
    required int achievementProductLimit,
    required bool forceRefresh,
    required Duration staleAfter,
  }) {
    if (forceRefresh) return null;
    final cachedAt = _cachedSnapshotAt;
    final proof = _cachedProof;
    if (cachedAt == null || proof == null) return null;
    if (DateTime.now().difference(cachedAt) > staleAfter) return null;

    final requestedCatalogIds = catalogIds.toSet();
    if (!_cachedCatalogItemIds.containsAll(requestedCatalogIds)) {
      return null;
    }

    if (achievementProductLimit > 0) {
      final requestedAchievementIds = productIdByCatalogItemId.entries
          .where((entry) => requestedCatalogIds.contains(entry.key))
          .where((entry) => entry.value.trim().isNotEmpty)
          .take(achievementProductLimit)
          .map((entry) => entry.key)
          .toSet();
      if (!_cachedAchievementCatalogItemIds.containsAll(
        requestedAchievementIds,
      )) {
        return null;
      }
    }

    return EpicProgressSnapshot(
      proof: proof,
      gamesByCatalogItemId: {
        for (final id in requestedCatalogIds)
          if (_cachedProgressByCatalogItemId[id] != null)
            id: _cachedProgressByCatalogItemId[id]!,
      },
    );
  }

  Future<Map<String, Duration>> _fetchAllPlaytimeByArtifactId({
    bool forceRefresh = false,
  }) async {
    final cached = _cachedPlaytimeByArtifactId;
    if (!forceRefresh && cached != null) return cached;

    final accountId = authService.accountId;
    final token = authService.accessToken;
    if (accountId == null || accountId.isEmpty || token == null) {
      throw StateError('Epic account token is missing');
    }

    final uri = Uri.https(
      _libraryHost,
      '$_allPlaytimePathPrefix/$accountId/all',
    );

    var response = await _getWithBearer(uri);
    if (response.statusCode == 401) {
      final refreshed = await authService.refreshTokens();
      if (!refreshed) throw StateError('Epic session expired');
      response = await _getWithBearer(uri);
    }

    if (response.statusCode != 200) {
      throw StateError(
        'LibraryService playtime returned ${response.statusCode}: ${response.body}',
      );
    }

    final body = jsonDecode(response.body);
    if (body is! List) {
      throw StateError('LibraryService playtime returned an unexpected body');
    }

    final result = <String, Duration>{};
    for (final raw in body) {
      if (raw is! Map<String, dynamic>) continue;
      final artifactId = (raw['artifactId'] as String?)?.trim();
      final totalTime = raw['totalTime'];
      if (artifactId == null || artifactId.isEmpty) continue;
      final seconds = switch (totalTime) {
        int value => value,
        double value => value.round(),
        String value => int.tryParse(value),
        _ => null,
      };
      if (seconds == null) continue;
      result[artifactId] = Duration(seconds: seconds);
    }

    _cachedPlaytimeByArtifactId = result;
    return result;
  }

  Future<http.Response> _getWithBearer(Uri uri) {
    return _client.get(
      uri,
      headers: {
        'Authorization': 'Bearer ${authService.accessToken}',
        'User-Agent': _launcherUserAgent,
      },
    );
  }

  Future<EpicGameProgress?> _fetchPlayerProductAchievements({
    required String catalogItemId,
    required String productId,
  }) async {
    final accountId = authService.accountId;
    if (accountId == null || accountId.isEmpty) {
      throw StateError('Epic account id is missing');
    }

    var response = await _postGraphql(
      query: _playerProductAchievementsQuery,
      variables: {'epicAccountId': accountId, 'productId': productId},
    );

    if (response.statusCode == 401) {
      final refreshed = await authService.refreshTokens();
      if (!refreshed) throw StateError('Epic session expired');
      response = await _postGraphql(
        query: _playerProductAchievementsQuery,
        variables: {'epicAccountId': accountId, 'productId': productId},
      );
    }

    if (response.statusCode != 200) {
      throw StateError(
        'Epic Store GraphQL achievements returned ${response.statusCode}: ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('Epic Store GraphQL returned an unexpected body');
    }
    final errors = decoded['errors'];
    if (errors is List && errors.isNotEmpty) {
      throw StateError('Epic Store GraphQL achievements errors: $errors');
    }

    final productAchievements = _readMap(decoded, const [
      'data',
      'PlayerProfile',
      'playerProfile',
      'productAchievements',
    ]);
    final data = productAchievements?['data'];
    if (data is! Map<String, dynamic>) return null;

    final playerAchievements = data['playerAchievements'];
    final totalAchievements = playerAchievements is List
        ? playerAchievements.length
        : null;
    final totalUnlocked = data['totalUnlocked'] is num
        ? (data['totalUnlocked'] as num).toInt()
        : null;
    final achievementPercent =
        totalAchievements != null &&
            totalAchievements > 0 &&
            totalUnlocked != null
        ? totalUnlocked / totalAchievements
        : null;

    return EpicGameProgress(
      catalogItemId: catalogItemId,
      productId: productId,
      unlockedAchievements: totalUnlocked,
      totalAchievements: totalAchievements,
      achievementPercent: achievementPercent,
      syncedAt: DateTime.now(),
    );
  }

  Future<http.Response> _postGraphql({
    required String query,
    required Map<String, String> variables,
  }) {
    return _client.post(
      Uri.parse(_storeGraphqlEndpoint),
      headers: {
        'Authorization': 'Bearer ${authService.accessToken}',
        'Content-Type': 'application/json',
        'User-Agent': _launcherUserAgent,
      },
      body: jsonEncode({'query': query, 'variables': variables}),
    );
  }

  Map<String, dynamic>? _readMap(Map<String, dynamic> root, List<String> path) {
    Object? current = root;
    for (final segment in path) {
      if (current is! Map<String, dynamic>) return null;
      current = current[segment];
    }
    return current is Map<String, dynamic> ? current : null;
  }
}
