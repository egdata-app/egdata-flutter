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
  Function()? onShowWindow;
  Function()? onQuit;

  Future<void> init() async {
    if (_isInitialized) return;

    // Copy tray icon from assets to temp directory
    final iconPath = await _extractTrayIcon();

    await trayManager.setIcon(iconPath);
    await trayManager.setToolTip('EGData Client');

    final menu = Menu(
      items: [
        MenuItem(key: 'show', label: 'Show EGData'),
        MenuItem.separator(),
        MenuItem(key: 'quit', label: 'Quit'),
      ],
    );
    await trayManager.setContextMenu(menu);

    trayManager.addListener(this);
    _isInitialized = true;
  }

  Future<String> _extractTrayIcon() async {
    final tempDir = await getTemporaryDirectory();

    // Windows requires .ico, macOS uses .png
    final isWindows = Platform.isWindows;
    final extension = isWindows ? 'ico' : 'png';
    final iconFile = File(path.join(tempDir.path, 'egdata_tray_icon.$extension'));

    // Always extract to ensure latest version
    final byteData = await rootBundle.load('assets/tray_icon.$extension');
    await iconFile.writeAsBytes(byteData.buffer.asUint8List());

    return iconFile.path;
  }

  @override
  void onTrayIconMouseDown() {
    _showWindow();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
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

  Future<void> destroy() async {
    if (_isInitialized) {
      trayManager.removeListener(this);
      await trayManager.destroy();
      _isInitialized = false;
    }
  }
}
