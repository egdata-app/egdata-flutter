class TrayPopupStats {
  final String weeklyPlaytime;
  final int gamesInstalled;
  final String? mostPlayedGame;
  final String? currentGame;
  final String? currentSessionTime;

  const TrayPopupStats({
    required this.weeklyPlaytime,
    required this.gamesInstalled,
    this.mostPlayedGame,
    this.currentGame,
    this.currentSessionTime,
  });

  const TrayPopupStats.empty()
    : weeklyPlaytime = '0h',
      gamesInstalled = 0,
      mostPlayedGame = null,
      currentGame = null,
      currentSessionTime = null;

  TrayPopupStats copyWith({
    String? weeklyPlaytime,
    int? gamesInstalled,
    String? mostPlayedGame,
    String? currentGame,
    String? currentSessionTime,
  }) {
    return TrayPopupStats(
      weeklyPlaytime: weeklyPlaytime ?? this.weeklyPlaytime,
      gamesInstalled: gamesInstalled ?? this.gamesInstalled,
      mostPlayedGame: mostPlayedGame ?? this.mostPlayedGame,
      currentGame: currentGame ?? this.currentGame,
      currentSessionTime: currentSessionTime ?? this.currentSessionTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weeklyPlaytime': weeklyPlaytime,
      'gamesInstalled': gamesInstalled,
      'mostPlayedGame': mostPlayedGame,
      'currentGame': currentGame,
      'currentSessionTime': currentSessionTime,
    };
  }

  factory TrayPopupStats.fromJson(Map<String, dynamic> json) {
    final gamesInstalledRaw = json['gamesInstalled'];
    return TrayPopupStats(
      weeklyPlaytime: (json['weeklyPlaytime'] ?? '0h').toString(),
      gamesInstalled: gamesInstalledRaw is int
          ? gamesInstalledRaw
          : int.tryParse(gamesInstalledRaw?.toString() ?? '0') ?? 0,
      mostPlayedGame: json['mostPlayedGame']?.toString(),
      currentGame: json['currentGame']?.toString(),
      currentSessionTime: json['currentSessionTime']?.toString(),
    );
  }
}
