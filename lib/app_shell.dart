import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluquery/fluquery.dart';
import 'package:window_manager/window_manager.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'main.dart';
import 'utils/platform_utils.dart';
import 'database/database_service.dart';
import 'models/game_info.dart';
import 'models/notification_topics.dart';
import 'models/settings.dart';
import 'models/upload_status.dart';
import 'services/api_service.dart';
import 'services/browse_prefetch_cache.dart';
import 'services/follow_service.dart';
import 'services/manifest_scanner.dart';
import 'services/notification_service.dart';
import 'services/playtime_service.dart';
import 'services/push_service.dart';
import 'services/sync_service.dart';
import 'services/upload_service.dart';
import 'services/settings_service.dart';
import 'services/tray_service.dart';
import 'services/update_service.dart';
import 'widgets/app_sidebar.dart';
import 'widgets/glassmorphic_bottom_nav.dart';
import 'widgets/custom_title_bar.dart';
import 'pages/dashboard_page.dart';
import 'pages/library_page.dart';
import 'pages/settings_page.dart';
import 'pages/free_games_page.dart';
import 'pages/mobile_browse_page.dart';
import 'pages/mobile_dashboard_page.dart';
import 'pages/mobile_chat_sessions_page.dart';
import 'services/chat_session_service.dart';
import 'services/user_service.dart';

class AppShell extends StatefulWidget {
  final QueryClient? queryClient;

  const AppShell({super.key, this.queryClient});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // Navigation
  AppPage _currentPage = AppPage.dashboard;

  // Mobile navigation with PageView for animations and state preservation
  late final PageController _mobilePageController;
  static const List<AppPage> _mobilePages = [
    AppPage.dashboard,
    AppPage.browse,
    AppPage.chat,
    AppPage.freeGames,
    AppPage.settings,
  ];

  // Universal services
  final SettingsService _settingsService = SettingsService();
  final NotificationService _notificationService = NotificationService();
  final ApiService _apiService = ApiService();

  // Desktop-only services (null on mobile)
  ManifestScanner? _scanner;
  UploadService? _uploadService;
  TrayService? _trayService;

  // Database-dependent services (initialized in _init)
  DatabaseService? _db;
  FollowService? _followService;
  SyncService? _syncService;
  PlaytimeService? _playtimeService; // Desktop only
  PushService? _pushService; // Mobile only
  ChatSessionService? _chatSessionService; // Mobile only

  // Shared state
  List<GameInfo> _games = [];
  final Map<String, UploadStatus> _uploadStatuses = {};
  final Set<String> _uploadingGames = {};
  bool _isLoading = true;
  bool _isUploadingAll = false;
  AppSettings _settings = AppSettings();
  Timer? _syncTimer;
  final List<String> _logs = [];
  bool _showConsole = false;
  String? _latestVersion;
  String _currentVersion = '';

