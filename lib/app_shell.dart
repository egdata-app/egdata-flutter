import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'main.dart';
import 'database/database_service.dart';
import 'models/game_info.dart';
import 'models/settings.dart';
import 'models/upload_status.dart';
import 'services/follow_service.dart';
import 'services/manifest_scanner.dart';
import 'services/notification_service.dart';
import 'services/playtime_service.dart';
import 'services/sync_service.dart';
import 'services/upload_service.dart';
import 'services/settings_service.dart';
import 'services/tray_service.dart';
import 'widgets/app_sidebar.dart';
import 'pages/dashboard_page.dart';
import 'pages/library_page.dart';
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
  final NotificationService _notificationService = NotificationService();

  // Database-dependent services (initialized in _init)
  DatabaseService? _db;
  FollowService? _followService;
  SyncService? _syncService;
  PlaytimeService? _playtimeService;

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
    _followService?.dispose();
    _playtimeService?.dispose();
    _notificationService.dispose();
    if (Platform.isWindows || Platform.isMacOS) {
      windowManager.removeListener(this);
      // Only destroy tray when actually quitting, not on widget dispose
      // Tray destruction is handled by _quitApp() and onWindowClose()
    }
    super.dispose();
  }

  Future<void> _init() async {
    // Initialize database first
    _db = await DatabaseService.getInstance();
    await _db!.migrateFromSharedPreferences();

    // Initialize database-dependent services
    _followService = FollowService(db: _db!);
    _syncService = SyncService(
      db: _db!,
      notification: _notificationService,
    );
    _playtimeService = PlaytimeService(
      db: _db!,
      getInstalledGames: () => _games,
    );
    _playtimeService!.startTracking();

    await _loadSettings();
    await _scanGames();
    await _followService!.loadFollowedGames();
    _setupAutoSync();
    await _initTray();
    await _initNotifications();

    // Perform startup sync
    _addLog('Performing startup sync...');
    final result = await _syncService!.performSync(_settings);
    if (result.error != null) {
      _addLog('Startup sync error: ${result.error}');
    } else if (result.hasChanges) {
      _addLog('Startup sync: ${result.newFreeGames.length} new free games, '
          '${result.gamesOnSale.length} games on sale, '
          '${result.newChangelogs.length} changelog updates');
    } else {
      _addLog('Startup sync complete: no changes detected');
    }
  }

  Future<void> _initNotifications() async {
    await _notificationService.init();
  }

  Future<void> _initTray() async {
    if (Platform.isWindows || Platform.isMacOS) {
      windowManager.addListener(this);
      await windowManager.setPreventClose(true);

      await _trayService.init();
      _trayService.onShowWindow = _showWindow;
      _trayService.onQuit = _quitApp;

      // launch_at_startup requires native setup on macOS (LaunchAtLogin Swift package)
      // Only use on Windows until macOS native code is configured
      if (Platform.isWindows) {
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
    // Sync API data (free games, sales, changelogs)
    _addLog('Auto-sync: syncing API data...');
    if (_syncService != null) {
      final result = await _syncService!.performSync(_settings);
      if (result.error != null) {
        _addLog('Auto-sync: API sync error - ${result.error}');
      } else if (result.hasChanges) {
        _addLog('Auto-sync: ${result.newFreeGames.length} new free games, '
            '${result.gamesOnSale.length} games on sale, '
            '${result.newChangelogs.length} changelog updates');
      }
    }

    // Scan local games and upload manifests
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

    // Only increment count for newly uploaded manifests (not already existing)
    if (status.status == UploadStatusType.uploaded) {
      await _db?.incrementManifestUploadCount();
    }
  }

  Future<void> _uploadAll() async {
    if (_isUploadingAll) return;
    setState(() {
      _isUploadingAll = true;
    });
    _addLog('Starting upload of all manifests...');
    await _uploadService.uploadAllManifests(
      _games,
      onProgress: (gameName, status) async {
        setState(() {
          final game = _games.firstWhere((g) => g.displayName == gameName);
          _uploadStatuses[game.installationGuid] = status;
        });
        _addLog('$gameName: ${status.message}');

        // Only increment count for newly uploaded manifests (not already existing)
        if (status.status == UploadStatusType.uploaded) {
          await _db?.incrementManifestUploadCount();
        }
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

    // launch_at_startup only works on Windows until macOS native code is configured
    if (Platform.isWindows) {
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
    // Show loading indicator while services are initializing
    if (_followService == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'Initializing...',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Radial gradient background
          Container(decoration: AppColors.radialGradientBackground),
          // Accent glow overlay
          Container(decoration: AppColors.accentGlowBackground),
          // Main content
          Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    AppSidebar(
                      currentPage: _currentPage,
                      onPageSelected: (page) {
                        setState(() {
                          _currentPage = page;
                        });
                      },
                    ),
                    Expanded(child: _buildCurrentPage()),
                  ],
                ),
              ),
              if (_showConsole) _buildConsolePanel(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentPage) {
      case AppPage.dashboard:
        return DashboardPage(
          playtimeService: _playtimeService,
          installedGames: _games,
          db: _db,
        );
      case AppPage.library:
        return LibraryPage(
          games: _games,
          uploadStatuses: _uploadStatuses,
          uploadingGames: _uploadingGames,
          isLoading: _isLoading,
          isUploadingAll: _isUploadingAll,
          followService: _followService!,
          manifestPath: _scanner.getManifestsPath(),
          onScanGames: _scanGames,
          onUploadManifest: _uploadManifest,
          onUploadAll: _uploadAll,
          onToggleConsole: () => setState(() => _showConsole = !_showConsole),
          showConsole: _showConsole,
          addLog: _addLog,
        );
      case AppPage.settings:
        return SettingsPage(
          settings: _settings,
          onSettingsChanged: _onSettingsChanged,
          onClearProcessCache: () => _db!.clearProcessCache(),
        );
    }
  }

  Widget _buildConsolePanel() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.background,
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.terminal_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Console',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_logs.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                const Spacer(),
                if (_logs.isNotEmpty)
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => setState(() => _logs.clear()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.borderLight),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Clear',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => setState(() => _showConsole = false),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _logs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inbox_rounded,
                          size: 32,
                          color: AppColors.textMuted.withOpacity(0.5),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'No activity yet',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      final isError = log.contains('Error') || log.contains('failed');
                      final isSuccess = log.contains('uploaded') ||
                          log.contains('complete') ||
                          log.contains('exists');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          log,
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 11,
                            height: 1.4,
                            color: isError
                                ? AppColors.error
                                : isSuccess
                                    ? AppColors.success
                                    : AppColors.textSecondary,
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
