import 'dart:async';

import 'package:flutter/material.dart';

import '../database/database_service.dart';
import '../models/drive_discovery.dart';
import '../models/epic_progress.dart';
import '../models/game_info.dart';
import '../services/drive_discovery_service.dart';
import '../services/playtime_service.dart';
import '../services/play_next_ranker.dart';
import '../theme/desktop_theme.dart';
import '../utils/epic_protocol.dart';
import '../utils/image_utils.dart';

class DesktopHomePage extends StatefulWidget {
  final List<GameInfo> installedGames;
  final int ownedGamesCount;
  final Map<String, EpicGameProgress> progressByCatalogItemId;
  final PlaytimeService? playtimeService;
  final DatabaseService? database;
  final DriveDiscoveryService? driveDiscoveryService;
  final bool epicConnected;
  final VoidCallback onOpenLibrary;
  final VoidCallback onOpenActivity;
  final VoidCallback onOpenDiskDiscovery;
  final ValueChanged<GameInfo> onOpenGameDetails;

  const DesktopHomePage({
    super.key,
    required this.installedGames,
    required this.ownedGamesCount,
    required this.progressByCatalogItemId,
    required this.playtimeService,
    this.database,
    required this.driveDiscoveryService,
    required this.epicConnected,
    required this.onOpenLibrary,
    required this.onOpenActivity,
    required this.onOpenDiskDiscovery,
    required this.onOpenGameDetails,
  });

  @override
  State<DesktopHomePage> createState() => _DesktopHomePageState();
}

class _DesktopHomePageState extends State<DesktopHomePage> {
  static const PlayNextRanker _ranker = PlayNextRanker();
  List<PlaytimeSessionEntry> _sessions = const [];
  List<ActivityEventEntry> _diskEvents = const [];
  StreamSubscription<PlaytimeSessionEntry?>? _activeSubscription;

  @override
  void initState() {
    super.initState();
    widget.driveDiscoveryService?.addListener(_onDiscoveryChanged);
    _activeSubscription = widget.playtimeService?.activeGameStream.listen((_) {
      unawaited(_loadActivity());
    });
    unawaited(_loadActivity());
  }

