import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'main.dart';
import 'models/game_info.dart';
import 'models/settings.dart';
import 'models/upload_status.dart';
import 'services/calendar_service.dart';
import 'services/follow_service.dart';
import 'services/manifest_scanner.dart';
import 'services/notification_service.dart';
import 'services/search_service.dart';
import 'services/upload_service.dart';
import 'services/settings_service.dart';
import 'services/tray_service.dart';
import 'widgets/app_sidebar.dart';
import 'pages/dashboard_page.dart';
import 'pages/discover_page.dart';
import 'pages/library_page.dart';
import 'pages/calendar_page.dart';
import 'pages/settings_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WindowListener {
  // Navigation
  AppPage _currentPage = AppPage.dashboard;

  // Services
  final ManifestScanner _scanner = ManifestScanner();
  final UploadService _uploadService = UploadService();
  final SettingsService _settingsService = SettingsService();
  final TrayService _trayService = TrayService();
  final FollowService _followService = FollowService();
  final SearchService _searchService = SearchService();
  final CalendarService _calendarService = CalendarService();
  final NotificationService _notificationService = NotificationService();

  // Shared state
  List<GameInfo> _games = [];
  final Map<String, UploadStatus> _uploadStatuses = {};
  final Set<String> _uploadingGames = {};
  bool _isLoading = true;
  bool _isUploadingAll = false;
  AppSettings _settings = AppSettings();
  Timer? _syncTimer;
  final List<String> _logs = [];
  bool _forceQuit = false;
  bool _showConsole = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _followService.dispose();
    _notificationService.dispose();
    if (Platform.isWindows || Platform.isMacOS) {
      windowManager.removeListener(this);
      _trayService.destroy();
    }
    super.dispose();
  }

  Future<void> _init() async {
    await _loadSettings();
    await _scanGames();
    await _followService.loadFollowedGames();
    _setupAutoSync();
    await _initTray();
    await _initNotifications();
  }

  Future<void> _initNotifications() async {
    await _notificationService.init();
    _notificationService.configure(
      calendarService: _calendarService,
      followService: _followService,
      settings: _settings,
    );
    _notificationService.updateSettings(_settings);
  }

  Future<void> _initTray() async {
    if (Platform.isWindows || Platform.isMacOS) {
      windowManager.addListener(this);
      await windowManager.setPreventClose(true);

      await _trayService.init();
      _trayService.onShowWindow = _showWindow;
      _trayService.onQuit = _quitApp;

      final isEnabled = await launchAtStartup.isEnabled();
      if (isEnabled != _settings.launchAtStartup) {
        if (_settings.launchAtStartup) {
          await launchAtStartup.enable();
        } else {
          await launchAtStartup.disable();
        }
      }
    }
  }

  Future<void> _showWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _quitApp() async {
    _forceQuit = true;
    await _trayService.destroy();
    await windowManager.destroy();
  }

  @override
  void onWindowClose() async {
    if (_settings.minimizeToTray && !_forceQuit) {
      await windowManager.hide();
    } else {
      await _trayService.destroy();
      await windowManager.destroy();
    }
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsService.loadSettings();
    setState(() {
      _settings = settings;
    });
  }

  void _setupAutoSync() {
    _syncTimer?.cancel();
    if (_settings.autoSync) {
      _syncTimer = Timer.periodic(
        Duration(minutes: _settings.syncIntervalMinutes),
        (_) => _performAutoSync(),
      );
      _addLog('Auto-sync enabled: every ${_settings.syncIntervalMinutes} minutes');
    }
  }

  Future<void> _performAutoSync() async {
    _addLog('Auto-sync: scanning for games...');
    try {
      final games = await _scanner.scanGames();
      setState(() {
        _games = games;
      });
      _addLog('Auto-sync: found ${games.length} games');
    } catch (e) {
      _addLog('Auto-sync: scan error - $e');
      return;
    }
    if (_games.isNotEmpty) {
      await _uploadAll();
    }
  }

  void _addLog(String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    setState(() {
      _logs.insert(0, '[$timestamp] $message');
      if (_logs.length > 100) {
        _logs.removeLast();
      }
    });
  }

  Future<void> _scanGames() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final games = await _scanner.scanGames();
      setState(() {
        _games = games;
        _isLoading = false;
      });
      _addLog('Found ${games.length} installed games');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _addLog('Error scanning games: $e');
    }
  }

  Future<void> _uploadManifest(GameInfo game) async {
    setState(() {
      _uploadingGames.add(game.installationGuid);
      _uploadStatuses[game.installationGuid] = UploadStatus(
        status: UploadStatusType.uploading,
        message: 'Uploading...',
      );
    });
    _addLog('Uploading ${game.displayName}...');
    final status = await _uploadService.uploadManifest(game);
    setState(() {
      _uploadingGames.remove(game.installationGuid);
      _uploadStatuses[game.installationGuid] = status;
    });
    _addLog('${game.displayName}: ${status.message}');
  }

  Future<void> _uploadAll() async {
    if (_isUploadingAll) return;
    setState(() {
      _isUploadingAll = true;
    });
    _addLog('Starting upload of all manifests...');
    await _uploadService.uploadAllManifests(
      _games,
      onProgress: (gameName, status) {
        setState(() {
          final game = _games.firstWhere((g) => g.displayName == gameName);
          _uploadStatuses[game.installationGuid] = status;
        });
        _addLog('$gameName: ${status.message}');
      },
    );
    setState(() {
      _isUploadingAll = false;
    });
    _addLog('Upload complete');
  }

  void _onSettingsChanged(AppSettings newSettings) async {
    final oldSettings = _settings;
    setState(() {
      _settings = newSettings;
    });
    await _settingsService.saveSettings(newSettings);
    _setupAutoSync();
    _notificationService.updateSettings(newSettings);

    if (Platform.isWindows || Platform.isMacOS) {
      if (oldSettings.launchAtStartup != newSettings.launchAtStartup) {
        if (newSettings.launchAtStartup) {
          await launchAtStartup.enable();
          _addLog('Launch at startup enabled');
        } else {
          await launchAtStartup.disable();
          _addLog('Launch at startup disabled');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                AppSidebar(
                  currentPage: _currentPage,
                  onPageSelected: (page) => setState(() => _currentPage = page),
                ),
                Expanded(
                  child: _buildCurrentPage(),
                ),
              ],
            ),
          ),
          if (_showConsole) _buildConsolePanel(),
        ],
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentPage) {
      case AppPage.dashboard:
        return DashboardPage(
          games: _games,
          settings: _settings,
          followService: _followService,
          calendarService: _calendarService,
          isLoading: _isLoading,
          isUploadingAll: _isUploadingAll,
          onScanGames: _scanGames,
          onUploadAll: _uploadAll,
          logs: _logs,
        );
      case AppPage.discover:
        return DiscoverPage(
          followService: _followService,
          searchService: _searchService,
        );
      case AppPage.library:
        return LibraryPage(
          games: _games,
          uploadStatuses: _uploadStatuses,
          uploadingGames: _uploadingGames,
          isLoading: _isLoading,
          isUploadingAll: _isUploadingAll,
          followService: _followService,
          manifestPath: _scanner.getManifestsPath(),
          onScanGames: _scanGames,
          onUploadManifest: _uploadManifest,
          onUploadAll: _uploadAll,
          onToggleConsole: () => setState(() => _showConsole = !_showConsole),
          showConsole: _showConsole,
          addLog: _addLog,
        );
      case AppPage.calendar:
        return CalendarPage(
          calendarService: _calendarService,
          followService: _followService,
        );
      case AppPage.settings:
        return SettingsPage(
          settings: _settings,
          onSettingsChanged: _onSettingsChanged,
        );
    }
  }

  Widget _buildConsolePanel() {
    return Container(
      height: 160,
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.terminal_rounded,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 8),
                const Text(
                  'CONSOLE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: AppColors.textMuted,
                  ),
                ),
                const Spacer(),
                if (_logs.isNotEmpty)
                  InkWell(
                    onTap: () => setState(() => _logs.clear()),
                    child: const Text(
                      'CLEAR',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
                InkWell(
                  onTap: () => setState(() => _showConsole = false),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _logs.isEmpty
                ? const Center(
                    child: Text(
                      'No activity yet',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      final isError = log.contains('Error') || log.contains('failed');
                      final isSuccess = log.contains('uploaded') ||
                          log.contains('complete') ||
                          log.contains('exists');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          log,
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 11,
                            color: isError
                                ? AppColors.error
                                : isSuccess
                                    ? AppColors.success
                                    : AppColors.textMuted,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
