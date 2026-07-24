import 'package:flutter/material.dart';

import '../database/database_service.dart';
import '../models/epic_progress.dart';
import '../models/game_info.dart';
import '../theme/desktop_theme.dart';

class DesktopActivityPage extends StatefulWidget {
  final DatabaseService database;
  final List<GameInfo> installedGames;
  final Map<String, EpicGameProgress> progressByCatalogItemId;
  final ValueChanged<String> onOpenGameDetailByCatalogItemId;

  const DesktopActivityPage({
    super.key,
    required this.database,
    required this.installedGames,
    required this.progressByCatalogItemId,
    required this.onOpenGameDetailByCatalogItemId,
  });

  @override
  State<DesktopActivityPage> createState() => _DesktopActivityPageState();
}

class _DesktopActivityPageState extends State<DesktopActivityPage> {
  List<PlaytimeSessionEntry> _sessions = const [];
  List<ActivityEventEntry> _events = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sessions = await widget.database.getRecentSessions(limit: 40);
    final events = await widget.database.getRecentActivityEvents(limit: 30);
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _events = events;
    });
  }

  @override
  Widget build(BuildContext context) {
    final progressGames =
        widget.installedGames
            .where(
              (game) =>
                  widget
                      .progressByCatalogItemId[game.catalogItemId]
                      ?.hasAchievementProgress ==
                  true,
            )
            .toList()
          ..sort((a, b) {
            final aValue =
                widget
                    .progressByCatalogItemId[a.catalogItemId]
                    ?.achievementPercent ??
                0;
            final bValue =
                widget
                    .progressByCatalogItemId[b.catalogItemId]
                    ?.achievementPercent ??
                0;
            return bValue.compareTo(aValue);
          });
    return ColoredBox(
      color: DesktopTheme.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(36, 30, 32, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Activity',
              style: TextStyle(
                color: DesktopTheme.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Real play sessions, recovery events, and current completion signals.',
              style: TextStyle(color: DesktopTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 850) {
                  return Column(
                    children: [
                      _timeline(),
                      const SizedBox(height: 16),
                      _progress(progressGames),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: _timeline()),
                    const SizedBox(width: 16),
                    Expanded(flex: 4, child: _progress(progressGames)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeline() {
    final rows = <_ActivityRow>[
      for (final session in _sessions)
        _ActivityRow(
          title: session.isActive
              ? 'Playing ${session.gameName}'
              : 'Played ${session.gameName}',
          detail: session.formattedDuration,
          time: session.startTime,
          icon: Icons.play_arrow_rounded,
          color: DesktopTheme.success,
        ),
      for (final event in _events)
        _ActivityRow(
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
    ]..sort((a, b) => b.time.compareTo(a.time));
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: DesktopTheme.panel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Recent activity',
            style: TextStyle(
              color: DesktopTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Text(
                'No activity recorded yet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: DesktopTheme.textSecondary),
              ),
            )
          else
            for (final row in rows.take(20))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: row.color.withValues(alpha: 0.12),
                  child: Icon(row.icon, color: row.color, size: 19),
                ),
                title: Text(
                  row.title,
                  style: const TextStyle(
                    color: DesktopTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  row.detail,
                  style: const TextStyle(
                    color: DesktopTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
                trailing: Text(
                  _relativeTime(row.time),
                  style: const TextStyle(
                    color: DesktopTheme.textMuted,
                    fontSize: 10,
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _progress(List<GameInfo> games) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: DesktopTheme.panel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Progress overview',
            style: TextStyle(
              color: DesktopTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          if (games.isEmpty)
            const Text(
              'Official Epic progress will appear after a successful sync.',
              style: TextStyle(color: DesktopTheme.textSecondary),
            )
          else
            for (final game in games.take(12)) _progressRow(game),
        ],
      ),
    );
  }

  Widget _progressRow(GameInfo game) {
    final progress = widget.progressByCatalogItemId[game.catalogItemId]!;
    final raw = progress.achievementPercent ?? 0;
    final value = raw > 1 ? raw / 100 : raw;
    return InkWell(
      onTap: () => widget.onOpenGameDetailByCatalogItemId(game.catalogItemId),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    game.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: DesktopTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${(value * 100).round()}%',
                  style: const TextStyle(
                    color: DesktopTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value.clamp(0.0, 1.0),
                minHeight: 5,
                color: DesktopTheme.primary,
                backgroundColor: DesktopTheme.border,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _relativeTime(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inMinutes < 1) return 'Now';
    if (difference.inHours < 1) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    if (difference.inDays == 1) return 'Yesterday';
    return '${difference.inDays}d';
  }
}

class _ActivityRow {
  final String title;
  final String detail;
  final DateTime time;
  final IconData icon;
  final Color color;

  const _ActivityRow({
    required this.title,
    required this.detail,
    required this.time,
    required this.icon,
    required this.color,
  });
}