  @override
  void didUpdateWidget(covariant DesktopHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.driveDiscoveryService != widget.driveDiscoveryService) {
      oldWidget.driveDiscoveryService?.removeListener(_onDiscoveryChanged);
      widget.driveDiscoveryService?.addListener(_onDiscoveryChanged);
    }
    if (oldWidget.installedGames != widget.installedGames) {
      unawaited(_loadActivity());
    }
  }

  @override
  void dispose() {
    widget.driveDiscoveryService?.removeListener(_onDiscoveryChanged);
    _activeSubscription?.cancel();
    super.dispose();
  }

  void _onDiscoveryChanged() {
    if (mounted) setState(() {});
    unawaited(_loadActivity());
  }

  Future<void> _loadActivity() async {
    final database = widget.database;
    if (database == null) return;
    final values = await Future.wait([
      database.getRecentSessions(limit: 30),
      database.getRecentActivityEvents(limit: 12),
    ]);
    if (!mounted) return;
    setState(() {
      _sessions = values[0] as List<PlaytimeSessionEntry>;
      _diskEvents = values[1] as List<ActivityEventEntry>;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ranked = _rankedGames();
    final hero = ranked.isEmpty ? null : ranked.first;
    final upNext = ranked.skip(1).take(3).toList(growable: false);
    final candidates =
        widget.driveDiscoveryService?.recoveryCandidates ?? const [];

    return ColoredBox(
      color: DesktopTheme.background,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final heroHeight = constraints.maxHeight >= 900 ? 634.0 : 522.0;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(36, 28, 32, 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 60,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(),
                    if (candidates.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _recoveryAlert(candidates),
                    ],
                    const SizedBox(height: 20),
                    if (constraints.maxWidth >= 930)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 7,
                            child: _hero(hero, height: heroHeight),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 360,
                            child: Column(
                              children: [
                                _upNext(upNext),
                                const SizedBox(height: 16),
                                _activity(),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _hero(hero, height: heroHeight),
                          const SizedBox(height: 16),
                          _upNext(upNext),
                          const SizedBox(height: 16),
                          _activity(),
                        ],
                      ),
                    const SizedBox(height: 16),
                    _quickActions(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _header() {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good morning'
        : now.hour < 18
        ? 'Good afternoon'
        : 'Good evening';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, Player',
                style: const TextStyle(
                  color: DesktopTheme.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _dateLabel(now),
                style: const TextStyle(
                  color: DesktopTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: DesktopTheme.panel(),
          child: Row(
            children: [
              Icon(
                widget.epicConnected ? Icons.check_circle : Icons.info_outline,
                color: widget.epicConnected
                    ? DesktopTheme.success
                    : DesktopTheme.warning,
                size: 20,
              ),
              const SizedBox(width: 9),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.epicConnected
                        ? 'Sync healthy'
                        : 'Sync needs attention',
                    style: const TextStyle(
                      color: DesktopTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    widget.epicConnected
                        ? 'Epic connected'
                        : 'Open Tools for details',
                    style: const TextStyle(
                      color: DesktopTheme.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _recoveryAlert(List<RecoveryCandidate> candidates) {
    final drive = candidates.first.drive;
    final validCount = candidates
        .where((candidate) => candidate.canRestore)
        .length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF10212D),
        borderRadius: BorderRadius.circular(DesktopTheme.radiusMedium),
        border: Border.all(color: DesktopTheme.borderStrong),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: DesktopTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.storage_rounded,
              color: DesktopTheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${drive.displayName} reconnected — ${candidates.length} game${candidates.length == 1 ? '' : 's'} found',
                  style: const TextStyle(
                    color: DesktopTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  validCount == 0
                      ? 'Detected installs need review; no launcher files will be changed.'
                      : 'No download required. Review $validCount validated match${validCount == 1 ? '' : 'es'} before restoring.',
                  style: const TextStyle(
                    color: DesktopTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: widget.onOpenDiskDiscovery,
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: const Text('Review'),
            style: FilledButton.styleFrom(
              backgroundColor: DesktopTheme.primaryStrong,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero(GameInfo? game, {required double height}) {
    final image = game == null ? null : _heroImage(game);
    final progress = game == null
        ? null
        : widget.progressByCatalogItemId[game.catalogItemId];
    final percent = _progressFraction(progress?.achievementPercent);
    return Container(
      height: height,
      decoration: DesktopTheme.panel(emphasized: true),
      clipBehavior: Clip.antiAlias,
      child: game == null
          ? _emptyHero()
          : Stack(
              fit: StackFit.expand,
              children: [
                if (image != null)
                  Image.network(
                    ImageUtils.getOptimizedUrl(image, width: 1100, height: 760),
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                    errorBuilder: (_, _, _) =>
                        const ColoredBox(color: DesktopTheme.surfaceRaised),
                  )
                else
                  const ColoredBox(color: DesktopTheme.surfaceRaised),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xF7081119),
                        Color(0xD9081119),
                        Color(0x33081119),
                      ],
                      stops: [0, 0.5, 1],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 360,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'PLAY NEXT',
                            style: TextStyle(
                              color: DesktopTheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            game.displayName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: DesktopTheme.textPrimary,
                              fontSize: 48,
                              height: 1.05,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.3,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              const Icon(
                                Icons.schedule,
                                color: DesktopTheme.textSecondary,
                                size: 17,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _lastPlayedLabel(game),
                                style: const TextStyle(
                                  color: DesktopTheme.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          Text(
                            percent == null
                                ? 'Ready when you are.'
                                : 'Continue your progress where you left off.',
                            style: const TextStyle(
                              color: DesktopTheme.textSecondary,
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                          if (percent != null) ...[
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Achievement progress',
                                    style: TextStyle(
                                      color: DesktopTheme.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${(percent * 100).round()}%',
                                  style: const TextStyle(
                                    color: DesktopTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                minHeight: 6,
                                value: percent,
                                color: DesktopTheme.primary,
                                backgroundColor: DesktopTheme.border,
                              ),
                            ),
                          ],
                          const SizedBox(height: 32),
                          SizedBox(
                            width: 276,
                            child: FilledButton.icon(
                              onPressed: () => _launch(game),
                              icon: const Icon(
                                Icons.play_arrow_rounded,
                                size: 25,
                              ),
                              label: const Text('Play'),
                              style: FilledButton.styleFrom(
                                backgroundColor: DesktopTheme.primaryStrong,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 19,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () => widget.onOpenGameDetails(game),
                            icon: const Icon(Icons.info_outline, size: 18),
                            label: const Text('More details'),
                            style: TextButton.styleFrom(
                              foregroundColor: DesktopTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _emptyHero() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.sports_esports_outlined,
            color: DesktopTheme.textMuted,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'No playable games found',
            style: TextStyle(
              color: DesktopTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Open Library or use Disk Discovery to find an installation.',
            style: TextStyle(color: DesktopTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: widget.onOpenLibrary,
            child: const Text('Open Library'),
          ),
        ],
      ),
    );
  }

  Widget _upNext(List<GameInfo> games) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: DesktopTheme.panel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'UP NEXT',
            style: TextStyle(
              color: DesktopTheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.7,
            ),
          ),
          const SizedBox(height: 14),
          if (games.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Text(
                'Playtime and progress will shape suggestions here.',
                style: TextStyle(color: DesktopTheme.textSecondary),
              ),
            )
          else
            for (var index = 0; index < games.length; index++)
              _queueRow(games[index], index + 1),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: widget.onOpenLibrary,
            child: const Text('Browse library'),
          ),
        ],
      ),
    );
  }

  Widget _queueRow(GameInfo game, int index) {
    final cover =
        game.metadata?.dieselGameBoxTall ?? game.metadata?.firstImageUrl;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => widget.onOpenGameDetails(game),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: DesktopTheme.surfaceRaised,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: DesktopTheme.border),
                ),
                child: Text(
                  '$index',
                  style: const TextStyle(
                    color: DesktopTheme.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: SizedBox(
                  width: 72,
                  height: 48,
                  child: cover == null
                      ? const ColoredBox(color: DesktopTheme.surfaceRaised)
                      : Image.network(
                          ImageUtils.getOptimizedUrl(
                            cover,
                            width: 160,
                            height: 100,
                          ),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const ColoredBox(
                            color: DesktopTheme.surfaceRaised,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: DesktopTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _queueReason(game),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: DesktopTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _activity() {
    final items = _activityItems().take(4).toList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: DesktopTheme.panel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'RECENT ACTIVITY',
            style: TextStyle(
              color: DesktopTheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.7,
            ),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text(
                'Launch a game or reconnect a drive to start your activity history.',
                style: TextStyle(color: DesktopTheme.textSecondary),
              ),
            )
          else
            for (final item in items) _activityRow(item),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: widget.onOpenActivity,
            child: const Text('View all activity'),
          ),
        ],
      ),
    );
  }

  Widget _activityRow(_HomeActivity item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, color: item.color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DesktopTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  item.detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DesktopTheme.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _relativeTime(item.time),
            style: const TextStyle(color: DesktopTheme.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _quickActions() {
    return Container(
      decoration: DesktopTheme.panel(),
      child: Row(
        children: [
          Expanded(
            child: _quickAction(
              Icons.search,
              'Search library',
              'Find any game',
              widget.onOpenLibrary,
            ),
          ),
          const SizedBox(
            height: 60,
            child: VerticalDivider(color: DesktopTheme.border),
          ),
          Expanded(
            child: _quickAction(
              Icons.grid_view_rounded,
              'Browse library',
              '${widget.ownedGamesCount} games',
              widget.onOpenLibrary,
            ),
          ),
          const SizedBox(
            height: 60,
            child: VerticalDivider(color: DesktopTheme.border),
          ),
          Expanded(
            child: _quickAction(
              Icons.storage_rounded,
              'Disk discovery',
              'Find installed games',
              widget.onOpenDiskDiscovery,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAction(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesktopTheme.radiusMedium),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, color: DesktopTheme.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: DesktopTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: DesktopTheme.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<GameInfo> _rankedGames() {
    return _ranker.rank(
      games: widget.installedGames,
      sessions: _sessions,
      progressByCatalogItemId: widget.progressByCatalogItemId,
    );
  }

  List<_HomeActivity> _activityItems() {
    final items = <_HomeActivity>[
      for (final event in _diskEvents)
        _HomeActivity(
          title: event.title,
          detail: event.detail,
          time: event.occurredAt,
          icon: event.type == ActivityEventType.recoveryFailed
              ? Icons.error_outline
              : Icons.storage_rounded,
          color: event.type == ActivityEventType.recoveryFailed
              ? DesktopTheme.danger
              : DesktopTheme.primary,
        ),
      for (final session in _sessions)
        _HomeActivity(
          title: session.isActive
              ? 'Playing ${session.gameName}'
              : 'Played ${session.gameName}',
          detail: session.formattedDuration,
          time: session.startTime,
          icon: Icons.play_arrow_rounded,
          color: DesktopTheme.success,
        ),
    ]..sort((a, b) => b.time.compareTo(a.time));
    return items;
  }

  String? _heroImage(GameInfo game) =>
      game.metadata?.dieselGameBox ??
      game.metadata?.firstImageUrl ??
      game.metadata?.dieselGameBoxTall;

  String _queueReason(GameInfo game) {
    final session = _sessions
        .where((value) => value.gameId == game.catalogItemId)
        .firstOrNull;
    if (session != null) return _relativeTime(session.startTime);
    final progress = _progressFraction(
      widget.progressByCatalogItemId[game.catalogItemId]?.achievementPercent,
    );
    if (progress != null && progress > 0 && progress < 1) {
      return '${(progress * 100).round()}% progress';
    }
    return 'Installed and ready';
  }

  String _lastPlayedLabel(GameInfo game) {
    final session = _sessions
        .where((value) => value.gameId == game.catalogItemId)
        .firstOrNull;
    return session == null
        ? 'Installed and ready'
        : _relativeTime(session.startTime);
  }

  double? _progressFraction(double? value) {
    if (value == null) return null;
    return value > 1 ? (value / 100).clamp(0.0, 1.0) : value.clamp(0.0, 1.0);
  }

  Future<void> _launch(GameInfo game) async {
    final launched = await EpicProtocol.launch(
      EpicProtocol.launchApp(
        game.appName,
        namespace: game.catalogNamespace.isEmpty ? null : game.catalogNamespace,
        itemId: game.catalogItemId.isEmpty ? null : game.catalogItemId,
      ),
    );
    if (!mounted || launched) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not launch ${game.displayName}.'),
        backgroundColor: DesktopTheme.danger,
      ),
    );
  }

  String _dateLabel(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _relativeTime(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays == 1) return 'Yesterday';
    return '${difference.inDays}d ago';
  }
}

class _HomeActivity {
  final String title;
  final String detail;
  final DateTime time;
  final IconData icon;
  final Color color;

  const _HomeActivity({
    required this.title,
    required this.detail,
    required this.time,
    required this.icon,
    required this.color,
  });
}
