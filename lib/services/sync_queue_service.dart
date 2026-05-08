import 'dart:async';

import 'package:flutter/foundation.dart';

import '../database/database_service.dart';
import '../models/epic_library_item.dart';
import '../models/upload_status.dart';
import 'analytics_service.dart';
import 'api_service.dart';
import 'epic_auth_service.dart';
import 'epic_library_service.dart';
import 'epic_manifest_service.dart';
import 'upload_service.dart';

enum SyncQueueStatus {
  idle,
  fetchingLibrary,
  syncing,
  paused,
  completed,
  failed,
  cancelled,
}

enum SyncQueueEntryState {
  pending,
  running,
  uploaded,
  alreadyUploaded,
  failed,
  skipped,
  cancelled,
  removed,
}

class SyncQueueLogEntry {
  final DateTime timestamp;
  final String message;

  const SyncQueueLogEntry({required this.timestamp, required this.message});

  String get timestampLabel {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final second = timestamp.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  String get formatted => '[$timestampLabel] $message';
}

class SyncQueueEntry {
  final EpicLibraryItem item;
  final String identityKey;
  late final String displayTitle;
  SyncQueueEntryState state;
  UploadStatusType status;
  String message;
  int attempts;
  DateTime? startedAt;
  DateTime? finishedAt;

  SyncQueueEntry({
    required this.item,
    String? identityKey,
    this.state = SyncQueueEntryState.pending,
    this.status = UploadStatusType.pending,
    this.message = '',
    this.attempts = 0,
    this.startedAt,
    this.finishedAt,
    String? displayTitle,
  }) : identityKey =
           identityKey ??
           OwnedGameEntry.makeIdentityKey(
             namespace: item.namespace,
             catalogItemId: item.catalogItemId,
             appName: item.appName,
             assetId: item.assetId,
           ) {
    this.displayTitle =
        _friendlyTitle(displayTitle, item) ??
        _friendlyTitle(item.title, item) ??
        'Unknown item';
  }

  bool get isActive => state != SyncQueueEntryState.removed;
  bool get isRunning => state == SyncQueueEntryState.running;
  bool get canRetry =>
      state == SyncQueueEntryState.failed ||
      state == SyncQueueEntryState.skipped ||
      state == SyncQueueEntryState.cancelled;
  bool get canRemove => isActive && !isRunning;
  bool get isComplete =>
      state == SyncQueueEntryState.uploaded ||
      state == SyncQueueEntryState.alreadyUploaded;
  bool get isTerminal =>
      isComplete ||
      state == SyncQueueEntryState.failed ||
      state == SyncQueueEntryState.skipped ||
      state == SyncQueueEntryState.cancelled;

  Duration? get duration {
    final started = startedAt;
    if (started == null) return null;
    return (finishedAt ?? DateTime.now()).difference(started);
  }

  static String? _friendlyTitle(String? candidate, EpicLibraryItem item) {
    final title = candidate?.trim();
    if (title == null || title.isEmpty) return null;
    final normalized = title.toLowerCase();
    final technicalValues = {
      item.appName.trim().toLowerCase(),
      item.catalogItemId.trim().toLowerCase(),
      item.assetId.trim().toLowerCase(),
    }..remove('');
    if (technicalValues.contains(normalized)) return null;
    return title;
  }
}

class SyncQueueService extends ChangeNotifier {
  final EpicAuthService authService;
  final UploadService uploadService;
  final DatabaseService? db;
  final Future<List<EpicLibraryItem>> Function()? libraryLoader;
  final Future<List<int>?> Function(EpicLibraryItem item)? manifestLoader;
  final Future<Map<String, String>> Function(Iterable<String> catalogItemIds)?
  titleLoader;
  final Duration delayBetweenItems;
  final int syncConcurrency;

  SyncQueueStatus _status = SyncQueueStatus.idle;
  final List<SyncQueueEntry> _queue = [];
  int _completed = 0;
  String _statusMessage = '';
  final List<SyncQueueLogEntry> _logs = [];
  bool _cancelRequested = false;
  bool _pauseRequested = false;
  bool _processing = false;
  DateTime? _runStartedAt;
  DateTime? _runFinishedAt;

  SyncQueueStatus get status => _status;
  List<SyncQueueEntry> get queue => List.unmodifiable(_queue);
  List<SyncQueueEntry> get activeQueue =>
      _queue.where((entry) => entry.isActive).toList(growable: false);
  int get completed => _completed;
  int get total => activeQueue.length;
  String get statusMessage => _statusMessage;
  List<SyncQueueLogEntry> get logEntries => List.unmodifiable(_logs);
  List<String> get logs =>
      _logs.map((entry) => entry.formatted).toList(growable: false);
  DateTime? get runStartedAt => _runStartedAt;
  DateTime? get runFinishedAt => _runFinishedAt;
  SyncQueueEntry? get currentEntry {
    for (final entry in _queue) {
      if (entry.isRunning) return entry;
    }
    return null;
  }