  @override
  void initState() {
    super.initState();
    _mobilePageController = PageController();
    _init();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _mobilePageController.dispose();
    _followService?.dispose();
    _playtimeService?.dispose();
    _pushService?.dispose();
    _notificationService.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    // Get app version from package info
    final packageInfo = await PackageInfo.fromPlatform();
    _currentVersion = packageInfo.version;

    // Initialize database first
    _db = await DatabaseService.getInstance();
    await _db!.migrateFromSharedPreferences();

    // Initialize universal services
    _followService = FollowService(db: _db!);
    _syncService = SyncService(
      db: _db!,
      notification: _notificationService,
    );

    // Initialize desktop-only services
    if (PlatformUtils.isDesktop) {
      _scanner = ManifestScanner();
      _uploadService = UploadService();
      _trayService = TrayService();
      _playtimeService = PlaytimeService(
        db: _db!,
        getInstalledGames: () => _games,
      );
      _playtimeService!.startTracking();
    }

    // Initialize mobile-only services
    if (PlatformUtils.isMobile) {
      _pushService = PushService(
        db: _db!,
        notification: _notificationService,
      );
      await _pushService!.init();

      // Get or create persistent user ID
      final userId = await UserService.getUserId();
      _chatSessionService = ChatSessionService(userId: userId);
    }

    await _loadSettings();

    // Desktop: scan local games
    if (PlatformUtils.isDesktop) {
      await _scanGames();
    }

    await _followService!.loadFollowedGames();

    // Migrate existing followed games to have notification topics
    if (PlatformUtils.isMobile && _pushService != null) {
      final pushState = await _pushService!.getSubscriptionState();
      if (pushState.isSubscribed) {
        await _migrateFollowedGamesTopics();
      }
    }

    _setupAutoSync();

    // Desktop: initialize tray
    if (PlatformUtils.isDesktop) {
      await _initTray();
    }

    await _initNotifications();

    // Perform startup sync
    // Check if this is the first sync (no free games in database yet)
    // to avoid flooding with notifications for all existing free games
    final existingFreeGames = await _db!.getAllFreeGames();
    final isFirstSync = existingFreeGames.isEmpty;

    // On mobile, skip local notifications entirely since push notifications
    // handle this. Firebase doesn't support desktop push, so desktop uses
    // local notifications from the sync service.
    final skipLocalNotifications = PlatformUtils.isMobile;

    if (isFirstSync) {
      _addLog('First sync detected - notifications will be skipped');
    }

    _addLog('Performing startup sync...');
    final result = await _syncService!.performSync(
      _settings,
      isFirstSync: isFirstSync,
      skipLocalNotifications: skipLocalNotifications,
    );
    if (result.error != null) {
      _addLog('Startup sync error: ${result.error}');
    } else if (result.hasChanges) {
      _addLog('Startup sync: ${result.newFreeGames.length} new free games, '
          '${result.gamesOnSale.length} games on sale, '
          '${result.newChangelogs.length} changelog updates');
    } else {
      _addLog('Startup sync complete: no changes detected');
    }

    // Check for app updates
    _checkForUpdates();

    // Prefetch browse page data for mobile (non-blocking)
    if (PlatformUtils.isMobile) {
      _prefetchBrowseData();
    }
  }

  /// Prefetch the default browse search to avoid loading state on first visit
  Future<void> _prefetchBrowseData() async {
    try {
      final request = SearchRequest(
        sortBy: SearchSortBy.lastModifiedDate,
        sortDir: SearchSortDir.desc,
        limit: 20,
        page: 1,
      );

      final response = await _apiService.search(
        request,
        country: _settings.country,
      );

      // Store in the prefetch cache for browse page to use
      BrowsePrefetchCache.instance.setData(
        country: _settings.country,
        response: response,
      );

      _addLog('Browse prefetch complete: ${response.offers.length} offers');
    } catch (e) {
      // Non-fatal - browse page will fetch on mount
      debugPrint('Browse prefetch failed: $e');
    }
  }

  Future<void> _checkForUpdates() async {
    final latestVersion = await UpdateService.getLatestVersion();
    if (latestVersion != null && latestVersion != _currentVersion) {
      setState(() {
        _latestVersion = latestVersion;
      });
      _addLog('Update available: v$latestVersion (current: v$_currentVersion)');
    }
  }

  Future<void> _initNotifications() async {
    await _notificationService.init();
  }

