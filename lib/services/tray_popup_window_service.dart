import 'dart:convert';
import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/services.dart';

import '../models/tray_popup_stats.dart';

class TrayPopupWindowService {
  static final TrayPopupWindowService _instance =
      TrayPopupWindowService._internal();
  factory TrayPopupWindowService() => _instance;
  TrayPopupWindowService._internal();

  int? _popupWindowId;
  bool _isVisible = false;
  Function()? onOpenApp;
  Function()? onQuit;
  TrayPopupStats _latestStats = const TrayPopupStats.empty();
  double? _anchorX;
  double? _anchorY;

  static const double _popupWidth = 352;
  static const double _popupHeightCompact = 222;
  static const double _popupHeightExpanded = 286;
  static const String popupWindowTitle = 'EGData Tray Popup';

  void init() {
    DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      switch (call.method) {
        case 'tray_popup_request_open_main':
          onOpenApp?.call();
          await hidePopup();
          return null;
        case 'tray_popup_request_quit':
          onQuit?.call();
          return null;
        case 'tray_popup_request_close':
          await hidePopup();
          return null;
        case 'tray_popup_visibility':
          final arguments = call.arguments as Map<dynamic, dynamic>?;
          final visible = arguments?['visible'] == true;
          _isVisible = visible;
          return null;
        default:
          return null;
      }
    });
  }

  Future<void> showPopup({required double x, required double y}) async {
    if (!Platform.isWindows && !Platform.isMacOS) {
      return;
    }

    _anchorX = x;
    _anchorY = y;

    if (_popupWindowId == null) {
      final controller = await DesktopMultiWindow.createWindow(
        jsonEncode({'windowType': 'trayPopup', 'stats': _latestStats.toJson()}),
      );
      _popupWindowId = controller.windowId;
      await controller.setTitle(popupWindowTitle);
      await controller.setFrame(_buildPopupRect(x: x, y: y));
      await controller.show();
      await _notifyPopupShown();
      _isVisible = true;
      return;
    }

    final controller = WindowController.fromWindowId(_popupWindowId!);
    if (_isVisible) {
      await controller.hide();
      _isVisible = false;
      return;
    }

    await controller.setFrame(_buildPopupRect(x: x, y: y));
    await controller.show();
    await _notifyPopupShown();
    await _pushStatsToPopup();
    _isVisible = true;
  }

  Future<void> _notifyPopupShown() async {
    if (_popupWindowId == null) {
      return;
    }

    try {
      await DesktopMultiWindow.invokeMethod(
        _popupWindowId!,
        'tray_popup_on_show',
      );
    } on MissingPluginException {
      // Popup isolate may not be ready yet.
    } on PlatformException {
      // Ignore transient method-channel errors from popup startup/teardown.
    }
  }

  Rect _buildPopupRect({required double x, required double y}) {
    final popupHeight = _hasNowPlaying()
        ? _popupHeightExpanded
        : _popupHeightCompact;

    if (Platform.isWindows) {
      final left = x - (_popupWidth / 2);
      final top = y - popupHeight - 8;
      return Rect.fromLTWH(left, top, _popupWidth, popupHeight);
    }

    final left = x - (_popupWidth / 2);
    final top = y + 8;
    return Rect.fromLTWH(left, top, _popupWidth, popupHeight);
  }

  bool _hasNowPlaying() {
    final currentGame = _latestStats.currentGame?.trim() ?? '';
    final currentSessionTime = _latestStats.currentSessionTime?.trim() ?? '';
    return currentGame.isNotEmpty && currentSessionTime.isNotEmpty;
  }

  Future<void> updateStats(TrayPopupStats stats) async {
    final hadNowPlaying = _hasNowPlaying();
    _latestStats = stats;

    final hasNowPlaying = _hasNowPlaying();
    if (_popupWindowId != null &&
        _isVisible &&
        hadNowPlaying != hasNowPlaying &&
        _anchorX != null &&
        _anchorY != null) {
      final controller = WindowController.fromWindowId(_popupWindowId!);
      await controller.setFrame(_buildPopupRect(x: _anchorX!, y: _anchorY!));
    }

    await _pushStatsToPopup();
  }

  Future<void> _pushStatsToPopup() async {
    if (_popupWindowId == null) {
      return;
    }
    try {
      await DesktopMultiWindow.invokeMethod(
        _popupWindowId!,
        'tray_popup_update_stats',
        _latestStats.toJson(),
      );
    } on MissingPluginException {
      // Popup isolate may not be ready yet. Next stats update will retry.
    } on PlatformException {
      // Ignore transient method-channel errors from popup startup/teardown.
    }
  }

  Future<void> hidePopup() async {
    if (_popupWindowId == null || !_isVisible) {
      return;
    }
    final controller = WindowController.fromWindowId(_popupWindowId!);
    await controller.hide();
    _isVisible = false;
  }

  Future<void> destroy() async {
    if (_popupWindowId != null) {
      final controller = WindowController.fromWindowId(_popupWindowId!);
      await controller.close();
      _popupWindowId = null;
      _isVisible = false;
    }
  }
}
