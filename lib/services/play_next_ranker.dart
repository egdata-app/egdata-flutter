import '../database/database_service.dart';
import '../models/drive_discovery.dart';
import '../models/epic_progress.dart';
import '../models/game_info.dart';

class PlayNextRanker {
  const PlayNextRanker();

  List<GameInfo> rank({
    required Iterable<GameInfo> games,
    required Iterable<PlaytimeSessionEntry> sessions,
    required Map<String, EpicGameProgress> progressByCatalogItemId,
  }) {
    final recentById = <String, DateTime>{};
    for (final session in sessions) {
      final existing = recentById[session.gameId];
      if (existing == null || session.startTime.isAfter(existing)) {
        recentById[session.gameId] = session.startTime;
      }
    }
    final candidates = games.where(isPlayableBaseGame).toList();
    candidates.sort((a, b) {
      final aRecent = recentById[a.catalogItemId];
      final bRecent = recentById[b.catalogItemId];
      if (aRecent != null || bRecent != null) {
        if (aRecent == null) return 1;
        if (bRecent == null) return -1;
        final recency = bRecent.compareTo(aRecent);
        if (recency != 0) return recency;
      }
      final aProgress = fraction(
        progressByCatalogItemId[a.catalogItemId]?.achievementPercent,
      );
      final bProgress = fraction(
        progressByCatalogItemId[b.catalogItemId]?.achievementPercent,
      );
      final aIncomplete = aProgress != null && aProgress > 0 && aProgress < 1;
      final bIncomplete = bProgress != null && bProgress > 0 && bProgress < 1;
      if (aIncomplete != bIncomplete) return bIncomplete ? 1 : -1;
      final aPlaytime =
          progressByCatalogItemId[a.catalogItemId]?.officialPlaytime ??
          Duration.zero;
      final bPlaytime =
          progressByCatalogItemId[b.catalogItemId]?.officialPlaytime ??
          Duration.zero;
      final playtime = bPlaytime.compareTo(aPlaytime);
      if (playtime != 0) return playtime;
      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });
    return candidates;
  }

  bool isPlayableBaseGame(GameInfo game) {
    if (game.appName.trim().isEmpty) return false;
    if (game.availability != InstalledGameAvailability.available &&
        game.availability != InstalledGameAvailability.unknown) {
      return false;
    }
    if (game.appCategories.any(
      (category) => category.toLowerCase() == 'addons',
    )) {
      return false;
    }
    final mainApp = game.mainGameAppName.trim();
    return mainApp.isEmpty || mainApp == game.appName;
  }

  static double? fraction(double? value) {
    if (value == null) return null;
    return value > 1 ? (value / 100).clamp(0.0, 1.0) : value.clamp(0.0, 1.0);
  }
}