  Future<void> _initTray() async {
    if (!PlatformUtils.isDesktop || _trayService == null) return;

    await _trayService!.init();
    _trayService!.onShowWindow = _showWindow;
    _trayService!.onQuit = _quitApp;

    // launch_at_startup requires native setup on macOS (LaunchAtLogin Swift package)
    // Only use on Windows until macOS native code is configured
    if (PlatformUtils.isWindows) {
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

  Future<void> _migrateFollowedGamesTopics() async {
    final followedGames = await _db!.getAllFollowedGames();
    final topicsToSubscribe = <String>[];

    for (final entry in followedGames) {
      if (entry.notificationTopics.isEmpty) {
        // Auto-assign "all notifications" topic for existing followed games
        final allTopic = OfferNotificationTopic.all.getTopicForOffer(entry.offerId);
        entry.notificationTopics = [allTopic];
        await _db!.saveFollowedGame(entry);
        topicsToSubscribe.add(allTopic);
      }
    }

    // Subscribe to all topics in one batch
    if (topicsToSubscribe.isNotEmpty) {
      await _pushService!.subscribeToTopics(topics: topicsToSubscribe);
    }
  }

  Future<void> _showWindow() async {
    if (!PlatformUtils.isDesktop) return;
    if (Platform.isWindows) {
      await windowManager.setSkipTaskbar(false);
    }
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _quitApp() async {
    if (!PlatformUtils.isDesktop) return;
    
    // Hide window immediately for responsive UI
    await windowManager.hide();
    
    // Continue with cleanup in the background
    // We use a try-catch to ensure cleanup doesn't prevent app exit
    try {
      // Dispose all services before quitting to ensure proper cleanup
      _syncTimer?.cancel();
      _followService?.dispose();
      await _playtimeService?.shutdown(); // Proper shutdown for playtime service
      _pushService?.dispose();
      _chatSessionService?.dispose();
      _apiService.dispose();
      _notificationService.dispose();
      
      // Close database connection
      await _db?.close();
      
      // Destroy tray and window manager
      await _trayService?.destroy();
      await windowManager.destroy();
    } catch (e) {
      // Log error but don't block app exit
      debugPrint('Error during app shutdown: $e');
    }
  }

  Future<void> _handleClose() async {
    if (!PlatformUtils.isDesktop) return;
    if (_settings.minimizeToTray) {
      // Minimize to tray instead of closing
      if (Platform.isWindows) {
        await windowManager.setSkipTaskbar(true);
        await windowManager.minimize();
      } else {
        await windowManager.hide();
      }
    } else {
      await _quitApp();
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
      // On mobile, skip local notifications - push notifications handle this
      final result = await _syncService!.performSync(
        _settings,
        skipLocalNotifications: PlatformUtils.isMobile,
      );
      if (result.error != null) {
        _addLog('Auto-sync: API sync error - ${result.error}');
      } else if (result.hasChanges) {
        _addLog('Auto-sync: ${result.newFreeGames.length} new free games, '
            '${result.gamesOnSale.length} games on sale, '
            '${result.newChangelogs.length} changelog updates');
      }
    }

    // Desktop only: Scan local games and upload manifests
    if (PlatformUtils.isDesktop && _scanner != null) {
      _addLog('Auto-sync: scanning for games...');
      try {
        final games = await _scanner!.scanGames();
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
    if (!PlatformUtils.isDesktop || _scanner == null) return;

    setState(() {
      _isLoading = true;
    });
    try {
      final games = await _scanner!.scanGames();
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
    if (!PlatformUtils.isDesktop || _uploadService == null) return;

    setState(() {
      _uploadingGames.add(game.installationGuid);
      _uploadStatuses[game.installationGuid] = UploadStatus(
        status: UploadStatusType.uploading,
        message: 'Uploading...',
      );
    });
    _addLog('Uploading ${game.displayName}...');
    final status = await _uploadService!.uploadManifest(game);
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
    if (!PlatformUtils.isDesktop || _uploadService == null) return;
    if (_isUploadingAll) return;

    setState(() {
      _isUploadingAll = true;
    });
    _addLog('Starting upload of all manifests...');
    await _uploadService!.uploadAllManifests(
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
    if (PlatformUtils.isWindows) {
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

    // Switch between desktop and mobile layouts
    if (PlatformUtils.isMobile) {
      return _buildMobileShell();
    }
    return _buildDesktopShell();
  }

  Widget _buildDesktopShell() {
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
              // Custom title bar for Windows/macOS
              if (Platform.isWindows || Platform.isMacOS)
                CustomTitleBar(onClose: _handleClose),
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
                      latestVersion: _latestVersion,
                      currentVersion: _currentVersion,
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

  Widget _buildMobileShell() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Mobile-optimized radial gradient background
          Container(decoration: AppColors.mobileRadialGradientBackground),
          // Mobile-optimized accent glow overlay
          Container(decoration: AppColors.mobileAccentGlowBackground),
          // Main content - PageView for animations & state preservation
          SafeArea(
            bottom: false, // Allow content to extend behind navbar for blur effect
            child: PageView(
              controller: _mobilePageController,
              physics: const NeverScrollableScrollPhysics(), // Disable swipe
              children: [
              MobileDashboardPage(
                followService: _followService!,
                syncService: _syncService!,
                db: _db!,
                settings: _settings,
                pushService: _pushService,
                onSettingsChanged: _onSettingsChanged,
              ),
              MobileBrowsePage(
                settings: _settings,
                followService: _followService!,
                pushService: _pushService,
              ),
              MobileChatSessionsPage(
                settings: _settings,
                apiService: _apiService,
                chatService: _chatSessionService!,
                followService: _followService!,
                pushService: _pushService,
              ),
              FreeGamesPage(
                followService: _followService!,
                syncService: _syncService!,
                db: _db!,
                pushService: _pushService,
              ),
              SettingsPage(
                settings: _settings,
                onSettingsChanged: _onSettingsChanged,
                onClearProcessCache: () => _db!.clearProcessCache(),
                pushService: _pushService,
              ),
            ],
            ),
          ),
          // Glassmorphic bottom navbar - positioned at bottom of Stack
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GlassmorphicBottomNav(
              currentPage: _currentPage,
              onPageSelected: (page) {
                final targetIndex = _mobilePages.indexOf(page);
                if (targetIndex != -1) {
                  _mobilePageController.animateToPage(
                    targetIndex,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                  );
                }
                setState(() {
                  _currentPage = page;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentPage) {
      case AppPage.dashboard:
        // Mobile gets simplified dashboard, desktop gets full dashboard
        if (PlatformUtils.isMobile) {
          return MobileDashboardPage(
            followService: _followService!,
            syncService: _syncService!,
            db: _db!,
            settings: _settings,
            pushService: _pushService,
            onSettingsChanged: _onSettingsChanged,
          );
        }
        return DashboardPage(
          playtimeService: _playtimeService,
          installedGames: _games,
          db: _db,
        );
      case AppPage.library:
        // Desktop: installed games with manifest upload
        // Mobile: redirects to browse page
        if (PlatformUtils.isMobile) {
          return MobileBrowsePage(
            settings: _settings,
            followService: _followService!,
            pushService: _pushService,
          );
        }
        return LibraryPage(
          games: _games,
          uploadStatuses: _uploadStatuses,
          uploadingGames: _uploadingGames,
          isLoading: _isLoading,
          isUploadingAll: _isUploadingAll,
          followService: _followService!,
          manifestPath: _scanner?.getManifestsPath() ?? '',
          onScanGames: _scanGames,
          onUploadManifest: _uploadManifest,
          onUploadAll: _uploadAll,
          onToggleConsole: () => setState(() => _showConsole = !_showConsole),
          showConsole: _showConsole,
          addLog: _addLog,
        );
      case AppPage.browse:
        // Mobile only: browse/search games
        return MobileBrowsePage(
          settings: _settings,
          followService: _followService!,
          pushService: _pushService,
        );
      case AppPage.chat:
        // Mobile only: AI chat sessions list
        return MobileChatSessionsPage(
          settings: _settings,
          apiService: _apiService,
          chatService: _chatSessionService!,
          followService: _followService!,
          pushService: _pushService,
        );
      case AppPage.freeGames:
        // Mobile only: free games list
        return FreeGamesPage(
          followService: _followService!,
          syncService: _syncService!,
          db: _db!,
          pushService: _pushService,
        );
      case AppPage.settings:
        return SettingsPage(
          settings: _settings,
          onSettingsChanged: _onSettingsChanged,
          onClearProcessCache: () => _db!.clearProcessCache(),
          pushService: _pushService,
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
                    color: AppColors.primary.withValues(alpha: 0.1),
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
                          color: AppColors.textMuted.withValues(alpha: 0.5),
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
