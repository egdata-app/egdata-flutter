import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/epic_library_item.dart';
import '../models/upload_status.dart';
import 'epic_auth_service.dart';
import 'epic_library_service.dart';
import 'epic_manifest_service.dart';
import 'upload_service.dart';
import 'analytics_service.dart';

enum SyncQueueStatus {
  idle,
  fetchingLibrary,
  syncing,
  completed,
  failed,
  cancelled,
}

class SyncQueueEntry {
  final EpicLibraryItem item;
  UploadStatusType status;
  String message;

  SyncQueueEntry({
    required this.item,
    this.status = UploadStatusType.pending,
    this.message = '',
  });
}

class SyncQueueService extends ChangeNotifier {
  final EpicAuthService authService;
  final UploadService uploadService;

  SyncQueueStatus _status = SyncQueueStatus.idle;
  final List<SyncQueueEntry> _queue = [];
  int _completed = 0;
  String _statusMessage = '';
  final List<String> _logs = [];
  bool _cancelRequested = false;

  static const _delayBetweenItems = Duration(seconds: 2);

  SyncQueueStatus get status => _status;
  List<SyncQueueEntry> get queue => List.unmodifiable(_queue);
  int get completed => _completed;
  int get total => _queue.length;
  String get statusMessage => _statusMessage;
  List<String> get logs => List.unmodifiable(_logs);
  bool get isRunning =>
      _status == SyncQueueStatus.fetchingLibrary ||
      _status == SyncQueueStatus.syncing;

  SyncQueueService({required this.authService, required this.uploadService});

  void _addLog(String message) {
    _logs.insert(0, message);
    if (_logs.length > 100) _logs.removeLast();
    notifyListeners();
  }

  Future<void> startSync() async {
    if (isRunning) return;

    _cancelRequested = false;
    _queue.clear();
    _completed = 0;
    _logs.clear();
    _status = SyncQueueStatus.fetchingLibrary;
    _statusMessage = 'Fetching library...';
    notifyListeners();

    try {
      final libraryService = EpicLibraryService(authService: authService);
      final manifestService = EpicManifestService(authService: authService);

      final library = await libraryService.getLibrary();

      if (_cancelRequested) {
        _status = SyncQueueStatus.cancelled;
        _statusMessage = 'Sync cancelled';
        notifyListeners();
        return;
      }

      for (final item in library) {
        if (item.namespace.toLowerCase() == 'ue') continue;
        _queue.add(SyncQueueEntry(item: item));
      }

      _status = SyncQueueStatus.syncing;
      _statusMessage = 'Syncing ${_queue.length} items...';
      _addLog('Found ${_queue.length} items in library');
      notifyListeners();

      for (int i = 0; i < _queue.length; i++) {
        if (_cancelRequested) {
          for (int j = i; j < _queue.length; j++) {
            _queue[j].status = UploadStatusType.failed;
            _queue[j].message = 'Cancelled';
          }
          _status = SyncQueueStatus.cancelled;
          _statusMessage = 'Sync cancelled';
          notifyListeners();
          return;
        }

        final entry = _queue[i];
        _statusMessage = 'Syncing ${entry.item.appName}...';
        notifyListeners();

        try {
          final manifestBytes = await manifestService.getManifestForLibraryItem(
            entry.item,
          );

          if (manifestBytes != null) {
            final result = await uploadService.uploadCloudManifest(
              entry.item,
              manifestBytes,
            );
            entry.status = result.status;
            entry.message = result.message;

            switch (result.status) {
              case UploadStatusType.uploaded:
                _addLog('✅ Uploaded: ${entry.item.appName}');
              case UploadStatusType.alreadyUploaded:
                _addLog('ℹ️ Already exists: ${entry.item.appName}');
              default:
                _addLog('❌ Failed: ${entry.item.appName} - ${result.message}');
            }
          } else {
            entry.status = UploadStatusType.failed;
            entry.message = 'No cloud manifest found';
            _addLog('⏭️ Skipped: ${entry.item.appName} (no manifest)');
          }
        } catch (e) {
          entry.status = UploadStatusType.failed;
          entry.message = '$e';
          _addLog('❌ Failed: ${entry.item.appName} - $e');
        }

        _completed++;
        notifyListeners();

        if (i < _queue.length - 1 && !_cancelRequested) {
          await Future.delayed(_delayBetweenItems);
        }
      }

      final successCount = _queue
          .where(
            (e) =>
                e.status == UploadStatusType.uploaded ||
                e.status == UploadStatusType.alreadyUploaded,
          )
          .length;

      if (_queue.isNotEmpty) {
        await AnalyticsService().logManifestUpload(
          count: _queue.length,
          success: successCount == _queue.length,
        );
      }

      _status = successCount == _queue.length
          ? SyncQueueStatus.completed
          : SyncQueueStatus.completed;
      _statusMessage =
          'Sync completed ($successCount/${_queue.length} successful)';
      _addLog(_statusMessage);
      notifyListeners();
    } catch (e) {
      _status = SyncQueueStatus.failed;
      _statusMessage = 'Sync failed: $e';
      _addLog('Sync error: $e');
      notifyListeners();
    }
  }

  void cancel() {
    if (!isRunning) return;
    _cancelRequested = true;
    _addLog('Cancelling sync...');
    notifyListeners();
  }

  void reset() {
    _status = SyncQueueStatus.idle;
    _queue.clear();
    _completed = 0;
    _statusMessage = '';
    _logs.clear();
    _cancelRequested = false;
    notifyListeners();
  }
}
