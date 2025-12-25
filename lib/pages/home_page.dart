import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import '../main.dart';
import '../models/game_info.dart';
import '../models/settings.dart';
import '../models/upload_status.dart';
import '../services/manifest_scanner.dart';
import '../services/upload_service.dart';
import '../services/settings_service.dart';
import '../services/tray_service.dart';
import '../widgets/game_tile.dart';
import 'move_game_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WindowListener {
  final ManifestScanner _scanner = ManifestScanner();
  final UploadService _uploadService = UploadService();
  final SettingsService _settingsService = SettingsService();
  final TrayService _trayService = TrayService();
  final TextEditingController _searchController = TextEditingController();

  List<GameInfo> _games = [];
  final Map<String, UploadStatus> _uploadStatuses = {};
  final Set<String> _uploadingGames = {};
  bool _isLoading = true;
  bool _isUploadingAll = false;
  bool _showLogs = true;
  String _searchQuery = '';
  AppSettings _settings = AppSettings();
  Timer? _syncTimer;
  final List<String> _logs = [];
  bool _forceQuit = false;

  List<GameInfo> get _filteredGames {
    if (_searchQuery.isEmpty) return _games;
    final query = _searchQuery.toLowerCase();
    return _games.where((game) {
      return game.displayName.toLowerCase().contains(query) ||
          game.appName.toLowerCase().contains(query) ||
          game.installLocation.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _searchController.dispose();
    if (Platform.isWindows || Platform.isMacOS) {
      windowManager.removeListener(this);
      _trayService.destroy();
    }
    super.dispose();
  }

  Future<void> _init() async {
    await _loadSettings();
    await _scanGames();
    _setupAutoSync();
    await _initTray();
  }

  Future<void> _initTray() async {
    if (Platform.isWindows || Platform.isMacOS) {
      windowManager.addListener(this);
      await windowManager.setPreventClose(true);

      await _trayService.init();
      _trayService.onShowWindow = _showWindow;
      _trayService.onQuit = _quitApp;

      // Sync launch at startup setting
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
      _addLog(
        'Auto-sync enabled: every ${_settings.syncIntervalMinutes} minutes',
      );
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

  void _openSettings() async {
    final result = await Navigator.push<AppSettings>(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsPage(settings: _settings),
      ),
    );

    if (result != null) {
      final oldSettings = _settings;
      setState(() {
        _settings = result;
      });
      await _settingsService.saveSettings(result);
      _setupAutoSync();

      // Handle launch at startup change
      if (Platform.isWindows || Platform.isMacOS) {
        if (oldSettings.launchAtStartup != result.launchAtStartup) {
          if (result.launchAtStartup) {
            await launchAtStartup.enable();
            _addLog('Launch at startup enabled');
          } else {
            await launchAtStartup.disable();
            _addLog('Launch at startup disabled');
          }
        }
      }
    }
  }

  void _moveGame(GameInfo game) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => MoveGamePage(game: game),
      ),
    );

    if (result == true) {
      _addLog('Game moved: ${game.displayName}');
      await _scanGames();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredGames = _filteredGames;

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildToolbar(filteredGames.length),
                      Expanded(child: _buildGameList(filteredGames)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_showLogs) _buildLogPanel(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Logo
          Image.asset(
            'assets/logo.png',
            width: 40,
            height: 40,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.storage_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EGDATA',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Manifest Uploader',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Stats badges
          _buildStatBadge(
            icon: Icons.games_rounded,
            label: '${_games.length}',
            sublabel: 'GAMES',
          ),
          const SizedBox(width: 12),
          if (_settings.autoSync) ...[
            _buildStatBadge(
              icon: Icons.sync_rounded,
              label: '${_settings.syncIntervalMinutes}m',
              sublabel: 'SYNC',
              isActive: true,
            ),
            const SizedBox(width: 12),
          ],
          // Settings button
          _buildIconButton(
            icon: Icons.settings_rounded,
            onPressed: _openSettings,
            tooltip: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required String label,
    required String sublabel,
    bool isActive = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.accent.withValues(alpha: 0.1)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isActive
              ? AppColors.accent.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isActive ? AppColors.accent : AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isActive ? AppColors.accent : AppColors.textPrimary,
                ),
              ),
              Text(
                sublabel,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    bool isActive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isActive
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isActive ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar(int gameCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Search field
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search games...',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          color: AppColors.textMuted,
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Console toggle
          _buildIconButton(
            icon: Icons.terminal_rounded,
            onPressed: () => setState(() => _showLogs = !_showLogs),
            tooltip: _showLogs ? 'Hide console' : 'Show console',
            isActive: _showLogs,
          ),
          const SizedBox(width: 8),
          // Refresh button
          _buildIconButton(
            icon: Icons.refresh_rounded,
            onPressed: _isLoading ? () {} : _scanGames,
            tooltip: 'Rescan games',
          ),
          const SizedBox(width: 12),
          // Upload button
          _buildUploadButton(),
        ],
      ),
    );
  }

  Widget _buildUploadButton() {
    final isDisabled = _isUploadingAll || _games.isEmpty;

    return Material(
      color: isDisabled ? AppColors.surfaceLight : AppColors.primary,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: isDisabled ? null : _uploadAll,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isUploadingAll)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                Icon(
                  Icons.cloud_upload_rounded,
                  size: 18,
                  color: isDisabled ? AppColors.textMuted : Colors.white,
                ),
              const SizedBox(width: 10),
              Text(
                _isUploadingAll ? 'UPLOADING...' : 'UPLOAD ALL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isDisabled ? AppColors.textMuted : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameList(List<GameInfo> games) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'SCANNING LIBRARY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_games.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.games_rounded,
                size: 40,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'NO GAMES FOUND',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _scanner.getManifestsPath(),
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'JetBrainsMono',
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _scanGames,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('SCAN AGAIN'),
            ),
          ],
        ),
      );
    }

    if (games.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'No results for "$_searchQuery"',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: games.length,
      separatorBuilder: (_, _) => const SizedBox(height: 2),
      itemBuilder: (context, index) {
        final game = games[index];
        return GameTile(
          game: game,
          uploadStatus: _uploadStatuses[game.installationGuid],
          isUploading: _uploadingGames.contains(game.installationGuid),
          onUpload: () => _uploadManifest(game),
          onMove: () => _moveGame(game),
        );
      },
    );
  }

  Widget _buildLogPanel() {
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
              ],
            ),
          ),
          Expanded(
            child: _logs.isEmpty
                ? const Center(
                    child: Text(
                      'No activity yet',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
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
