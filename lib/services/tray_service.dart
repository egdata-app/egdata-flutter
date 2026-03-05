import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class TrayService with TrayListener {
  static final TrayService _instance = TrayService._internal();
  factory TrayService() => _instance;
  TrayService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  Function()? onShowWindow;
  Function()? onQuit;

  // Cache stats for menu updates if needed
  String _weeklyPlaytime = '0m';
  int _gamesInstalled = 0;
  String? _currentGame;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Copy tray icon from assets to temp directory
      final iconPath = await _extractTrayIcon();
      print('TrayService: Icon extracted to $iconPath');

      await trayManager.setIcon(iconPath);
      print('TrayService: Icon set successfully');

      await trayManager.setToolTip('EGData Client');

      await _updateMenu();
      print('TrayService: Context menu set successfully');

      trayManager.addListener(this);
      _isInitialized = true;
      print('TrayService: Initialization complete');
    } catch (e) {
      print('TrayService: Error during initialization: $e');
    }
  }

  Future<void> _updateMenu() async {
    if (!_isInitialized && !trayManager.hashCode.isFinite)
      return; // Basic safety

    final menu = Menu(
      items: [
        MenuItem(key: 'show', label: 'Show EGData'),
        MenuItem.separator(),
        if (_currentGame != null) ...[
          MenuItem(
            key: 'current_game',
            label: 'Playing: $_currentGame',
            disabled: true,
          ),
          MenuItem.separator(),
        ],
        MenuItem(
          key: 'stats',
          label: 'Weekly: $_weeklyPlaytime ($_gamesInstalled games)',
          disabled: true,
        ),
        MenuItem.separator(),
        MenuItem(key: 'quit', label: 'Quit'),
      ],
    );
    await trayManager.setContextMenu(menu);
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
    await trayManager.popUpContextMenu();
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

  /// Updates the stats displayed in the native context menu.
  Future<void> updatePopupStats({
    required String weeklyPlaytime,
    required int gamesInstalled,
    String? mostPlayedGame,
    String? currentGame,
    String? currentSessionTime,
  }) async {
    _weeklyPlaytime = weeklyPlaytime;
    _gamesInstalled = gamesInstalled;
    _currentGame = currentGame;

    if (_isInitialized) {
      await _updateMenu();
    }
  }

  Future<void> destroy() async {
    if (_isInitialized) {
      trayManager.removeListener(this);
      await trayManager.destroy();
      _isInitialized = false;
    }
  }
}
