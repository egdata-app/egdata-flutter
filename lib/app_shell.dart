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
import 'models/epic_progress.dart';
import 'models/library_game.dart';
import 'models/notification_topics.dart';
import 'models/playtime_stats.dart';
import 'models/settings.dart';
import 'models/upload_status.dart';
import 'models/manifest_health_issue.dart';
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
import 'services/sync_queue_service.dart';
import 'services/tray_service.dart';
import 'services/update_service.dart';
import 'services/window_channel_service.dart';
import 'services/epic_auth_service.dart';
import 'services/epic_progress_service.dart';
import 'services/epic_library_service.dart';
import 'services/library_metadata_service.dart';
import 'services/library_repository.dart';
import 'services/drive_discovery_service.dart';
import 'services/epic_recovery_service.dart';
import 'widgets/app_sidebar.dart';
import 'pages/dashboard_page.dart';
import 'pages/desktop_home_page.dart';
import 'pages/desktop_activity_page.dart';
import 'pages/desktop_tools_page.dart';
import 'pages/disk_discovery_page.dart';
import 'pages/library_page.dart';
import 'pages/library_game_detail_page.dart';
import 'pages/move_game_page.dart';
import 'pages/cloud_sync_page.dart';
import 'pages/settings_page.dart';
import 'pages/free_games_page.dart';
import 'pages/mobile_browse_page.dart';
import 'pages/mobile_dashboard_page.dart';
import 'pages/mobile_chat_sessions_page.dart';
import 'services/chat_session_service.dart';
import 'services/user_service.dart';
import 'shell_controller.dart';
import 'utils/epic_protocol.dart';
import 'theme/desktop_theme.dart';

class AppShell extends StatefulWidget {
  final QueryClient? queryClient;
  final EpicAuthService? epicAuthService;
  final UploadService? uploadService;
  final SyncQueueService? syncQueueService;
  final ShellController shellController;