  Set<String> get syncingIdentityKeys =>
      _status == SyncQueueStatus.syncing || _status == SyncQueueStatus.paused
      ? _queue
            .where((entry) => entry.state == SyncQueueEntryState.running)
            .map((entry) => entry.identityKey)
            .toSet()
      : const {};

  Map<String, UploadStatus> get ownedUploadStatuses => {
    for (final entry in _queue)
      if (entry.isActive)
        entry.identityKey: UploadStatus(
          status: entry.status,
          message: entry.message,
        ),
  };

  bool get isRunning =>
      _status == SyncQueueStatus.fetchingLibrary ||
      _status == SyncQueueStatus.syncing;
  bool get isPaused => _status == SyncQueueStatus.paused;
  bool get hasQueue => _queue.any((entry) => entry.isActive);
  bool get canStart => !isRunning && !isPaused;
  bool get canPause => _status == SyncQueueStatus.syncing;
  bool get canResume =>
      _status == SyncQueueStatus.paused ||
      (!_processing &&
          _queue.any((entry) => entry.state == SyncQueueEntryState.pending));
  bool get canCancel => isRunning || isPaused;
  bool get canRetryFailed =>
      !isRunning && _queue.any((entry) => entry.canRetry);
  bool get canClearCompleted =>
      !isRunning && _queue.any((entry) => entry.isComplete);

  SyncQueueService({
    required this.authService,
    required this.uploadService,
    this.db,
    this.libraryLoader,
    this.manifestLoader,
    this.titleLoader,
    this.delayBetweenItems = const Duration(seconds: 2),
    this.syncConcurrency = 5,
  });

  void _addLog(String message) {
    _logs.insert(
      0,
      SyncQueueLogEntry(timestamp: DateTime.now(), message: message),
    );
    if (_logs.length > 200) _logs.removeLast();
    notifyListeners();
  }

  Future<void> startSync({List<EpicLibraryItem>? items}) async {
    if (isRunning) return;

    _cancelRequested = false;
    _pauseRequested = false;
    _queue.clear();
    _completed = 0;
    _logs.clear();
    _runStartedAt = DateTime.now();
    _runFinishedAt = null;
    _status = SyncQueueStatus.fetchingLibrary;
    _statusMessage = 'Fetching library...';
    notifyListeners();

    try {
      final library =
          items ??
          (libraryLoader != null
              ? await libraryLoader!()
              : await EpicLibraryService(
                  authService: authService,
                ).getLibrary());

      if (_cancelRequested) {
        _status = SyncQueueStatus.cancelled;
        _statusMessage = 'Sync cancelled';
        _runFinishedAt = DateTime.now();
        notifyListeners();
        return;
      }

      final titleById = await _loadItemTitles(library);

      for (final item in library) {
        if (item.namespace.toLowerCase() == 'ue') continue;
        _queue.add(
          SyncQueueEntry(
            item: item,
            displayTitle: titleById[item.catalogItemId],
          ),
        );
      }

      _status = SyncQueueStatus.syncing;
      _statusMessage = 'Syncing ${activeQueue.length} items...';
      _addLog('Found ${activeQueue.length} items in library');
      await _processPending();
    } catch (e) {
      _status = SyncQueueStatus.failed;
      _statusMessage = 'Sync failed: $e';
      _runFinishedAt = DateTime.now();
      _addLog('Sync error: $e');
      notifyListeners();
    }
  }

  Future<Map<String, String>> _loadItemTitles(
    List<EpicLibraryItem> items,
  ) async {
    final ids = items
        .map((item) => item.catalogItemId)
        .where((id) => id.trim().isNotEmpty)
        .toSet();
    if (ids.isEmpty) return const {};

    try {
      if (titleLoader != null) return await titleLoader!(ids);
      final itemMetadata = await ApiService().bulkGetItems(ids);
      return {
        for (final entry in itemMetadata.entries)
          if ((entry.value.title ?? '').trim().isNotEmpty)
            entry.key: entry.value.title!.trim(),
      };
    } catch (e) {
      _addLog('Item title lookup failed: $e');
      return const {};
    }
  }

  void pause() {
    if (!canPause) return;
    _pauseRequested = true;
    _statusMessage = 'Pausing after current items...';
    _addLog('Pausing sync after current items...');
    notifyListeners();
  }

