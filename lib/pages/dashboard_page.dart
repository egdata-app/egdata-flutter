import 'dart:async';
import 'package:flutter/material.dart';
import '../database/collections/playtime_session_entry.dart';
import '../database/database_service.dart';
import '../main.dart';
import '../models/game_info.dart';
import '../models/playtime_stats.dart';
import '../services/playtime_service.dart';
import '../widgets/weekly_activity_chart.dart';

class DashboardPage extends StatefulWidget {
  final PlaytimeService? playtimeService;
  final List<GameInfo> installedGames;
  final DatabaseService? db;

  const DashboardPage({
    super.key,
    this.playtimeService,
    this.installedGames = const [],
    this.db,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  PlaytimeStats? _playtimeStats;
  Map<String, String> _gameNames = {};
  Map<String, String?> _gameThumbnails = {};
  PlaytimeSessionEntry? _activeSession;
  StreamSubscription<PlaytimeStats>? _statsSubscription;
  StreamSubscription<PlaytimeSessionEntry?>? _activeGameSubscription;
  StreamSubscription<int>? _uploadCountSubscription;
  Timer? _durationTimer;
  int _uploadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPlaytimeStats();
    _loadUploadCount();

    _statsSubscription = widget.playtimeService?.statsStream.listen((stats) {
      if (mounted) {
        setState(() => _playtimeStats = stats);
        _updateGameInfo();
      }
    });

    _activeGameSubscription =
        widget.playtimeService?.activeGameStream.listen((session) {
      if (mounted) {
        final wasActive = _activeSession != null;
        final isActive = session != null;
        setState(() => _activeSession = session);

        // Start/stop the duration timer based on active state
        if (isActive && !wasActive) {
          _startDurationTimer();
        } else if (!isActive && wasActive) {
          _stopDurationTimer();
        }
      }
    });

    _uploadCountSubscription = widget.db?.uploadCountStream.listen((count) {
      if (mounted) {
        setState(() => _uploadCount = count);
      }
    });
  }

  @override
  void dispose() {
    _statsSubscription?.cancel();
    _activeGameSubscription?.cancel();
    _uploadCountSubscription?.cancel();
    _stopDurationTimer();
    super.dispose();
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _activeSession != null) {
        setState(() {}); // Trigger rebuild to update duration
      }
    });
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  Future<void> _loadPlaytimeStats() async {
    if (widget.playtimeService == null) return;
    final stats = await widget.playtimeService!.getWeeklyStats();
    if (mounted) {
      setState(() => _playtimeStats = stats);
      await _updateGameInfo();
    }
  }

  Future<void> _updateGameInfo() async {
    if (widget.playtimeService == null || _playtimeStats == null) return;

    final names = await widget.playtimeService!
        .getGameNamesForStats(_playtimeStats!.playtimeByGame);
    final thumbnails = await widget.playtimeService!
        .getGameThumbnailsForStats(_playtimeStats!.playtimeByGame);

    if (mounted) {
      setState(() {
        _gameNames = names;
        _gameThumbnails = thumbnails;
      });
    }
  }

  Future<void> _loadUploadCount() async {
    if (widget.db == null) return;
    final count = await widget.db!.getManifestUploadCount();
    if (mounted) {
      setState(() => _uploadCount = count);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_activeSession != null) ...[
                    _buildNowPlayingCard(),
                    const SizedBox(height: 20),
                  ],
                  _buildStatsRow(),
                  const SizedBox(height: 32),
                  if (_playtimeStats != null &&
                      _playtimeStats!.playtimeByGame.isNotEmpty) ...[
                    _buildSection(
                      title: 'Weekly Activity',
                      icon: Icons.bar_chart_rounded,
                      color: AppColors.primary,
                      child: WeeklyActivityChart(
                        playtimeByGame: _playtimeStats!.playtimeByGame,
                        gameNames: _gameNames,
                        gameThumbnails: _gameThumbnails,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                  _buildSection(
                    title: 'Recently Played',
                    icon: Icons.history_rounded,
                    color: AppColors.accent,
                    child: _buildRecentlyPlayed(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your gaming overview',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNowPlayingCard() {
    final session = _activeSession!;
    final duration = session.duration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    final timeStr = hours > 0
        ? '${hours}h ${minutes}m ${seconds}s'
        : minutes > 0
            ? '${minutes}m ${seconds}s'
            : '${seconds}s';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppColors.radiusMedium),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Game thumbnail
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppColors.radiusSmall),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: session.thumbnailUrl != null
                ? Image.network(
                    session.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.games_rounded,
                      size: 28,
                      color: AppColors.textMuted,
                    ),
                  )
                : const Icon(
                    Icons.games_rounded,
                    size: 28,
                    color: AppColors.textMuted,
                  ),
          ),
          const SizedBox(width: 16),
          // Game info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Pulsing indicator
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withValues(alpha: 0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'NOW PLAYING',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  session.gameName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Duration
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Text(
              timeStr,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.timer_rounded,
            label: 'Weekly Playtime',
            value: _playtimeStats?.formattedTotalPlaytime ?? '0h',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildStatCard(
            icon: Icons.games_rounded,
            label: 'Games Installed',
            value: '${widget.installedGames.length}',
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildStatCard(
            icon: Icons.cloud_done_rounded,
            label: 'Manifests Uploaded',
            value: '$_uploadCount',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: _buildMostPlayedCard()),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceGlass,
        borderRadius: BorderRadius.circular(AppColors.radiusMedium),
        border: Border.all(color: AppColors.borderGlass),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppColors.radiusSmall),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMostPlayedCard() {
    final mostPlayed = _playtimeStats?.mostPlayedGame;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceGlass,
        borderRadius: BorderRadius.circular(AppColors.radiusMedium),
        border: Border.all(color: AppColors.borderGlass),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppColors.radiusSmall),
            ),
            child: const Icon(Icons.star_rounded, size: 20, color: AppColors.warning),
          ),
          const SizedBox(height: 14),
          if (mostPlayed != null) ...[
            Row(
              children: [
                if (mostPlayed.thumbnailUrl != null)
                  Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: AppColors.surfaceLight,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      mostPlayed.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.games_rounded,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mostPlayed.gameName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mostPlayed.formattedPlaytime,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else
            const Text(
              'No data yet',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          const SizedBox(height: 6),
          const Text(
            'Most Played',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppColors.radiusSmall),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        child,
      ],
    );
  }

  Widget _buildRecentlyPlayed() {
    if (_playtimeStats == null || _playtimeStats!.playtimeByGame.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppColors.radiusMedium),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.sports_esports_rounded,
                size: 48,
                color: AppColors.textMuted.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'No games played this week',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Launch a game to start tracking',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Sort games by playtime (highest first)
    final sortedGames = _playtimeStats!.playtimeByGame.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: sortedGames.take(5).map((entry) {
          final gameId = entry.key;
          final playtime = entry.value;
          final gameName = _gameNames[gameId] ?? 'Unknown Game';
          final thumbnail = _gameThumbnails[gameId];
          final isLast = sortedGames.indexOf(entry) ==
              (sortedGames.length > 5 ? 4 : sortedGames.length - 1);

          return _buildRecentGameItem(
            gameName: gameName,
            playtime: playtime,
            thumbnailUrl: thumbnail,
            isLast: isLast,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentGameItem({
    required String gameName,
    required Duration playtime,
    String? thumbnailUrl,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppColors.radiusSmall),
            ),
            clipBehavior: Clip.antiAlias,
            child: thumbnailUrl != null
                ? Image.network(
                    thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.games_rounded,
                      size: 22,
                      color: AppColors.textMuted,
                    ),
                  )
                : const Icon(
                    Icons.games_rounded,
                    size: 22,
                    color: AppColors.textMuted,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              gameName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _formatPlaytime(playtime),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPlaytime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
