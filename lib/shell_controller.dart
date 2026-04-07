import 'package:flutter/material.dart';
import 'widgets/app_sidebar.dart';
import 'services/sync_queue_service.dart';

class ShellController extends ChangeNotifier {
  AppPage _currentPage = AppPage.dashboard;
  String? _latestVersion;
  String _currentVersion = '';
  SyncQueueService? _syncQueueService;
  VoidCallback? _handleClose;
  bool _syncPopupVisible = false;
  Rect? _syncAnchorRect;
  void Function(AppPage page)? _onPageSelectedFromOverlay;

  AppPage get currentPage => _currentPage;
  String? get latestVersion => _latestVersion;
  String get currentVersion => _currentVersion;
  SyncQueueService? get syncQueueService => _syncQueueService;
  VoidCallback? get handleClose => _handleClose;
  bool get syncPopupVisible => _syncPopupVisible;
  Rect? get syncAnchorRect => _syncAnchorRect;

  void updateFromShell({
    AppPage? currentPage,
    String? latestVersion,
    String? currentVersion,
    SyncQueueService? syncQueueService,
    VoidCallback? handleClose,
    void Function(AppPage)? onPageSelectedFromOverlay,
  }) {
    bool changed = false;
    if (currentPage != null && currentPage != _currentPage) {
      _currentPage = currentPage;
      changed = true;
    }
    if (latestVersion != _latestVersion) {
      _latestVersion = latestVersion;
      changed = true;
    }
    if (currentVersion != null && currentVersion != _currentVersion) {
      _currentVersion = currentVersion;
      changed = true;
    }
    if (syncQueueService != _syncQueueService) {
      _syncQueueService = syncQueueService;
      changed = true;
    }
    if (handleClose != _handleClose) {
      _handleClose = handleClose;
      changed = true;
    }
    if (onPageSelectedFromOverlay != null) {
      _onPageSelectedFromOverlay = onPageSelectedFromOverlay;
    }
    if (changed) notifyListeners();
  }

  void selectPage(AppPage page) {
    if (_currentPage == page) return;
    _currentPage = page;
    _onPageSelectedFromOverlay?.call(page);
    notifyListeners();
  }

  void showSyncPopup(Rect anchorRect) {
    _syncPopupVisible = true;
    _syncAnchorRect = anchorRect;
    notifyListeners();
  }

  void hideSyncPopup() {
    _syncPopupVisible = false;
    notifyListeners();
  }
}
