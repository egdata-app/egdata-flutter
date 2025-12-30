class PlaytimeStats {
  final Duration totalWeeklyPlaytime;
  final int gamesPlayedThisWeek;
  final Map<String, Duration> playtimeByGame; // gameId -> duration
  final GamePlaytimeSummary? mostPlayedGame;

  const PlaytimeStats({
    required this.totalWeeklyPlaytime,
    required this.gamesPlayedThisWeek,
    required this.playtimeByGame,
    this.mostPlayedGame,
  });

  factory PlaytimeStats.empty() {
    return const PlaytimeStats(
      totalWeeklyPlaytime: Duration.zero,
      gamesPlayedThisWeek: 0,
      playtimeByGame: {},
      mostPlayedGame: null,
    );
  }

  String get formattedTotalPlaytime {
    final hours = totalWeeklyPlaytime.inHours;
    final minutes = totalWeeklyPlaytime.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  bool get hasPlaytime => totalWeeklyPlaytime.inMinutes > 0;
}

class GamePlaytimeSummary {
  final String gameId;
  final String gameName;
  final String? thumbnailUrl;
  final Duration totalPlaytime;

  const GamePlaytimeSummary({
    required this.gameId,
    required this.gameName,
    this.thumbnailUrl,
    required this.totalPlaytime,
  });

  String get formattedPlaytime {
    final hours = totalPlaytime.inHours;
    final minutes = totalPlaytime.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String get shortFormattedPlaytime {
    final hours = totalPlaytime.inHours;
    if (hours > 0) {
      return '${hours}h';
    }
    return '${totalPlaytime.inMinutes}m';
  }
}
