import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import '../services/epic_auth_service.dart';
import '../services/sync_queue_service.dart';

enum CloudSyncFilter {
  all('All'),
  pending('Pending'),
  running('Running'),
  uploaded('Uploaded'),
  exists('Exists'),
  failed('Failed'),
  skipped('Skipped'),
  removed('Removed');

  const CloudSyncFilter(this.label);
  final String label;
}

class CloudSyncPage extends StatefulWidget {
  final EpicAuthService? authService;
  final SyncQueueService syncQueueService;

  const CloudSyncPage({
    super.key,
    required this.authService,
    required this.syncQueueService,
  });

  @override
  State<CloudSyncPage> createState() => _CloudSyncPageState();
}

class _CloudSyncPageState extends State<CloudSyncPage> {
  final Set<String> _selected = {};
  CloudSyncFilter _filter = CloudSyncFilter.all;
  Timer? _ticker;
  bool _loggingIn = false;

  @override
  void initState() {
    super.initState();
    widget.syncQueueService.addListener(_onQueueChanged);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && widget.syncQueueService.runStartedAt != null) {
        setState(() {});
      }
    });
    unawaited(_loadAuth());
  }

  @override
  void didUpdateWidget(covariant CloudSyncPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.syncQueueService != widget.syncQueueService) {
      oldWidget.syncQueueService.removeListener(_onQueueChanged);
      widget.syncQueueService.addListener(_onQueueChanged);
      _selected.clear();
    }
  }

  @override
  void dispose() {
    widget.syncQueueService.removeListener(_onQueueChanged);
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _loadAuth() async {
    await widget.authService?.loadTokens();
    if (mounted) setState(() {});
  }

  void _onQueueChanged() {
    if (!mounted) return;
    final available = widget.syncQueueService.queue.map((e) => e.identityKey);
    _selected.removeWhere((id) => !available.contains(id));
    setState(() {});
  }

  Future<void> _login() async {
    final auth = widget.authService;
    if (auth == null || _loggingIn) return;
    setState(() => _loggingIn = true);
    try {
      await auth.login();
    } finally {
      if (mounted) setState(() => _loggingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final queue = widget.syncQueueService;
    final auth = widget.authService;
    final isAuthenticated = auth?.isAuthenticated ?? false;
    final visibleEntries = queue.queue
        .where(_matchesFilter)
        .toList(growable: false);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(queue, isAuthenticated),
          const SizedBox(height: 16),
          _buildToolbar(queue, isAuthenticated),
          const SizedBox(height: 16),
          _buildFilters(queue),
          const SizedBox(height: 12),
          Expanded(child: _buildQueuePanel(queue, visibleEntries)),
          const SizedBox(height: 16),
          _buildLogPanel(queue),
        ],
      ),
    );
  }

  Widget _buildHeader(SyncQueueService queue, bool isAuthenticated) {
    final progress = queue.total > 0 ? queue.completed / queue.total : 0.0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(
                  Icons.cloud_sync_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cloud Sync',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _headerSubtitle(queue, isAuthenticated),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              _metric('State', _statusLabel(queue.status)),
              const SizedBox(width: 12),
              _metric('Elapsed', _elapsedLabel(queue)),
              const SizedBox(width: 12),
              _metric('Items', '${queue.completed}/${queue.total}'),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: queue.status == SyncQueueStatus.fetchingLibrary
                  ? null
                  : progress,
              minHeight: 6,
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(SyncQueueService queue, bool isAuthenticated) {
    final selectedEligible = _selected.where((id) {
      final entry = _entryById(id);
      return entry != null && !entry.isRunning;
    }).toSet();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _actionButton(
          icon: isAuthenticated ? Icons.sync_rounded : Icons.login_rounded,
          label: isAuthenticated ? 'Start Full Sync' : 'Login',
          onPressed: queue.canStart
              ? () {
                  if (isAuthenticated) {
                    unawaited(queue.startSync());
                  } else {
                    unawaited(_login());
                  }
                }
              : null,
          primary: true,
          loading: _loggingIn,
        ),
        _actionButton(
          icon: Icons.pause_rounded,
          label: 'Pause',
          onPressed: queue.canPause ? queue.pause : null,
        ),
        _actionButton(
          icon: Icons.play_arrow_rounded,
          label: 'Resume',
          onPressed: queue.canResume ? () => unawaited(queue.resume()) : null,
        ),
        _actionButton(
          icon: Icons.close_rounded,
          label: 'Cancel',
          onPressed: queue.canCancel ? queue.cancel : null,
          danger: true,
        ),
        _actionButton(
          icon: Icons.replay_rounded,
          label: 'Retry Failed',
          onPressed: queue.canRetryFailed
              ? () => unawaited(queue.retryFailed())
              : null,
        ),
        _actionButton(
          icon: Icons.restart_alt_rounded,
          label: 'Retry Selected',
          onPressed: selectedEligible.isNotEmpty
              ? () => unawaited(queue.retryEntries(selectedEligible))
              : null,
        ),
        _actionButton(
          icon: Icons.remove_circle_outline_rounded,
          label: 'Remove Selected',
          onPressed: selectedEligible.isNotEmpty
              ? () {
                  queue.removeEntries(selectedEligible);
                  _selected.removeAll(selectedEligible);
                }
              : null,
        ),
        _actionButton(
          icon: Icons.done_all_rounded,
          label: 'Clear Completed',
          onPressed: queue.canClearCompleted ? queue.clearCompleted : null,
        ),
        _actionButton(
          icon: Icons.delete_outline_rounded,
          label: 'Reset',
          onPressed: !queue.isRunning && queue.queue.isNotEmpty
              ? () {
                  queue.reset();
                  _selected.clear();
                }
              : null,
          danger: true,
        ),
      ],
    );
  }

  Widget _buildFilters(SyncQueueService queue) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final filter in CloudSyncFilter.values)
          FilterChip(
            label: Text('${filter.label} ${_filterCount(queue, filter)}'),
            selected: _filter == filter,
            onSelected: (_) => setState(() => _filter = filter),
            backgroundColor: AppColors.surface,
            selectedColor: AppColors.primary.withValues(alpha: 0.16),
            checkmarkColor: AppColors.primary,
            side: BorderSide(
              color: _filter == filter ? AppColors.primary : AppColors.border,
            ),
            labelStyle: TextStyle(
              color: _filter == filter
                  ? AppColors.primary
                  : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _buildQueuePanel(
    SyncQueueService queue,
    List<SyncQueueEntry> visibleEntries,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 40,
            color: AppColors.surfaceLight.withValues(alpha: 0.45),
            child: Row(
              children: [
                const SizedBox(width: 44),
                _headerCell('Item', flex: 4),
                _headerCell('Namespace', flex: 2),
                _headerCell('Attempts', flex: 1),
                _headerCell('Duration', flex: 1),
                _headerCell('Message', flex: 3),
              ],
            ),
          ),
          Expanded(
            child: visibleEntries.isEmpty
                ? _emptyQueue(queue)
                : ListView.builder(
                    itemCount: visibleEntries.length,
                    itemBuilder: (context, index) {
                      final entry = visibleEntries[index];
                      return _queueRow(entry, index.isEven);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _queueRow(SyncQueueEntry entry, bool even) {
    final selected = _selected.contains(entry.identityKey);
    final canSelect = !entry.isRunning;
    return Container(
      height: 58,
      color: selected
          ? AppColors.primary.withValues(alpha: 0.08)
          : even
          ? AppColors.background.withValues(alpha: 0.16)
          : Colors.transparent,
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Checkbox(
              value: selected,
              onChanged: canSelect
                  ? (value) {
                      setState(() {
                        if (value == true) {
                          _selected.add(entry.identityKey);
                        } else {
                          _selected.remove(entry.identityKey);
                        }
                      });
                    }
                  : null,
              activeColor: AppColors.primary,
            ),
          ),
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Icon(
                  _stateIcon(entry.state),
                  color: _stateColor(entry.state),
                  size: 18,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.displayTitle,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _bodyCell(entry.item.namespace, flex: 2),
          _bodyCell('${entry.attempts}', flex: 1),
          _bodyCell(_durationLabel(entry.duration), flex: 1),
          _bodyCell(entry.message, flex: 3),
        ],
      ),
    );
  }

  Widget _buildLogPanel(SyncQueueService queue) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Sync Logs',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: queue.logs.isEmpty
                      ? null
                      : () {
                          Clipboard.setData(
                            ClipboardData(text: queue.logs.join('\n')),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sync logs copied')),
                          );
                        },
                  icon: const Icon(Icons.copy_rounded, size: 15),
                  label: const Text('Copy'),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.border),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              itemCount: queue.logEntries.length,
              itemBuilder: (context, index) {
                final log = queue.logEntries[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '[${log.timestampLabel}] ${log.message}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontFamily: 'JetBrainsMono',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyQueue(SyncQueueService queue) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_queue_rounded,
            size: 46,
            color: AppColors.textMuted.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 10),
          Text(
            queue.queue.isEmpty ? 'No sync queue yet' : 'No rows match filter',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Container(
      constraints: const BoxConstraints(minWidth: 92),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool primary = false,
    bool danger = false,
    bool loading = false,
  }) {
    final foreground = danger
        ? AppColors.error
        : primary
        ? Colors.black
        : AppColors.textPrimary;
    final background = primary ? AppColors.primary : AppColors.surface;
    return SizedBox(
      height: 38,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foreground,
                ),
              )
            : Icon(icon, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: AppColors.surfaceLight,
          disabledForegroundColor: AppColors.textMuted,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          side: BorderSide(color: danger ? AppColors.error : AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _headerCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _bodyCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: Text(
          text,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  bool _matchesFilter(SyncQueueEntry entry) {
    return _matchesFilterValue(entry, _filter);
  }

  bool _matchesFilterValue(SyncQueueEntry entry, CloudSyncFilter filter) {
    return switch (filter) {
      CloudSyncFilter.all => true,
      CloudSyncFilter.pending => entry.state == SyncQueueEntryState.pending,
      CloudSyncFilter.running => entry.state == SyncQueueEntryState.running,
      CloudSyncFilter.uploaded => entry.state == SyncQueueEntryState.uploaded,
      CloudSyncFilter.exists =>
        entry.state == SyncQueueEntryState.alreadyUploaded,
      CloudSyncFilter.failed => entry.state == SyncQueueEntryState.failed,
      CloudSyncFilter.skipped => entry.state == SyncQueueEntryState.skipped,
      CloudSyncFilter.removed => entry.state == SyncQueueEntryState.removed,
    };
  }

  int _filterCount(SyncQueueService queue, CloudSyncFilter filter) {
    return queue.queue
        .where((entry) => _matchesFilterValue(entry, filter))
        .length;
  }

  SyncQueueEntry? _entryById(String id) {
    for (final entry in widget.syncQueueService.queue) {
      if (entry.identityKey == id) return entry;
    }
    return null;
  }

  String _headerSubtitle(SyncQueueService queue, bool isAuthenticated) {
    if (!isAuthenticated) return 'Epic account disconnected';
    if (queue.statusMessage.isNotEmpty) return queue.statusMessage;
    return 'Epic account connected';
  }

  String _statusLabel(SyncQueueStatus status) {
    return switch (status) {
      SyncQueueStatus.idle => 'Idle',
      SyncQueueStatus.fetchingLibrary => 'Fetching',
      SyncQueueStatus.syncing => 'Syncing',
      SyncQueueStatus.paused => 'Paused',
      SyncQueueStatus.completed => 'Completed',
      SyncQueueStatus.failed => 'Failed',
      SyncQueueStatus.cancelled => 'Cancelled',
    };
  }

  IconData _stateIcon(SyncQueueEntryState state) {
    return switch (state) {
      SyncQueueEntryState.pending => Icons.schedule_rounded,
      SyncQueueEntryState.running => Icons.sync_rounded,
      SyncQueueEntryState.uploaded => Icons.check_circle_rounded,
      SyncQueueEntryState.alreadyUploaded => Icons.info_rounded,
      SyncQueueEntryState.failed => Icons.error_rounded,
      SyncQueueEntryState.skipped => Icons.block_rounded,
      SyncQueueEntryState.cancelled => Icons.cancel_rounded,
      SyncQueueEntryState.removed => Icons.remove_circle_rounded,
    };
  }

  Color _stateColor(SyncQueueEntryState state) {
    return switch (state) {
      SyncQueueEntryState.pending => AppColors.textMuted,
      SyncQueueEntryState.running => AppColors.primary,
      SyncQueueEntryState.uploaded => AppColors.success,
      SyncQueueEntryState.alreadyUploaded => AppColors.textSecondary,
      SyncQueueEntryState.failed => AppColors.error,
      SyncQueueEntryState.skipped => AppColors.warning,
      SyncQueueEntryState.cancelled => AppColors.error,
      SyncQueueEntryState.removed => AppColors.textMuted,
    };
  }

  String _elapsedLabel(SyncQueueService queue) {
    final start = queue.runStartedAt;
    if (start == null) return '0s';
    final end = queue.runFinishedAt ?? DateTime.now();
    return _durationLabel(end.difference(start));
  }

  String _durationLabel(Duration? duration) {
    if (duration == null) return '-';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 0) return '${minutes}m ${seconds}s';
    return '${seconds}s';
  }
}
