import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';
import '../models/playtime_stats.dart';
import '../services/playtime_service.dart';
import '../database/database_service.dart';
import '../models/game_info.dart';

/// Compact dashboard content for the tray popup window.
/// Shows current game (if playing) and quick stats.
class TrayPopupContent extends StatefulWidget {
  final PlaytimeService? playtimeService;
  final DatabaseService? db;
  final List<GameInfo> installedGames;
  final VoidCallback? onClose;

  const TrayPopupContent({
    super.key,
    this.playtimeService,
    this.db,
    this.installedGames = const [],
    this.onClose,
  });

  @override
  State<TrayPopupContent> createState() => _TrayPopupContentState();
}

class _TrayPopupContentState extends State<TrayPopupContent> {
  PlaytimeStats? _playtimeStats;
  PlaytimeSessionEntry? _activeSession;
  StreamSubscription<PlaytimeStats>? _statsSubscription;
  StreamSubscription<PlaytimeSessionEntry?>? _activeGameSubscription;
  Timer? _durationTimer;

  @override
  void initState() {
    super.initState();
    _loadStats();

    _statsSubscription = widget.playtimeService?.statsStream.listen((stats) {
      if (mounted) setState(() => _playtimeStats = stats);
    });

    _activeGameSubscription = widget.playtimeService?.activeGameStream.listen((session) {
      if (mounted) {
        final wasActive = _activeSession != null;
        final isActive = session != null;
        setState(() => _activeSession = session);

        if (isActive && !wasActive) {
          _startDurationTimer();
        } else if (!isActive && wasActive) {
          _stopDurationTimer();
        }
      }
    });
  }

  @override
  void dispose() {
    _statsSubscription?.cancel();
    _activeGameSubscription?.cancel();
    _stopDurationTimer();
    super.dispose();
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _activeSession != null) setState(() {});
    });
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  Future<void> _loadStats() async {
    if (widget.playtimeService == null) return;
    final stats = await widget.playtimeService!.getWeeklyStats();
    if (mounted) setState(() => _playtimeStats = stats);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _buildHeader(),
          // Now Playing (if active)
          if (_activeSession != null) _buildNowPlaying(),
          // Stats
          _buildStats(),
          // Recently Played
          _buildRecentlyPlayed(),
          // Footer with "Open App" button
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.games_rounded,
              size: 14,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'EGData',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 14,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNowPlaying() {
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
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
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
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                  )
                : const Icon(
                    Icons.games_rounded,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withValues(alpha: 0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'NOW PLAYING',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  session.gameName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Text(
              timeStr,
              style: const TextStyle(
                fontSize: 11,
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

  Widget _buildStats() {
    return Padding(
      padding: EdgeInsets.fromLTRB(12, _activeSession != null ? 0 : 12, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.timer_rounded,
              label: 'This Week',
              value: _playtimeStats?.formattedTotalPlaytime ?? '0h',
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatItem(
              icon: Icons.games_rounded,
              label: 'Installed',
              value: '${widget.installedGames.length}',
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMostPlayedStat(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceGlass,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderGlass),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMostPlayedStat() {
    final mostPlayed = _playtimeStats?.mostPlayedGame;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceGlass,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderGlass),
      ),
      child: Column(
        children: [
          const Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
          const SizedBox(height: 6),
          Text(
            mostPlayed?.gameName ?? 'None',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          const Text(
            'Most Played',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentlyPlayed() {
    if (_playtimeStats == null || _playtimeStats!.playtimeByGame.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedGames = _playtimeStats!.playtimeByGame.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Text(
              'RECENTLY PLAYED',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 1,
              ),
            ),
          ),
          ...sortedGames.take(3).map((entry) {
            final playtime = entry.value;
            return _buildRecentGameRow(entry.key, playtime);
          }),
        ],
      ),
    );
  }

  Widget _buildRecentGameRow(String gameId, Duration playtime) {
    // For now, just show the app name from installed games
    final game = widget.installedGames.where((g) => g.appName == gameId).firstOrNull;
    final gameName = game?.displayName ?? gameId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.games_rounded,
              size: 14,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              gameName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _formatPlaytime(playtime),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                // This will be handled by the tray service to show main window
                widget.onClose?.call();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Open EGData',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
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
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}
