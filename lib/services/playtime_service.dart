import 'dart:async';
import 'dart:io';
import '../database/database_service.dart';
import '../models/game_info.dart';
import '../models/playtime_stats.dart';
import 'game_process_api_service.dart';
import 'windows_process_service.dart';

class PlaytimeService {
  final DatabaseService _db;
  final List<GameInfo> Function() _getInstalledGames;
  final GameProcessApiService _processApiService;

  Timer? _pollTimer;
  bool _isTracking = false;
  int? _activeSessionId;
  String? _activeGameId;
  DateTime? _lastProcessSeen;

  // Stream for UI updates
  final StreamController<PlaytimeStats> _statsController =
      StreamController<PlaytimeStats>.broadcast();
  Stream<PlaytimeStats> get statsStream => _statsController.stream;

  // Stream for currently running game
  final StreamController<PlaytimeSessionEntry?> _activeGameController =
      StreamController<PlaytimeSessionEntry?>.broadcast();
  Stream<PlaytimeSessionEntry?> get activeGameStream =>
      _activeGameController.stream;

  // Configuration
  static const Duration _pollInterval = Duration(seconds: 10);
  static const Duration _sessionGracePeriod = Duration(seconds: 30);

  PlaytimeService({
    required DatabaseService db,
    required List<GameInfo> Function() getInstalledGames,
    GameProcessApiService? processApiService,
  })  : _db = db,
        _getInstalledGames = getInstalledGames,
        _processApiService = processApiService ?? GameProcessApiService();

  /// Start tracking (called when app initializes)
  void startTracking() {
    if (_isTracking) return;
    _isTracking = true;

    // Check for any dangling active sessions
    _cleanupDanglingSessions();

    // Start polling
    _pollTimer = Timer.periodic(_pollInterval, (_) => _pollForRunningGames());

    // Run first check immediately
    _pollForRunningGames();
  }

  /// Stop tracking (called on dispose)
  void stopTracking() {
    _isTracking = false;
    _pollTimer?.cancel();
    _pollTimer = null;

    // End any active session (fire and forget for normal dispose)
    if (_activeSessionId != null) {
      _endCurrentSession().catchError((e) {
        // Ignore errors during shutdown
      });
    }
  }

  /// Clean up any sessions that weren't properly closed
  Future<void> _cleanupDanglingSessions() async {
    final activeSession = await _db.getActiveSession();
    if (activeSession != null) {
      // End the session with the last known time
      await _db.endSession(activeSession.id, DateTime.now());
    }
  }

  /// Main polling loop
  Future<void> _pollForRunningGames() async {
    if (!_isTracking) return;

    try {
      final runningGame = await _detectRunningGame();

      if (runningGame != null) {
        // A game is running
        _lastProcessSeen = DateTime.now();

        if (_activeSessionId == null ||
            _activeGameId != runningGame.catalogItemId) {
          // Start a new session (end previous if different game)
          if (_activeSessionId != null && _activeGameId != runningGame.catalogItemId) {
            await _endCurrentSession();
          }
          await _startSession(runningGame);
        }
      } else {
        // No game is running
        if (_activeSessionId != null && _lastProcessSeen != null) {
          final elapsed = DateTime.now().difference(_lastProcessSeen!);
          if (elapsed > _sessionGracePeriod) {
            // Grace period expired, end the session
            await _endCurrentSession();
          }
        }
      }

      // Emit updated stats
      final stats = await getWeeklyStats();
      _statsController.add(stats);

      // Emit active game state
      final activeSession = await _db.getActiveSession();
      _activeGameController.add(activeSession);
    } catch (e) {
      // Silently handle errors to keep polling running
    }
  }

  /// Check if any game process is running
  Future<GameInfo?> _detectRunningGame() async {
    final games = _getInstalledGames();
    if (games.isEmpty) return null;

    // On Windows, use install directory detection via native Win32 API (most reliable)
    if (Platform.isWindows) {
      for (final game in games) {
        if (_hasProcessInInstallDir(game)) {
          return game;
        }
      }
      return null;
    }

    // On macOS, fall back to process name matching
    for (final game in games) {
      final processNames = await _getProcessNamesForGame(game);
      for (final processName in processNames) {
        if (await _isProcessRunning(processName)) {
          return game;
        }
      }
    }

    return null;
  }

  /// Check if any process is running from the game's install directory (Windows)
  /// Uses native Win32 API for better performance and reliability.
  bool _hasProcessInInstallDir(GameInfo game) {
    try {
      return WindowsProcessService.hasProcessInDirectory(game.installLocation);
    } catch (e) {
      return false;
    }
  }

  /// Get process names for a game (with caching)
  Future<List<String>> _getProcessNamesForGame(GameInfo game) async {
    // Check cache first
    final cached = await _db.getProcessCache(game.catalogItemId);
    if (cached != null && !cached.isExpired) {
      return cached.processNames;
    }

    List<String> processNames = [];

    // Primary source: Use launchExecutable from local manifest
    // This is the actual executable name specified by Epic Games
    if (game.launchExecutable != null && game.launchExecutable!.isNotEmpty) {
      final executable = game.launchExecutable!;
      // Add the executable and common variant patterns
      processNames = [
        executable,
        // Some games use -Win64-Shipping suffix for the actual game process
        if (!executable.contains('-Win64-Shipping'))
          executable.replaceAll('.exe', '-Win64-Shipping.exe'),
      ];
    }

    // Fallback: Try API if local manifest didn't have launchExecutable
    if (processNames.isEmpty && game.catalogItemId.isNotEmpty) {
      processNames =
          await _processApiService.fetchProcessNames(game.catalogItemId);
    }

    // Last resort fallback: use appName as a guess
    if (processNames.isEmpty && game.appName.isNotEmpty) {
      // Common patterns: game.exe, game-Win64-Shipping.exe
      processNames = [
        '${game.appName}.exe',
        '${game.appName}-Win64-Shipping.exe',
      ];
    }

    // Cache the result
    if (processNames.isNotEmpty) {
      final cacheEntry = GameProcessCacheEntry()
        ..catalogItemId = game.catalogItemId
        ..processNames = processNames
        ..fetchedAt = DateTime.now();
      await _db.saveProcessCache(cacheEntry);
    }

    return processNames;
  }

