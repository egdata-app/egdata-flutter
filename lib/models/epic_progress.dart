enum EpicProgressProofStatus { unauthenticated, blocked, available }

class EpicProgressProofResult {
  final EpicProgressProofStatus status;
  final String title;
  final String message;
  final DateTime checkedAt;
  final List<String> evidence;

  const EpicProgressProofResult({
    required this.status,
    required this.title,
    required this.message,
    required this.checkedAt,
    this.evidence = const [],
  });

  bool get isAvailable => status == EpicProgressProofStatus.available;
  bool get isBlocked => status == EpicProgressProofStatus.blocked;
  bool get needsLogin => status == EpicProgressProofStatus.unauthenticated;

  factory EpicProgressProofResult.unauthenticated() {
    return EpicProgressProofResult(
      status: EpicProgressProofStatus.unauthenticated,
      title: 'Epic login required',
      message:
          'Official Epic progress cannot be checked until the user is logged in with Epic Games.',
      checkedAt: DateTime.now(),
    );
  }

  factory EpicProgressProofResult.blockedByMissingOfficialApi() {
    return EpicProgressProofResult(
      status: EpicProgressProofStatus.blocked,
      title: 'Official progress API not proven',
      message:
          'EGData has an Epic account token, but a supported official Epic Store endpoint for launcher playtime or cross-game user achievement progress has not been verified. EOS achievement progress exists through SDK product context, not a general library dashboard API.',
      checkedAt: DateTime.now(),
      evidence: const [
        'EOS_Achievements_QueryPlayerAchievements requires EOS SDK handles and Product User IDs for a specific product.',
        'Epic Social Overlay can display player achievement progress inside integrated games.',
        'No official public Epic Store user achievement-progress REST endpoint is currently wired into this client.',
      ],
    );
  }

  factory EpicProgressProofResult.blockedByMissingAchievementProgressApi({
    required int playtimeRecords,
  }) {
    return EpicProgressProofResult(
      status: EpicProgressProofStatus.blocked,
      title: 'Achievement progress API not proven',
      message:
          'EGData can read official Epic LibraryService playtime, but no supported cross-game Epic Store user achievement-progress endpoint has been verified yet.',
      checkedAt: DateTime.now(),
      evidence: [
        'Verified documented LibraryService playtime read access with $playtimeRecords playtime record(s).',
        'LibraryService playtime endpoint: GET /library/api/public/playtime/account/:accountId/all.',
        'EOS_Achievements_QueryPlayerAchievements still requires EOS SDK/product context rather than a general Epic Store library endpoint.',
      ],
    );
  }

  factory EpicProgressProofResult.blockedByMissingAchievementProductProbe({
    required int playtimeRecords,
  }) {
    return EpicProgressProofResult(
      status: EpicProgressProofStatus.blocked,
      title: 'Achievement product probe required',
      message:
          'EGData can read official Epic LibraryService playtime, but user achievement progress must be checked with a product-specific Epic Store GraphQL query.',
      checkedAt: DateTime.now(),
      evidence: [
        'Verified documented LibraryService playtime read access with $playtimeRecords playtime record(s).',
        'Achievement progress query requires epicAccountId and productId against https://store.epicgames.com/graphql.',
        'Product IDs are available from owned Epic library records, not from every local manifest.',
      ],
    );
  }

  factory EpicProgressProofResult.blockedByAchievementProbeFailure({
    required int playtimeRecords,
    required String failure,
  }) {
    return EpicProgressProofResult(
      status: EpicProgressProofStatus.blocked,
      title: 'Achievement progress probe failed',
      message:
          'EGData can read official Epic LibraryService playtime, but the Epic Store GraphQL player-achievement query failed with the current token.',
      checkedAt: DateTime.now(),
      evidence: [
        'Verified documented LibraryService playtime read access with $playtimeRecords playtime record(s).',
        failure,
        'Expected GraphQL endpoint: https://store.epicgames.com/graphql.',
      ],
    );
  }

  factory EpicProgressProofResult.available({
    required int playtimeRecords,
    required int achievementProductsChecked,
    required int achievementProductsWithData,
  }) {
    return EpicProgressProofResult(
      status: EpicProgressProofStatus.available,
      title: 'Official Epic progress available',
      message:
          'EGData verified official Epic LibraryService playtime and the Epic Store GraphQL user achievement-progress query.',
      checkedAt: DateTime.now(),
      evidence: [
        'Read $playtimeRecords official playtime record(s) from LibraryService.',
        'Checked $achievementProductsChecked product achievement record(s); $achievementProductsWithData returned user progress data.',
        'Achievement progress source: PlayerProfile.playerProfile(epicAccountId).productAchievements(productId).',
      ],
    );
  }

  factory EpicProgressProofResult.blockedByPlaytimeProbeFailure({
    required String failure,
  }) {
    return EpicProgressProofResult(
      status: EpicProgressProofStatus.blocked,
      title: 'Official playtime probe failed',
      message:
          'EGData found the documented Epic LibraryService playtime endpoint, but the current Epic token could not read it. Achievement progress is also still unproven.',
      checkedAt: DateTime.now(),
      evidence: [
        failure,
        'Expected playtime scope: library:public:{accountId}:playtime:all READ.',
        'No supported cross-game Epic Store user achievement-progress endpoint has been verified.',
      ],
    );
  }
}

class EpicGameProgress {
  final String catalogItemId;
  final String? artifactId;
  final String? productId;
  final Duration? officialPlaytime;
  final int? unlockedAchievements;
  final int? totalAchievements;
  final double? achievementPercent;
  final DateTime? syncedAt;
  final String source;

  const EpicGameProgress({
    required this.catalogItemId,
    this.artifactId,
    this.productId,
    this.officialPlaytime,
    this.unlockedAchievements,
    this.totalAchievements,
    this.achievementPercent,
    this.syncedAt,
    this.source = 'official-epic',
  });

  bool get hasOfficialPlaytime => officialPlaytime != null;

  bool get hasAchievementProgress =>
      unlockedAchievements != null ||
      totalAchievements != null ||
      achievementPercent != null;
}

class EpicProgressSnapshot {
  final EpicProgressProofResult proof;
  final Map<String, EpicGameProgress> gamesByCatalogItemId;

  const EpicProgressSnapshot({
    required this.proof,
    this.gamesByCatalogItemId = const {},
  });

  bool get isAvailable => proof.isAvailable;
}
