import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/tray_popup_stats.dart';
import 'tray_popup_window_service.dart';
import 'windows_cursor_service.dart';

class TrayService with TrayListener {
  static final TrayService _instance = TrayService._internal();
  factory TrayService() => _instance;
  TrayService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  Function()? onShowWindow;
  Function()? onQuit;
  final TrayPopupWindowService _popupService = TrayPopupWindowService();

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Initialize popup service
      _popupService.init();
      _popupService.onOpenApp = () {
        onShowWindow?.call();
      };
      _popupService.onQuit = () {
        onQuit?.call();
      };

      // Copy tray icon from assets to temp directory
      final iconPath = await _extractTrayIcon();
      print('TrayService: Icon extracted to $iconPath');

      await trayManager.setIcon(iconPath);
      print('TrayService: Icon set successfully');

      await trayManager.setToolTip('EGData Client');

      final menu = Menu(
        items: [
          MenuItem(key: 'show', label: 'Show EGData'),
          MenuItem.separator(),
          MenuItem(key: 'quit', label: 'Quit'),
        ],
      );
      await trayManager.setContextMenu(menu);
      print('TrayService: Context menu set successfully');

      trayManager.addListener(this);
      _isInitialized = true;
      print('TrayService: Initialization complete');
    } catch (e) {
      print('TrayService: Error during initialization: $e');
    }
  }

  Future<String> _extractTrayIcon() async {
    final tempDir = await getTemporaryDirectory();

    // Windows requires .ico, macOS uses .png
    final isWindows = Platform.isWindows;
    final extension = isWindows ? 'ico' : 'png';
    final iconFile = File(
      path.join(tempDir.path, 'egdata_tray_icon.$extension'),
    );

    // Always extract to ensure latest version
    final byteData = await rootBundle.load('assets/tray_icon.$extension');
    await iconFile.writeAsBytes(byteData.buffer.asUint8List());

    return iconFile.path;
  }

  @override
  void onTrayIconMouseDown() async {
    _showWindow();
  }

  @override
  void onTrayIconRightMouseDown() async {
    if (!Platform.isWindows && !Platform.isMacOS) {
      _showWindow();
      return;
    }

    try {
      final bounds = await trayManager.getBounds();
      if (bounds != null) {
        await _popupService.showPopup(
          x: bounds.left + bounds.width / 2,
          y: Platform.isWindows ? bounds.top : bounds.bottom,
        );
      } else {
        if (Platform.isWindows) {
          final cursorPos = WindowsCursorService.getCursorScreenPosition();
          if (cursorPos != null) {
            await _popupService.showPopup(x: cursorPos.x, y: cursorPos.y);
            return;
          }
        }

        _showWindow();
      }
    } catch (e) {
      print('TrayService: Error showing popup: $e');
      _showWindow();
    }
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        _showWindow();
        break;
      case 'quit':
        onQuit?.call();
        break;
    }
  }

  void _showWindow() {
    onShowWindow?.call();
  }

  /// Updates the popup stats displayed when left-clicking the tray icon.
  Future<void> updatePopupStats({
    required String weeklyPlaytime,
    required int gamesInstalled,
    String? mostPlayedGame,
    String? currentGame,
    String? currentSessionTime,
  }) async {
    await _popupService.updateStats(
      TrayPopupStats(
        weeklyPlaytime: weeklyPlaytime,
        gamesInstalled: gamesInstalled,
        mostPlayedGame: mostPlayedGame,
        currentGame: currentGame,
        currentSessionTime: currentSessionTime,
      ),
    );
  }

  Future<void> destroy() async {
    if (_isInitialized) {
      trayManager.removeListener(this);
      await _popupService.destroy();
      await trayManager.destroy();
      _isInitialized = false;
    }
  }
}