  /// Check if a specific process is running
  Future<bool> _isProcessRunning(String processName) async {
    try {
      if (Platform.isWindows) {
        // Use native Win32 API for better performance
        return WindowsProcessService.isProcessRunning(processName);
      } else if (Platform.isMacOS) {
        // On macOS, process names don't have .exe
        final macProcessName = processName.replaceAll('.exe', '');
        final result = await Process.run('pgrep', ['-ix', macProcessName]);
        return result.exitCode == 0;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Start a new session for the given game
  Future<void> _startSession(GameInfo game) async {
    final session = PlaytimeSessionEntry()
      ..gameId = game.catalogItemId
      ..gameName = game.displayName
      ..thumbnailUrl = game.metadata?.dieselGameBoxTall ?? game.metadata?.firstImageUrl
      ..startTime = DateTime.now()
      ..durationSeconds = 0
      ..installationGuid = game.installationGuid;

    await _db.savePlaytimeSession(session);

    // Get the ID of the saved session
    final activeSession = await _db.getActiveSession();
    if (activeSession != null) {
      _activeSessionId = activeSession.id;
      _activeGameId = game.catalogItemId;
    }
  }

  /// End the current session
  Future<void> _endCurrentSession() async {
    if (_activeSessionId != null) {
      await _db.endSession(_activeSessionId!, DateTime.now());
      _activeSessionId = null;
      _activeGameId = null;
      _lastProcessSeen = null;
    }
  }

  /// Get weekly stats
  Future<PlaytimeStats> getWeeklyStats() async {
    final playtimeByGameSeconds = await _db.getWeeklyPlaytimeByGame();

    if (playtimeByGameSeconds.isEmpty) {
      return PlaytimeStats.empty();
    }

    // Convert to Duration map
    final playtimeByGame = <String, Duration>{};
    for (final entry in playtimeByGameSeconds.entries) {
      playtimeByGame[entry.key] = Duration(seconds: entry.value);
    }

    // Calculate total
    final totalSeconds = playtimeByGameSeconds.values.fold(0, (a, b) => a + b);
    final totalWeeklyPlaytime = Duration(seconds: totalSeconds);

    // Find most played game
    GamePlaytimeSummary? mostPlayedGame;
    if (playtimeByGameSeconds.isNotEmpty) {
      final mostPlayedEntry = playtimeByGameSeconds.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );

      // Get game info for thumbnail
      final sessions = await _db.getSessionsForGame(mostPlayedEntry.key);
      final latestSession = sessions.isNotEmpty ? sessions.first : null;

      mostPlayedGame = GamePlaytimeSummary(
        gameId: mostPlayedEntry.key,
        gameName: latestSession?.gameName ?? 'Unknown',
        thumbnailUrl: latestSession?.thumbnailUrl,
        totalPlaytime: Duration(seconds: mostPlayedEntry.value),
      );
    }

    return PlaytimeStats(
      totalWeeklyPlaytime: totalWeeklyPlaytime,
      gamesPlayedThisWeek: playtimeByGameSeconds.length,
      playtimeByGame: playtimeByGame,
      mostPlayedGame: mostPlayedGame,
    );
  }

  /// Get total playtime for a specific game
  Future<Duration> getTotalPlaytime(String gameId) async {
    final seconds = await _db.getTotalPlaytimeSeconds(gameId);
    return Duration(seconds: seconds);
  }

  /// Get recent sessions
  Future<List<PlaytimeSessionEntry>> getRecentSessions({int limit = 10}) async {
    return _db.getRecentSessions(limit: limit);
  }

  /// Get game names mapping for the chart
  Future<Map<String, String>> getGameNamesForStats(
      Map<String, Duration> playtimeByGame) async {
    final gameNames = <String, String>{};

    for (final gameId in playtimeByGame.keys) {
      final sessions = await _db.getSessionsForGame(gameId);
      if (sessions.isNotEmpty) {
        gameNames[gameId] = sessions.first.gameName;
      }
    }

    return gameNames;
  }

  /// Get game thumbnails mapping for the chart
  Future<Map<String, String?>> getGameThumbnailsForStats(
      Map<String, Duration> playtimeByGame) async {
    final gameThumbnails = <String, String?>{};

    for (final gameId in playtimeByGame.keys) {
      final sessions = await _db.getSessionsForGame(gameId);
      if (sessions.isNotEmpty) {
        gameThumbnails[gameId] = sessions.first.thumbnailUrl;
      }
    }

    return gameThumbnails;
  }

  void dispose() {
    stopTracking();
    _statsController.close();
    _activeGameController.close();
  }

  /// Proper shutdown that ensures all async operations complete
  Future<void> shutdown() async {
    if (_activeSessionId != null) {
      await _endCurrentSession();
    }
    _statsController.close();
    _activeGameController.close();
  }
}