  Future<void> resume() async {
    if (!canResume || _processing) return;
    _cancelRequested = false;
    _pauseRequested = false;
    _status = SyncQueueStatus.syncing;
    _runStartedAt ??= DateTime.now();
    _runFinishedAt = null;
    _addLog('Resuming sync...');
    notifyListeners();
    await _processPending();
  }

  void cancel() {
    if (!canCancel) return;
    _cancelRequested = true;
    _pauseRequested = false;
    _addLog('Cancelling sync...');
    if (_status == SyncQueueStatus.paused) {
      _cancelPendingEntries();
      _status = SyncQueueStatus.cancelled;
      _statusMessage = 'Sync cancelled';
      _runFinishedAt = DateTime.now();
      notifyListeners();
    }
  }

  Future<void> retryFailed() async {
    final ids = _queue
        .where((entry) => entry.canRetry)
        .map((entry) => entry.identityKey)
        .toSet();
    await retryEntries(ids);
  }

  Future<void> retryEntries(Set<String> identityKeys) async {
    if (identityKeys.isEmpty) return;
    var resetCount = 0;
    for (final entry in _queue) {
      if (!identityKeys.contains(entry.identityKey) || entry.isRunning) {
        continue;
      }
      if (!entry.canRetry && entry.state != SyncQueueEntryState.removed) {
        continue;
      }
      _resetEntryForRetry(entry);
      resetCount++;
    }
    if (resetCount == 0) return;
    _completed = _calculateCompleted();
    _status = SyncQueueStatus.syncing;
    _runStartedAt ??= DateTime.now();
    _runFinishedAt = null;
    _cancelRequested = false;
    _pauseRequested = false;
    _addLog('Retrying $resetCount item${resetCount == 1 ? '' : 's'}...');
    notifyListeners();
    if (!_processing) {
      await _processPending();
    }
  }

  void removeEntries(Set<String> identityKeys) {
    if (identityKeys.isEmpty) return;
    var removed = 0;
    for (final entry in _queue) {
      if (!identityKeys.contains(entry.identityKey) || !entry.canRemove) {
        continue;
      }
      entry.state = SyncQueueEntryState.removed;
      entry.status = UploadStatusType.failed;
      entry.message = 'Removed from queue';
      entry.finishedAt = DateTime.now();
      removed++;
    }
    if (removed == 0) return;
    _completed = _calculateCompleted();
    _addLog('Removed $removed item${removed == 1 ? '' : 's'} from queue');
    _finalizeIfNoWork();
    notifyListeners();
  }

  void clearCompleted() {
    if (isRunning) return;
    final ids = _queue
        .where((entry) => entry.isComplete)
        .map((entry) => entry.identityKey)
        .toSet();
    removeEntries(ids);
  }

  void reset() {
    if (isRunning) return;
    _status = SyncQueueStatus.idle;
    _queue.clear();
    _completed = 0;
    _statusMessage = '';
    _logs.clear();
    _cancelRequested = false;
    _pauseRequested = false;
    _processing = false;
    _runStartedAt = null;
    _runFinishedAt = null;
    notifyListeners();
  }

  Future<void> _processPending() async {
    if (_processing) return;
    _processing = true;
    try {
      final workerCount = syncConcurrency.clamp(1, 16).toInt();
      await Future.wait(
        List.generate(workerCount, (_) => _processPendingWorker()),
      );

      if (_cancelRequested) {
        _cancelPendingEntries();
        _status = SyncQueueStatus.cancelled;
        _statusMessage = 'Sync cancelled';
        _runFinishedAt = DateTime.now();
        notifyListeners();
        return;
      }

      if (_pauseRequested && _nextPendingEntry() != null) {
        _status = SyncQueueStatus.paused;
        _statusMessage = 'Sync paused';
        _addLog('Sync paused');
        notifyListeners();
        return;
      }

      await _completeRun();
    } finally {
      _processing = false;
    }
  }

  Future<void> _processPendingWorker() async {
    while (true) {
      if (_cancelRequested || _pauseRequested) return;

      final entry = _nextPendingEntry();
      if (entry == null) return;

      await _processEntry(entry);

      if (delayBetweenItems > Duration.zero &&
          _nextPendingEntry() != null &&
          !_cancelRequested &&
          !_pauseRequested) {
        await Future.delayed(delayBetweenItems);
      }
    }
  }

  SyncQueueEntry? _nextPendingEntry() {
    for (final entry in _queue) {
      if (entry.state == SyncQueueEntryState.pending) return entry;
    }
    return null;
  }

