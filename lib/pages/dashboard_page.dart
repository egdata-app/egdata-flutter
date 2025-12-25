import 'package:flutter/material.dart';
import '../main.dart';
import '../models/calendar_event.dart';
import '../models/game_info.dart';
import '../models/settings.dart';
import '../services/calendar_service.dart';
import '../services/follow_service.dart';

class DashboardPage extends StatefulWidget {
  final List<GameInfo> games;
  final AppSettings settings;
  final FollowService followService;
  final CalendarService calendarService;
  final bool isLoading;
  final bool isUploadingAll;
  final VoidCallback onScanGames;
  final VoidCallback onUploadAll;
  final List<String> logs;

  const DashboardPage({
    super.key,
    required this.games,
    required this.settings,
    required this.followService,
    required this.calendarService,
    required this.isLoading,
    required this.isUploadingAll,
    required this.onScanGames,
    required this.onUploadAll,
    required this.logs,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<CalendarEvent> _freeGames = [];
  List<CalendarEvent> _upcomingReleases = [];
  bool _isLoadingEvents = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoadingEvents = true);
    try {
      final events = await widget.calendarService.fetchAllEvents(
        followedGames: widget.followService.followedGames,
      );

      final now = DateTime.now();
      _freeGames = events
          .where((e) => e.type == CalendarEventType.freeGame && !e.hasEnded)
          .take(3)
          .toList();
      _upcomingReleases = events
          .where((e) =>
              e.type == CalendarEventType.release &&
              e.startDate.isAfter(now))
          .take(3)
          .toList();
    } catch (e) {
      // Failed to load events
    }
    if (mounted) {
      setState(() => _isLoadingEvents = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsRow(),
                  const SizedBox(height: 24),
                  _buildCardsRow(),
                  const SizedBox(height: 24),
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                  _buildRecentActivity(),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Overview of your library and events',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: _loadEvents,
            icon: const Icon(Icons.refresh_rounded),
            color: AppColors.textSecondary,
            tooltip: 'Refresh',
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
            icon: Icons.games_rounded,
            label: 'Installed Games',
            value: '${widget.games.length}',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            icon: Icons.favorite_rounded,
            label: 'Following',
            value: '${widget.followService.followedGames.length}',
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            icon: Icons.sync_rounded,
            label: 'Auto Sync',
            value: widget.settings.autoSync
                ? '${widget.settings.syncIntervalMinutes}m'
                : 'Off',
            color: widget.settings.autoSync
                ? AppColors.success
                : AppColors.textMuted,
          ),
        ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildFreeGamesCard()),
        const SizedBox(width: 16),
        Expanded(child: _buildUpcomingCard()),
        const SizedBox(width: 16),
        Expanded(child: _buildFollowingCard()),
      ],
    );
  }

  Widget _buildFreeGamesCard() {
    return _buildEventCard(
      title: 'FREE NOW',
      icon: Icons.card_giftcard_rounded,
      color: AppColors.success,
      events: _freeGames,
      emptyMessage: 'No free games available',
      isLoading: _isLoadingEvents,
    );
  }

  Widget _buildUpcomingCard() {
    return _buildEventCard(
      title: 'UPCOMING',
      icon: Icons.rocket_launch_rounded,
      color: AppColors.primary,
      events: _upcomingReleases,
      emptyMessage: 'No upcoming releases',
      isLoading: _isLoadingEvents,
    );
  }

  Widget _buildFollowingCard() {
    final followedGames = widget.followService.followedGames.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.favorite_rounded,
                  size: 16,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'FOLLOWING',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (followedGames.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No games followed yet',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            )
          else
            ...followedGames.map((game) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: game.thumbnailUrl != null
                              ? Image.network(
                                  game.thumbnailUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.games_rounded, size: 16),
                                )
                              : const Icon(Icons.games_rounded, size: 16),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          game.title,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildEventCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<CalendarEvent> events,
    required String emptyMessage,
    required bool isLoading,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            )
          else if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  emptyMessage,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            )
          else
            ...events.map((event) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: event.thumbnailUrl != null
                              ? Image.network(
                                  event.thumbnailUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Icon(icon, size: 16, color: color),
                                )
                              : Icon(icon, size: 16, color: color),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (event.subtitle != null)
                              Text(
                                event.subtitle!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'QUICK ACTIONS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: AppColors.textMuted,
            ),
          ),
        ),
        Row(
          children: [
            _buildActionButton(
              icon: Icons.refresh_rounded,
              label: 'Scan Games',
              onPressed: widget.isLoading ? null : widget.onScanGames,
              isLoading: widget.isLoading,
            ),
            const SizedBox(width: 12),
            _buildActionButton(
              icon: Icons.cloud_upload_rounded,
              label: 'Upload All',
              onPressed: widget.isUploadingAll || widget.games.isEmpty
                  ? null
                  : widget.onUploadAll,
              isLoading: widget.isUploadingAll,
              isPrimary: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isPrimary = false,
  }) {
    return Material(
      color: isPrimary
          ? (onPressed == null ? AppColors.surfaceLight : AppColors.primary)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isPrimary ? Colors.transparent : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isPrimary ? Colors.white : AppColors.textSecondary,
                  ),
                )
              else
                Icon(
                  icon,
                  size: 18,
                  color: isPrimary
                      ? (onPressed == null
                          ? AppColors.textMuted
                          : Colors.white)
                      : AppColors.textSecondary,
                ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isPrimary
                      ? (onPressed == null ? AppColors.textMuted : Colors.white)
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    final recentLogs = widget.logs.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'RECENT ACTIVITY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: AppColors.textMuted,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: recentLogs.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'No recent activity',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: recentLogs.map((log) {
                    final isError =
                        log.contains('Error') || log.contains('failed');
                    final isSuccess = log.contains('uploaded') ||
                        log.contains('complete') ||
                        log.contains('exists');
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        log,
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 11,
                          color: isError
                              ? AppColors.error
                              : isSuccess
                                  ? AppColors.success
                                  : AppColors.textMuted,
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}