  const AppShell({
    super.key,
    this.queryClient,
    this.epicAuthService,
    this.uploadService,
    this.syncQueueService,
    required this.shellController,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WindowListener {
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
  LibraryMetadataService? _libraryMetadataService;
  LibraryRepository? _libraryRepository;
  // Desktop only until mobile progress UX exists.
  EpicProgressService? _epicProgressService;
  DriveDiscoveryService? _driveDiscoveryService;
  EpicRecoveryService? _epicRecoveryService;

  // Shared state
  List<GameInfo> _games = [];
  List<GameInfo> _allGames = [];
  List<OwnedGameEntry> _ownedGames = [];
  final Map<String, UploadStatus> _uploadStatuses = {};
  final Set<String> _uploadingGames = {};
  bool _isLoading = true;
  bool _isUploadingAll = false;
  bool _isFetchingOwnedLibrary = false;
  AppSettings _settings = AppSettings();
  Timer? _syncTimer;
  final List<String> _logs = [];
  bool _showConsole = false;
  String? _latestVersion;
  String _currentVersion = '';
  bool _isHandlingClose = false;
  bool _isQuitting = false;
  bool _isStartupSyncing = false;
  String? _selectedGameIdentityKey;
  Map<String, EpicGameProgress> _officialProgressByCatalogItemId = const {};
  EpicProgressProofResult? _officialProgressProof;

  // Tray popup subscriptions (macOS)
  StreamSubscription<PlaytimeStats>? _trayStatsSubscription;
  StreamSubscription<PlaytimeSessionEntry?>? _trayActiveGameSubscription;

  @override
  void initState() {
    super.initState();
    if (PlatformUtils.isDesktop) {
      windowManager.addListener(this);
    }
    _mobilePageController = PageController();
    _init();
  }

  @override
  void dispose() {
    if (PlatformUtils.isDesktop) {
      windowManager.removeListener(this);
    }
    _syncTimer?.cancel();
    _trayStatsSubscription?.cancel();
    _trayActiveGameSubscription?.cancel();
    _mobilePageController.dispose();
    _libraryRepository?.removeListener(_onLibraryRepositoryChanged);
    _driveDiscoveryService?.removeListener(_onDriveDiscoveryChanged);
    _driveDiscoveryService?.dispose();
    _followService?.dispose();
    _playtimeService?.dispose();
    _pushService?.dispose();
    _notificationService.dispose();
    super.dispose();
  }

  @override
  void onWindowClose() {
    unawaited(
      _handleClose().catchError((Object e, StackTrace stackTrace) {
        debugPrint('Error handling window close: $e');
      }),
    );
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
    _syncService = SyncService(db: _db!, notification: _notificationService);
    _libraryMetadataService = LibraryMetadataService(
      database: _db!,
      api: _apiService,
    );
    await _libraryMetadataService!.loadFromDatabase();
    _libraryRepository = LibraryRepository(
      database: _db!,
      metadataService: _libraryMetadataService!,
    );
    _libraryRepository!.addListener(_onLibraryRepositoryChanged);
    if (PlatformUtils.isDesktop) {
      await _libraryRepository!.loadCached();
      _syncShellLibraryStateFromRepository();
    }

    // Initialize desktop-only services
    if (PlatformUtils.isDesktop) {
      _scanner = ManifestScanner();
      _uploadService = UploadService();
      _trayService = TrayService();
      _epicProgressService = EpicProgressService(
        authService: widget.epicAuthService ?? EpicAuthService(),
      );
      _playtimeService = PlaytimeService(
        db: _db!,
        getInstalledGames: () => _games,
      );
      _playtimeService!.startTracking();
      final launcherManifestDirectory = _scanner!.getManifestsPath();
      _driveDiscoveryService = DriveDiscoveryService(
        database: _db!,
        launcherManifestDirectory: launcherManifestDirectory,
      )..addListener(_onDriveDiscoveryChanged);
      _epicRecoveryService = EpicRecoveryService(
        database: _db!,
        launcherManifestDirectory: launcherManifestDirectory,
      );
    }

    // Initialize mobile-only services
    if (PlatformUtils.isMobile) {
      _pushService = PushService(db: _db!, notification: _notificationService);
      await _pushService!.init();

      // Get or create persistent user ID
      final userId = await UserService.getUserId();
      _chatSessionService = ChatSessionService(userId: userId);
    }

    await _loadSettings();

    // Desktop: initialize tray early so it's available even if startup work is long.
    if (PlatformUtils.isDesktop) {
      await _initTray();
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

    await _initNotifications();

    await _performStartupSync();
    if (PlatformUtils.isWindows && _settings.diskMonitoringEnabled) {
      await _driveDiscoveryService?.start();
    }

    // Check for app updates
    _checkForUpdates();

    // Prefetch browse page data for mobile (non-blocking)
    if (PlatformUtils.isMobile) {
      _prefetchBrowseData();
    }

    // Register with shell controller so overlay widgets can access state
    widget.shellController.updateFromShell(
      handleClose: _handleClose,
      syncQueueService: widget.syncQueueService,
      latestVersion: _latestVersion,
      currentVersion: _currentVersion,
      onPageSelectedFromOverlay: _handlePageSelectedFromOverlay,
    );
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
      widget.shellController.updateFromShell(
        latestVersion: _latestVersion,
        currentVersion: _currentVersion,
      );
      _addLog('Update available: v$latestVersion (current: v$_currentVersion)');
    }
  }

  Future<void> _initNotifications() async {
    await _notificationService.init();
  }

  Future<void> _initTray() async {
    if (!PlatformUtils.isDesktop || _trayService == null) return;

    await _trayService!.init();
    if (!_trayService!.isInitialized) {
      _addLog('Tray initialization failed, retrying...');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await _trayService!.init();
    }

    if (!_trayService!.isInitialized) {
      _addLog('Tray is unavailable on this startup');
      return;
    }

    _trayService!.onShowWindow = _showWindow;
    _trayService!.onQuit = _quitApp;

    // Set up tray popup stats updates (desktop)
    if (PlatformUtils.isDesktop && _playtimeService != null) {
      // Initial stats update
      _updateTrayPopupStats();

      // Subscribe to stats changes
      _trayStatsSubscription = _playtimeService!.statsStream.listen((_) {
        _updateTrayPopupStats();
      });

      // Subscribe to active game changes
      _trayActiveGameSubscription = _playtimeService!.activeGameStream.listen((
        _,
      ) {
        _updateTrayPopupStats();
      });
    }

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

  Future<void> _updateTrayPopupStats() async {
    if (_trayService == null || _playtimeService == null || _db == null) return;

    final stats = await _playtimeService!.getWeeklyStats();
    final activeSession = await _db!.getActiveSession();

    String? currentSessionTime;
    if (activeSession != null) {
      final duration = activeSession.duration;
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      final seconds = duration.inSeconds % 60;
      currentSessionTime = hours > 0
          ? '${hours}h ${minutes}m ${seconds}s'
          : minutes > 0
          ? '${minutes}m ${seconds}s'
          : '${seconds}s';
    }

    await _trayService!.updatePopupStats(
      weeklyPlaytime: stats.formattedTotalPlaytime,
      gamesInstalled: _games.length,
      mostPlayedGame: stats.mostPlayedGame?.gameName,
      currentGame: activeSession?.gameName,
      currentSessionTime: currentSessionTime,
    );
  }

  Future<void> _migrateFollowedGamesTopics() async {
    final followedGames = await _db!.getAllFollowedGames();
    final topicsToSubscribe = <String>[];

    for (final entry in followedGames) {
      if (entry.notificationTopics.isEmpty) {
        // Auto-assign "all notifications" topic for existing followed games
        final allTopic = OfferNotificationTopic.all.getTopicForOffer(
          entry.offerId,
        );
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

    final isMinimized = await windowManager.isMinimized();
    if (isMinimized) {
      await windowManager.restore();
    }

    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _quitApp() async {
    if (!PlatformUtils.isDesktop || _isQuitting) return;
    _isQuitting = true;

    // Hide window immediately for responsive UI
    try {
      await windowManager.hide();
    } catch (e) {
      debugPrint('Error hiding window during app shutdown: $e');
    }

    // Continue with cleanup in the background
    // We use a try-catch to ensure cleanup doesn't prevent app exit
    try {
      // Dispose all services before quitting to ensure proper cleanup
      _syncTimer?.cancel();
      _followService?.dispose();
      await _playtimeService
          ?.shutdown(); // Proper shutdown for playtime service
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
    if (!PlatformUtils.isDesktop || _isHandlingClose || _isQuitting) return;

    _isHandlingClose = true;
    try {
      if (_trayService != null && !_trayService!.isInitialized) {
        await _initTray();
      }

      if (_settings.minimizeToTray) {
        if (Platform.isWindows) {
          await windowManager.setSkipTaskbar(true);
          await windowManager.minimize();
        } else {
          await windowManager.hide();
        }
      } else {
        await _quitApp();
      }
    } finally {
      _isHandlingClose = false;
    }
  }

  void _handlePageSelectedFromOverlay(AppPage page) {
    if (PlatformUtils.isMobile) {
      final targetIndex = _mobilePages.indexOf(page);
      if (targetIndex != -1) {
        _mobilePageController.animateToPage(
          targetIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    }
    setState(() {
      _currentPage = page;
      if (page != AppPage.gameDetail) {
        _selectedGameIdentityKey = null;
      }
    });
  }

  void _selectPageFromContent(AppPage page) {
    setState(() {
      _currentPage = page;
      if (page != AppPage.gameDetail) {
        _selectedGameIdentityKey = null;
      }
    });
    widget.shellController.updateFromShell(currentPage: page);
  }

  void _onLibraryRepositoryChanged() {
    if (!mounted) return;
    setState(_syncShellLibraryStateFromRepository);
  }

  void _onDriveDiscoveryChanged() {
    if (!mounted) return;
    setState(() {});
    unawaited(_libraryRepository?.loadCached());
  }

  void _syncShellLibraryStateFromRepository() {
    final repository = _libraryRepository;
    if (repository == null) return;
    _allGames = repository.allInstalledGames;
    _games = repository.installedGames;
    _ownedGames = repository.ownedGames;
    _officialProgressByCatalogItemId = repository.progressByCatalogItemId;
    _officialProgressProof = repository.progressProof;
    _isLoading =
        repository.sync.isRunning &&
        repository.installedGames.isEmpty &&
        repository.ownedGames.isEmpty;
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsService.loadSettings();
    setState(() {
      _settings = settings;
    });

    // Sync minimize-to-tray setting with macOS native code
    if (Platform.isMacOS) {
      await WindowChannelService().setMinimizeToTray(settings.minimizeToTray);
    }
  }

  void _setupAutoSync() {
    _syncTimer?.cancel();
    if (_settings.autoSync) {
      _syncTimer = Timer.periodic(
        Duration(minutes: _settings.syncIntervalMinutes),
        (_) => _performAutoSync(),
      );
      _addLog(
        'Auto-sync enabled: every ${_settings.syncIntervalMinutes} minutes',
      );
    }
  }

  Future<void> _performStartupSync() async {
    if (_isStartupSyncing || _db == null || _syncService == null) return;
    _isStartupSyncing = true;

    try {
      if (PlatformUtils.isDesktop) {
        _libraryRepository?.markSync(
          LibrarySyncPhase.scanningLocal,
          'Scanning local installs',
        );
        await _scanGames(syncMetadata: false);
        await _loadOwnedGames(syncMetadata: false);
      }

      final existingFreeGames = await _db!.getAllFreeGames();
      final isFirstSync = existingFreeGames.isEmpty;
      if (isFirstSync) {
        _addLog('First sync detected - notifications will be skipped');
      }

      _addLog('Startup sync: syncing local database...');
      final result = await _syncService!.performSync(
        _settings,
        isFirstSync: isFirstSync,
        skipLocalNotifications: PlatformUtils.isMobile,
      );
      _logSyncResult('Startup sync', result);

      if (PlatformUtils.isDesktop) {
        _libraryRepository?.markSync(
          LibrarySyncPhase.fetchingEpicLibrary,
          'Fetching Epic library',
        );
        await _fetchOwnedLibrary(promptLogin: false, syncMetadata: false);
        _libraryRepository?.markSync(
          LibrarySyncPhase.syncingMetadata,
          'Hydrating EGData metadata',
        );
        await _syncLibraryMetadata();
        _libraryRepository?.markSync(
          LibrarySyncPhase.syncingProgress,
          'Syncing official progress',
        );
        await _syncOfficialProgress();
        _libraryRepository?.markSync(
          LibrarySyncPhase.completed,
          'Desktop library sync complete',
        );
      }
    } catch (e) {
      _libraryRepository?.markSync(
        LibrarySyncPhase.failed,
        'Desktop library sync failed',
        error: e,
      );
      _addLog('Startup desktop sync failed: $e');
    } finally {
      _isStartupSyncing = false;
    }
  }

  void _logSyncResult(String label, SyncResult result) {
    if (result.error != null) {
      _addLog('$label error: ${result.error}');
    } else if (result.hasChanges) {
      _addLog(
        '$label: ${result.newFreeGames.length} new free games, '
        '${result.gamesOnSale.length} games on sale, '
        '${result.newChangelogs.length} changelog updates',
      );
    } else {
      _addLog('$label complete: no changes detected');
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
        _addLog(
          'Auto-sync: ${result.newFreeGames.length} new free games, '
          '${result.gamesOnSale.length} games on sale, '
          '${result.newChangelogs.length} changelog updates',
        );
      }
    }

    // Desktop only: scan local games and refresh Epic/EGData hydration.
    if (PlatformUtils.isDesktop && _scanner != null) {
      _addLog('Auto-sync: scanning for games...');
      try {
        final allGames = await _scanner!.scanGames(groupByMainGame: false);
        final games = ManifestScanner.groupGamesByMainGame(allGames);
        setState(() {
          _allGames = allGames;
          _games = games;
        });
        _addLog(
          'Auto-sync: found ${games.length} games from ${allGames.length} manifests',
        );
      } catch (e) {
        _addLog('Auto-sync: scan error - $e');
        return;
      }
      await _fetchOwnedLibrary(promptLogin: false, syncMetadata: false);
      await _syncLibraryMetadata();
      await _syncOfficialProgress();
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

  Future<void> _scanGames({bool syncMetadata = true}) async {
    if (!PlatformUtils.isDesktop || _scanner == null) return;

    setState(() {
      _isLoading = true;
    });
    try {
      final allGames = await _scanner!.scanGames(groupByMainGame: false);
      final games = ManifestScanner.groupGamesByMainGame(allGames);
      final repository = _libraryRepository;
      if (repository != null) {
        await repository.replaceInstalledGames(allGames);
      } else {
        setState(() {
          _allGames = allGames;
          _games = games;
        });
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      _addLog(
        'Found ${games.length} installed games from ${allGames.length} manifests',
      );
      if (syncMetadata) {
        unawaited(_syncLibraryMetadata());
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _addLog('Error scanning games: $e');
    }
  }

  Future<void> _loadOwnedGames({bool syncMetadata = true}) async {
    if (!PlatformUtils.isDesktop || _db == null) return;
    final ownedGames = await _db!.getAllOwnedGames();
    final repository = _libraryRepository;
    if (repository != null) {
      await repository.reloadOwnedGames();
    } else if (mounted) {
      setState(() {
        _ownedGames = ownedGames;
      });
    }
    if (syncMetadata) {
      unawaited(_syncLibraryMetadata());
    }
  }

  /// Fire-and-forget background sync of offer-level metadata for every
  /// item in the library (installed + owned). Used to power right-sidebar
  /// filters by offer type, tags, release date, and price.
  Future<void> _syncLibraryMetadata({bool forceRefresh = false}) async {
    final service = _libraryMetadataService;
    if (service == null) return;
    final ids = <String>{
      for (final game in _games)
        if (game.catalogItemId.isNotEmpty) game.catalogItemId,
      for (final owned in _ownedGames)
        if (owned.catalogItemId.isNotEmpty) owned.catalogItemId,
    };
    if (ids.isEmpty) return;

    try {
      final result = forceRefresh
          ? await service.refresh(ids)
          : await service.syncStale(ids);
      if (result != null && result.requested > 0) {
        _addLog(
          'Library metadata synced: ${result.resolved} resolved, '
          '${result.empty} empty, ${result.errors} errors '
          '(${result.elapsed.inMilliseconds} ms)',
        );
        _libraryRepository?.refreshMetadataCache();
        if (mounted) setState(() {});
      }
    } catch (e) {
      _addLog('Library metadata sync failed: $e');
    }
  }

  Future<void> _fetchOwnedLibrary({
    bool promptLogin = true,
    bool syncMetadata = true,
  }) async {
    if (!PlatformUtils.isDesktop ||
        _db == null ||
        widget.epicAuthService == null) {
      return;
    }

    setState(() {
      _isFetchingOwnedLibrary = true;
    });

    try {
      await widget.epicAuthService!.loadTokens();
      if (!widget.epicAuthService!.isAuthenticated) {
        if (!promptLogin) {
          _addLog('Epic library startup sync skipped: login required');
          return;
        }
        final success = await widget.epicAuthService!.login();
        if (!success) {
          _addLog('Epic library fetch cancelled: login required');
          return;
        }
      }

      final libraryService = EpicLibraryService(
        authService: widget.epicAuthService!,
      );
      final library = await libraryService.getLibrary();

      // Filter out Unreal Engine assets (engine versions, marketplace
      // assets) before we hit the metadata API — they're not games and
      // make up a large fraction of every Epic account.
      final games = library
          .where((item) => item.namespace.toLowerCase() != 'ue')
          .toList(growable: false);
      final skipped = library.length - games.length;
      if (skipped > 0) {
        _addLog('Skipping $skipped Unreal Engine assets');
      }

      // One round trip per 100 items instead of one per item.
      final itemIds = games
          .map((g) => g.catalogItemId)
          .where((id) => id.isNotEmpty)
          .toSet();
      _addLog('Fetching metadata for ${itemIds.length} items…');
      final metadataMap = await _apiService.bulkGetItems(itemIds);

      final now = DateTime.now();
      final entries = <OwnedGameEntry>[];
      for (final item in games) {
        final metadata = metadataMap[item.catalogItemId];
        final keyImages = metadata?.keyImages ?? const [];
        String? imageOfType(String type) {
          for (final img in keyImages) {
            if (img.type == type && img.url.isNotEmpty) return img.url;
          }
          return null;
        }

        entries.add(
          OwnedGameEntry.fromLibraryItem(
            item,
            title: metadata?.title,
            boxArtUrl: imageOfType('DieselGameBoxTall'),
            wideImageUrl: imageOfType('DieselGameBox'),
            developer: metadata?.developer,
            publisher: metadata?.publisher,
            syncedAt: now,
          ),
        );
      }

      await _db!.saveOwnedGames(entries);
      await _loadOwnedGames(syncMetadata: false);
      if (syncMetadata) {
        await _syncLibraryMetadata();
      }
      _addLog('Fetched ${entries.length} Epic library items');
    } catch (e) {
      _addLog('Epic library fetch failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingOwnedLibrary = false;
        });
      }
    }
  }

  Future<void> _syncOfficialProgress({bool forceRefresh = false}) async {
    final service = _epicProgressService;
    if (!PlatformUtils.isDesktop || service == null) return;

    final catalogIds = <String>{};
    final artifactIdByCatalogItemId = <String, String>{};
    final productIdByCatalogItemId = <String, String>{};

    for (final game in _games) {
      final catalogItemId = game.catalogItemId.trim();
      final appName = game.appName.trim();
      if (catalogItemId.isEmpty) continue;
      catalogIds.add(catalogItemId);
      if (appName.isNotEmpty) {
        artifactIdByCatalogItemId[catalogItemId] = appName;
      }
    }

    for (final game in _ownedGames) {
      final catalogItemId = game.catalogItemId.trim();
      final appName = game.appName.trim();
      final productId = game.assetId.trim();
      if (catalogItemId.isEmpty) continue;
      catalogIds.add(catalogItemId);
      if (appName.isNotEmpty) {
        artifactIdByCatalogItemId.putIfAbsent(catalogItemId, () => appName);
      }
      if (productId.isNotEmpty &&
          productId.toLowerCase() != appName.toLowerCase()) {
        productIdByCatalogItemId[catalogItemId] = productId;
      }
    }

    if (catalogIds.isEmpty) {
      final proof = await service.verifyOfficialProgressAccess(
        forceRefresh: forceRefresh,
      );
      await _libraryRepository?.replaceProgressProof(proof);
      return;
    }

    try {
      final snapshot = await service.loadProgressSnapshot(
        catalogIds,
        artifactIdByCatalogItemId: artifactIdByCatalogItemId,
        productIdByCatalogItemId: productIdByCatalogItemId,
        achievementProductLimit: 50,
        forceRefresh: forceRefresh,
      );
      await _libraryRepository?.replaceProgressSnapshot(snapshot);

      if (snapshot.proof.needsLogin) {
        _addLog('Official progress sync skipped: Epic login required');
      } else if (snapshot.proof.isBlocked) {
        _addLog(
          'Official progress sync blocked: ${snapshot.proof.title} - '
          '${snapshot.proof.message}',
        );
      } else {
        _addLog(
          'Official progress synced: '
          '${snapshot.gamesByCatalogItemId.length} library item(s)',
        );
      }
    } catch (e) {
      _addLog('Official progress sync failed: $e');
    }
  }

  Future<void> _syncOwnedGames(List<OwnedGameEntry> ownedGames) async {
    final queue = widget.syncQueueService;
    if (queue == null || ownedGames.isEmpty || queue.isRunning) return;
    await queue.startSync(
      items: ownedGames.map((entry) => entry.toLibraryItem()).toList(),
    );
    await _loadOwnedGames();
  }

  List<LibraryGame> get _mergedLibraryGames {
    final queue = widget.syncQueueService;
    final repository = _libraryRepository;
    if (repository != null) {
      return repository.mergedGames(
        localUploadStatuses: _uploadStatuses,
        ownedUploadStatuses: queue?.ownedUploadStatuses ?? const {},
        uploadingInstalledIds: _uploadingGames,
        syncingOwnedKeys: queue?.syncingIdentityKeys ?? const {},
      );
    }
    return LibraryGame.merge(
      installedGames: _games,
      ownedGames: _ownedGames,
      localUploadStatuses: _uploadStatuses,
      ownedUploadStatuses: queue?.ownedUploadStatuses ?? const {},
      uploadingInstalledIds: _uploadingGames,
      syncingOwnedKeys: queue?.syncingIdentityKeys ?? const {},
      metadataByCatalogItemId: _libraryMetadataService?.cache ?? const {},
      progressByCatalogItemId: _officialProgressByCatalogItemId,
    );
  }

  LibraryGame? _selectedDetailGame() {
    final key = _selectedGameIdentityKey;
    if (key == null || key.isEmpty) return null;
    for (final game in _mergedLibraryGames) {
      if (game.identityKey == key) return game;
    }
    return null;
  }

  void _openGameDetail(LibraryGame game) {
    setState(() {
      _selectedGameIdentityKey = game.identityKey;
      _currentPage = AppPage.gameDetail;
    });
    widget.shellController.updateFromShell(currentPage: AppPage.gameDetail);
  }

  void _openInstalledGameDetail(GameInfo game) {
    final repository = _libraryRepository;
    final libraryGame =
        repository?.findInstalledGame(
          game,
          localUploadStatuses: _uploadStatuses,
          ownedUploadStatuses:
              widget.syncQueueService?.ownedUploadStatuses ?? const {},
          uploadingInstalledIds: _uploadingGames,
          syncingOwnedKeys:
              widget.syncQueueService?.syncingIdentityKeys ?? const {},
        ) ??
        _mergedLibraryGames.where((candidate) {
          return candidate.installedGame?.installationGuid ==
                  game.installationGuid ||
              (game.catalogItemId.isNotEmpty &&
                  candidate.catalogItemId == game.catalogItemId);
        }).firstOrNull;
    if (libraryGame == null) {
      _selectPageFromContent(AppPage.library);
      return;
    }
    _openGameDetail(libraryGame);
  }

  void _openGameDetailByCatalogItemId(String catalogItemId) {
    final repository = _libraryRepository;
    final libraryGame =
        repository?.findGameByCatalogItemId(
          catalogItemId,
          localUploadStatuses: _uploadStatuses,
          ownedUploadStatuses:
              widget.syncQueueService?.ownedUploadStatuses ?? const {},
          uploadingInstalledIds: _uploadingGames,
          syncingOwnedKeys:
              widget.syncQueueService?.syncingIdentityKeys ?? const {},
        ) ??
        _mergedLibraryGames
            .where((game) => game.catalogItemId == catalogItemId)
            .firstOrNull;
    if (libraryGame == null) {
      _selectPageFromContent(AppPage.library);
      return;
    }
    _openGameDetail(libraryGame);
  }

  Future<void> _launchLibraryGame(LibraryGame game) async {
    final installed = game.installedGame;
    if (installed == null) return;
    final ok = await EpicProtocol.launch(
      EpicProtocol.launchApp(
        installed.appName,
        namespace: installed.catalogNamespace,
        itemId: installed.catalogItemId,
      ),
    );
    _addLog(
      ok
          ? 'Launching ${installed.displayName}'
          : 'Could not launch ${installed.displayName} (Epic launcher missing?)',
    );
  }

  Future<void> _installLibraryGame(LibraryGame game) async {
    final owned = game.ownedGame;
    if (owned == null) return;
    final ok = await EpicProtocol.launch(
      EpicProtocol.installApp(
        owned.appName,
        namespace: owned.namespace,
        itemId: owned.catalogItemId,
      ),
    );
    _addLog(
      ok
          ? 'Install requested for ${owned.title}'
          : 'Could not request install for ${owned.title}',
    );
  }

  Future<void> _moveLibraryGame(GameInfo game) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => MoveGamePage(game: game)),
    );

    if (result == true) {
      _addLog('Game moved: ${game.displayName}');
      await _scanGames();
    }
  }

  Future<void> _syncLibraryGames(List<LibraryGame> games) async {
    final installedGames = games
        .where((game) => game.isInstalled)
        .map((game) => game.installedGame!)
        .toList(growable: false);
    final cloudGames = games
        .where((game) => !game.isInstalled && game.ownedGame != null)
        .map((game) => game.ownedGame!)
        .toList(growable: false);

    for (final game in installedGames) {
      await _uploadManifest(game);
    }
    if (cloudGames.isNotEmpty) {
      await _syncOwnedGames(cloudGames);
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
      onProgress: (game, status) async {
        setState(() {
          _uploadStatuses[game.installationGuid] = status;
        });
        _addLog('${game.displayName}: ${status.message}');

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

  Future<ManifestHealthReport> _runManifestHealthCheck() async {
    if (!PlatformUtils.isDesktop || _scanner == null) {
      return const ManifestHealthReport(issues: []);
    }
    return _scanner!.analyzeManifestHealth(_allGames);
  }

  Future<int> _autoRepairManifestFiles() async {
    if (!PlatformUtils.isDesktop || _scanner == null) {
      return 0;
    }
    final repaired = await _scanner!.autoRepairManifestLocations(_allGames);
    if (repaired > 0) {
      await _scanGames();
    }
    return repaired;
  }

  void _onSettingsChanged(AppSettings newSettings) async {
    final oldSettings = _settings;
    setState(() {
      _settings = newSettings;
    });
    await _settingsService.saveSettings(newSettings);
    _setupAutoSync();

    // Sync minimize-to-tray setting with macOS native code
    if (Platform.isMacOS &&
        oldSettings.minimizeToTray != newSettings.minimizeToTray) {
      await WindowChannelService().setMinimizeToTray(
        newSettings.minimizeToTray,
      );
    }

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
      if (oldSettings.diskMonitoringEnabled !=
          newSettings.diskMonitoringEnabled) {
        if (newSettings.diskMonitoringEnabled) {
          await _driveDiscoveryService?.start();
          _addLog('Disk monitoring enabled');
        } else {
          _driveDiscoveryService?.stop();
          _addLog('Disk monitoring disabled');
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
    final titleBarHeight = (Platform.isWindows || Platform.isMacOS)
        ? 40.0
        : 0.0;

    return Scaffold(
      backgroundColor: DesktopTheme.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: DesktopTheme.background),
          Padding(
            padding: EdgeInsets.only(left: 220, top: titleBarHeight),
            child: Column(
              children: [
                Expanded(child: _buildCurrentPage()),
                if (_showConsole) _buildConsolePanel(),
              ],
            ),
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
          Container(decoration: AppColors.mobileRadialGradientBackground),
          Container(decoration: AppColors.mobileAccentGlowBackground),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: 74 + MediaQuery.of(context).padding.bottom,
              ),
              child: PageView(
                controller: _mobilePageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  MobileDashboardPage(
                    followService: _followService!,
                    syncService: _syncService!,
                    db: _db!,
                    settings: _settings,
                    pushService: _pushService,
                    chatService: _chatSessionService,
                    playtimeService: _playtimeService,
                    onSettingsChanged: _onSettingsChanged,
                  ),
                  MobileBrowsePage(
                    settings: _settings,
                    followService: _followService!,
                    pushService: _pushService,
                    chatService: _chatSessionService,
                    playtimeService: _playtimeService,
                  ),
                  MobileChatSessionsPage(
                    settings: _settings,
                    apiService: _apiService,
                    chatService: _chatSessionService!,
                    followService: _followService!,
                    pushService: _pushService,
                    playtimeService: _playtimeService,
                  ),
                  FreeGamesPage(
                    followService: _followService!,
                    syncService: _syncService!,
                    db: _db!,
                    pushService: _pushService,
                    chatService: _chatSessionService,
                    playtimeService: _playtimeService,
                    settings: _settings,
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
            chatService: _chatSessionService,
            playtimeService: _playtimeService,
            onSettingsChanged: _onSettingsChanged,
          );
        }
        return DesktopHomePage(
          installedGames: _games,
          ownedGamesCount: _ownedGames.length,
          playtimeService: _playtimeService,
          database: _db!,
          driveDiscoveryService: _driveDiscoveryService,
          progressByCatalogItemId: _officialProgressByCatalogItemId,
          epicConnected:
              widget.epicAuthService?.isAuthenticated == true &&
              _officialProgressProof?.isAvailable == true,
          onOpenLibrary: () => _selectPageFromContent(AppPage.library),
          onOpenActivity: () => _selectPageFromContent(AppPage.playtime),
          onOpenDiskDiscovery: () =>
              _selectPageFromContent(AppPage.diskDiscovery),
          onOpenGameDetails: _openInstalledGameDetail,
        );
      case AppPage.library:
        // Desktop: installed games with manifest upload
        // Mobile: redirects to browse page
        if (PlatformUtils.isMobile) {
          return MobileBrowsePage(
            settings: _settings,
            followService: _followService!,
            pushService: _pushService,
            chatService: _chatSessionService,
            playtimeService: _playtimeService,
          );
        }
        return LibraryPage(
          games: _games,
          allGames: _allGames,
          ownedGames: _ownedGames,
          uploadStatuses: _uploadStatuses,
          uploadingGames: _uploadingGames,
          isLoading: _isLoading,
          isUploadingAll: _isUploadingAll,
          isFetchingOwnedLibrary: _isFetchingOwnedLibrary,
          libraryViewMode: _settings.libraryViewMode,
          settings: _settings,
          followService: _followService!,
          playtimeService: _playtimeService,
          epicAuthService: widget.epicAuthService,
          uploadService: widget.uploadService,
          syncQueueService: widget.syncQueueService,
          metadataService: _libraryMetadataService,
          epicProgressService: _epicProgressService,
          progressByCatalogItemId: _officialProgressByCatalogItemId,
          progressProof: _officialProgressProof,
          onRefreshOfficialProgress: _syncOfficialProgress,
          onOpenGameDetail: _openGameDetail,
          onRefreshMetadata: () async {
            final service = _libraryMetadataService;
            if (service == null) return;
            final ids = <String>{
              for (final game in _games)
                if (game.catalogItemId.isNotEmpty) game.catalogItemId,
              for (final owned in _ownedGames)
                if (owned.catalogItemId.isNotEmpty) owned.catalogItemId,
            };
            final result = await service.refresh(ids);
            if (result != null) {
              _addLog(
                'Library metadata refreshed: ${result.resolved} resolved, '
                '${result.empty} empty, ${result.errors} errors',
              );
              if (mounted) setState(() {});
            }
          },
          manifestPath: _scanner?.getManifestsPath() ?? '',
          onScanGames: _scanGames,
          onFetchOwnedLibrary: _fetchOwnedLibrary,
          onSyncOwnedGames: _syncOwnedGames,
          onUploadManifest: _uploadManifest,
          onUploadAll: _uploadAll,
          onManifestHealthCheck: _runManifestHealthCheck,
          onManifestAutoRepair: _autoRepairManifestFiles,
          onToggleConsole: () => setState(() => _showConsole = !_showConsole),
          showConsole: _showConsole,
          addLog: _addLog,
          onLibraryViewModeChanged: (mode) =>
              _onSettingsChanged(_settings.copyWith(libraryViewMode: mode)),
          onLibraryFiltersChanged: _onSettingsChanged,
          onNavigateToDashboard: () =>
              _selectPageFromContent(AppPage.dashboard),
        );
      case AppPage.gameDetail:
        final detailGame = _selectedDetailGame();
        if (PlatformUtils.isMobile || detailGame == null) {
          return DashboardPage(
            playtimeService: _playtimeService,
            installedGames: _games,
            ownedGames: _ownedGames,
            ownedGamesCount: _ownedGames.length,
            db: _db,
            epicAuthService: widget.epicAuthService,
            epicProgressService: _epicProgressService,
            progressByCatalogItemId: _officialProgressByCatalogItemId,
            progressProof: _officialProgressProof,
            onRefreshOfficialProgress: _syncOfficialProgress,
            onOpenLibrary: () => _selectPageFromContent(AppPage.library),
            onOpenProgress: () => _selectPageFromContent(AppPage.playtime),
            onOpenSyncCenter: () => _selectPageFromContent(AppPage.syncCenter),
            onOpenGameDetails: _openInstalledGameDetail,
          );
        }
        return Navigator(
          key: ValueKey('game-detail-${detailGame.identityKey}'),
          onGenerateRoute: (_) => MaterialPageRoute(
            builder: (_) => LibraryGameDetailPage(
              key: ValueKey(detailGame.identityKey),
              game: detailGame,
              followService: _followService!,
              playtimeService: _playtimeService,
              epicProgressService: _epicProgressService,
              onLaunch: _launchLibraryGame,
              onInstall: _installLibraryGame,
              onMove: _moveLibraryGame,
              onSyncManifest: (game) => _syncLibraryGames([game]),
              onBack: () => _selectPageFromContent(AppPage.library),
            ),
          ),
        );
      case AppPage.playtime:
        return DesktopActivityPage(
          database: _db!,
          installedGames: _games,
          progressByCatalogItemId: _officialProgressByCatalogItemId,
          onOpenGameDetailByCatalogItemId: _openGameDetailByCatalogItemId,
        );
      case AppPage.tools:
        return DesktopToolsPage(
          syncQueueService: widget.syncQueueService,
          driveDiscoveryService: _driveDiscoveryService,
          onOpenSyncCenter: () => _selectPageFromContent(AppPage.syncCenter),
          onOpenDiskDiscovery: () =>
              _selectPageFromContent(AppPage.diskDiscovery),
          onToggleConsole: () => setState(() => _showConsole = !_showConsole),
        );
      case AppPage.diskDiscovery:
        final discovery = _driveDiscoveryService;
        final recovery = _epicRecoveryService;
        if (discovery == null || recovery == null) {
          return DesktopToolsPage(
            syncQueueService: widget.syncQueueService,
            driveDiscoveryService: discovery,
            onOpenSyncCenter: () => _selectPageFromContent(AppPage.syncCenter),
            onOpenDiskDiscovery: () {},
            onToggleConsole: () => setState(() => _showConsole = !_showConsole),
          );
        }
        return DiskDiscoveryPage(
          service: discovery,
          recoveryService: recovery,
          onBack: () => _selectPageFromContent(AppPage.tools),
        );
      case AppPage.syncCenter:
        if (PlatformUtils.isMobile || widget.syncQueueService == null) {
          return DashboardPage(
            playtimeService: _playtimeService,
            installedGames: _games,
            ownedGames: _ownedGames,
            ownedGamesCount: _ownedGames.length,
            db: _db,
            epicAuthService: widget.epicAuthService,
            epicProgressService: _epicProgressService,
            progressByCatalogItemId: _officialProgressByCatalogItemId,
            progressProof: _officialProgressProof,
            onRefreshOfficialProgress: _syncOfficialProgress,
            onOpenLibrary: () => _selectPageFromContent(AppPage.library),
            onOpenProgress: () => _selectPageFromContent(AppPage.playtime),
            onOpenSyncCenter: () => _selectPageFromContent(AppPage.syncCenter),
            onOpenGameDetails: _openInstalledGameDetail,
          );
        }
        return CloudSyncPage(
          authService: widget.epicAuthService,
          syncQueueService: widget.syncQueueService!,
        );
      case AppPage.browse:
        // Mobile only: browse/search games
        return MobileBrowsePage(
          settings: _settings,
          followService: _followService!,
          pushService: _pushService,
          playtimeService: _playtimeService,
        );
      case AppPage.chat:
        // Mobile only: AI chat sessions list
        return MobileChatSessionsPage(
          settings: _settings,
          apiService: _apiService,
          chatService: _chatSessionService!,
          followService: _followService!,
          pushService: _pushService,
          playtimeService: _playtimeService,
        );
      case AppPage.freeGames:
        // Mobile only: free games list
        return FreeGamesPage(
          followService: _followService!,
          syncService: _syncService!,
          db: _db!,
          pushService: _pushService,
          chatService: _chatSessionService,
          playtimeService: _playtimeService,
          settings: _settings,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
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
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      final isError =
                          log.contains('Error') || log.contains('failed');
                      final isSuccess =
                          log.contains('uploaded') ||
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