  Future<void> _processEntry(SyncQueueEntry entry) async {
    entry.state = SyncQueueEntryState.running;
    entry.status = UploadStatusType.uploading;
    entry.message = 'Syncing...';
    entry.attempts++;
    entry.startedAt = DateTime.now();
    entry.finishedAt = null;
    _updateSyncingStatusMessage(entry);
    notifyListeners();

    try {
      final manifestBytes = await _loadManifest(entry.item);
      if (manifestBytes == null) {
        await _setEntryStatus(
          entry,
          UploadStatus(
            status: UploadStatusType.failed,
            message: 'No cloud manifest found',
          ),
          state: SyncQueueEntryState.skipped,
        );
        _addLog('Skipped: ${entry.displayTitle} (no manifest)');
      } else {
        final result = await uploadService.uploadCloudManifest(
          entry.item,
          manifestBytes,
        );
        await _setEntryStatus(entry, result);
        switch (entry.state) {
          case SyncQueueEntryState.uploaded:
            _addLog('Uploaded: ${entry.displayTitle}');
          case SyncQueueEntryState.alreadyUploaded:
            _addLog('Already exists: ${entry.displayTitle}');
          default:
            _addLog('Failed: ${entry.displayTitle} - ${result.message}');
        }
      }
    } catch (e) {
      await _setEntryStatus(
        entry,
        UploadStatus(status: UploadStatusType.failed, message: '$e'),
      );
      _addLog('Failed: ${entry.displayTitle} - $e');
    }

    _completed = _calculateCompleted();
    _updateSyncingStatusMessage();
    notifyListeners();
  }

  void _updateSyncingStatusMessage([SyncQueueEntry? newestEntry]) {
    final running = _queue.where((entry) => entry.isRunning).length;
    if (running > 1) {
      _statusMessage = 'Syncing $running items...';
      return;
    }
    final entry = newestEntry ?? currentEntry;
    if (entry != null) {
      _statusMessage = 'Syncing ${entry.displayTitle}...';
    }
  }

  Future<List<int>?> _loadManifest(EpicLibraryItem item) {
    final loader = manifestLoader;
    if (loader != null) return loader(item);
    return EpicManifestService(
      authService: authService,
    ).getManifestForLibraryItem(item);
  }

  Future<void> _setEntryStatus(
    SyncQueueEntry entry,
    UploadStatus status, {
    SyncQueueEntryState? state,
  }) async {
    entry.status = status.status;
    entry.message = status.message;
    entry.state = state ?? _stateForUploadStatus(status.status);
    entry.finishedAt = DateTime.now();
    await db?.updateOwnedGameUploadStatus(entry.identityKey, status);
  }

  SyncQueueEntryState _stateForUploadStatus(UploadStatusType status) {
    return switch (status) {
      UploadStatusType.uploaded => SyncQueueEntryState.uploaded,
      UploadStatusType.alreadyUploaded => SyncQueueEntryState.alreadyUploaded,
      UploadStatusType.failed => SyncQueueEntryState.failed,
      UploadStatusType.pending => SyncQueueEntryState.pending,
      UploadStatusType.uploading => SyncQueueEntryState.running,
    };
  }

  void _resetEntryForRetry(SyncQueueEntry entry) {
    entry.state = SyncQueueEntryState.pending;
    entry.status = UploadStatusType.pending;
    entry.message = '';
    entry.startedAt = null;
    entry.finishedAt = null;
  }

  void _cancelPendingEntries() {
    for (final entry in _queue) {
      if (entry.state == SyncQueueEntryState.pending) {
        entry.state = SyncQueueEntryState.cancelled;
        entry.status = UploadStatusType.failed;
        entry.message = 'Cancelled';
        entry.finishedAt = DateTime.now();
      }
    }
    _completed = _calculateCompleted();
  }

  int _calculateCompleted() {
    return _queue.where((entry) => entry.isActive && entry.isTerminal).length;
  }

  Future<void> _completeRun() async {
    final active = activeQueue;
    final successCount = active.where((entry) => entry.isComplete).length;
    if (active.isNotEmpty) {
      await AnalyticsService().logManifestUpload(
        count: active.length,
        success: successCount == active.length,
      );
    }
    _completed = _calculateCompleted();
    _status = SyncQueueStatus.completed;
    _statusMessage =
        'Sync completed ($successCount/${active.length} successful)';
    _runFinishedAt = DateTime.now();
    _addLog(_statusMessage);
    notifyListeners();
  }

  void _finalizeIfNoWork() {
    if (isRunning || isPaused) return;
    final hasPending = _queue.any(
      (entry) => entry.state == SyncQueueEntryState.pending,
    );
    if (hasPending) return;
    if (!hasQueue) {
      _status = SyncQueueStatus.idle;
      _statusMessage = '';
      _completed = 0;
      return;
    }
    _completed = _calculateCompleted();
  }
}
