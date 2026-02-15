import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../models/followed_game.dart';
import '../models/daily_playtime_bucket.dart';
import '../models/game_info.dart';
import '../models/manifest_health_issue.dart';
import '../models/upload_status.dart';
import '../services/follow_service.dart';
import '../services/playtime_service.dart';
import '../widgets/game_tile.dart';
import 'move_game_page.dart';

class LibraryPage extends StatefulWidget {
  final List<GameInfo> games;
  final List<GameInfo> allGames;
  final Map<String, UploadStatus> uploadStatuses;
  final Set<String> uploadingGames;
  final bool isLoading;
  final bool isUploadingAll;
  final FollowService followService;
  final PlaytimeService? playtimeService;
  final String manifestPath;
  final Future<void> Function() onScanGames;
  final Future<void> Function(GameInfo) onUploadManifest;
  final Future<void> Function() onUploadAll;
  final Future<ManifestHealthReport> Function()? onManifestHealthCheck;
  final Future<int> Function()? onManifestAutoRepair;
  final VoidCallback onToggleConsole;
  final bool showConsole;
  final Function(String) addLog;

  const LibraryPage({
    super.key,
    required this.games,
    required this.allGames,
    required this.uploadStatuses,
    required this.uploadingGames,
    required this.isLoading,
    required this.isUploadingAll,
    required this.followService,
    this.playtimeService,
    required this.manifestPath,
    required this.onScanGames,
    required this.onUploadManifest,
    required this.onUploadAll,
    this.onManifestHealthCheck,
    this.onManifestAutoRepair,
    required this.onToggleConsole,
    required this.showConsole,
    required this.addLog,
  });

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showGrouped = true;
  bool _selectionMode = false;
  final Set<String> _selectedGameIds = {};
  bool _isQueueRunning = false;
  bool _isQueuePaused = false;
  bool _queueCancelRequested = false;
  int _queueCompleted = 0;
  int _queueTotal = 0;
  final List<GameInfo> _queueFailed = [];
  int _unplayedInstalledCount = 0;
  GameInfo? _detailsGame;
  bool _detailsLoading = false;
  Duration? _detailsTotalPlaytime;
  DateTime? _detailsLastPlayedAt;
  List<DailyPlaytimeBucket> _detailsTimeline = const [];

  List<GameInfo> get _displayGames =>
      _showGrouped ? widget.games : widget.allGames;

  List<GameInfo> get _filteredGames {
    final source = _displayGames;
    if (_searchQuery.isEmpty) return source;
    final query = _searchQuery.toLowerCase();
    return source.where((game) {
      return game.displayName.toLowerCase().contains(query) ||
          game.appName.toLowerCase().contains(query) ||
          game.installLocation.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _computeUnplayedInstalledCount();
  }

  @override
  void didUpdateWidget(covariant LibraryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.games != widget.games ||
        oldWidget.allGames != widget.allGames) {
      _computeUnplayedInstalledCount();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleFollow(GameInfo game) async {
    final offerId = game.catalogItemId;
    if (widget.followService.isFollowing(offerId)) {
      await widget.followService.unfollowGame(offerId);
      widget.addLog('Unfollowed ${game.displayName}');
    } else {
      final metadata = game.metadata;
      await widget.followService.followGame(
        FollowedGame(
          offerId: offerId,
          title: game.displayName,
          namespace: game.catalogNamespace,
          thumbnailUrl: metadata?.dieselGameBoxTall ?? metadata?.firstImageUrl,
          followedAt: DateTime.now(),
        ),
      );
      widget.addLog('Following ${game.displayName}');
    }
    setState(() {});
  }

  void _moveGame(GameInfo game) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => MoveGamePage(game: game)),
    );

    if (result == true) {
      widget.addLog('Game moved: ${game.displayName}');
      await widget.onScanGames();
    }
  }

  Future<void> _computeUnplayedInstalledCount() async {
    final playtimeService = widget.playtimeService;
    if (playtimeService == null) {
      if (mounted) {
        setState(() {
          _unplayedInstalledCount = 0;
        });
      }
      return;
    }

    var unplayed = 0;
    for (final game in widget.games) {
      final total = await playtimeService.getTotalPlaytime(game.catalogItemId);
      if (total.inSeconds <= 0) {
        unplayed++;
      }
    }

    if (mounted) {
      setState(() {
        _unplayedInstalledCount = unplayed;
      });
    }
  }

  Future<void> _runUploadQueue(List<GameInfo> games) async {
    if (games.isEmpty || _isQueueRunning) {
      return;
    }

    setState(() {
      _isQueueRunning = true;
      _isQueuePaused = false;
      _queueCancelRequested = false;
      _queueCompleted = 0;
      _queueTotal = games.length;
      _queueFailed.clear();
    });

    for (final game in games) {
      if (_queueCancelRequested) {
        break;
      }

      while (_isQueuePaused && !_queueCancelRequested) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      if (_queueCancelRequested) {
        break;
      }

      await widget.onUploadManifest(game);
      final status = widget.uploadStatuses[game.installationGuid];
      if (status != null && status.status == UploadStatusType.failed) {
        _queueFailed.add(game);
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _queueCompleted++;
      });
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _isQueueRunning = false;
      _isQueuePaused = false;
      _queueCancelRequested = false;
    });
  }

  Future<void> _openDetailsDrawer(GameInfo game) async {
    setState(() {
      _detailsGame = game;
      _detailsLoading = true;
      _detailsTimeline = const [];
      _detailsTotalPlaytime = null;
      _detailsLastPlayedAt = null;
    });

    final playtimeService = widget.playtimeService;
    if (playtimeService != null) {
      final total = await playtimeService.getTotalPlaytime(game.catalogItemId);
      final sessions = await playtimeService.getRecentSessions(limit: 50);
      final timeline = await playtimeService.getDailyTimeline(
        game.catalogItemId,
        days: 14,
      );
      DateTime? lastPlayedAt;
      for (final session in sessions) {
        if (session.gameId == game.catalogItemId) {
          lastPlayedAt = session.startTime;
          break;
        }
      }

      if (mounted && _detailsGame?.installationGuid == game.installationGuid) {
        setState(() {
          _detailsTotalPlaytime = total;
          _detailsLastPlayedAt = lastPlayedAt;
          _detailsTimeline = timeline;
        });
      }
    }

    if (mounted && _detailsGame?.installationGuid == game.installationGuid) {
      setState(() {
        _detailsLoading = false;
      });
    }
  }

  Future<void> _showManifestHealthDialog() async {
    final check = widget.onManifestHealthCheck;
    final repair = widget.onManifestAutoRepair;
    if (check == null) {
      widget.addLog('Manifest health check is unavailable');
      return;
    }

    final report = await check();
    final hasRepairableIssues = report.issues.any(
      (issue) => issue.type == ManifestHealthIssueType.staleManifestLocation,
    );
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Manifest Health',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: SizedBox(
            width: 640,
            child: report.issues.isEmpty
                ? const Text(
                    'No issues detected.',
                    style: TextStyle(color: AppColors.textSecondary),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: report.issues.length,
                    separatorBuilder: (context, index) =>
                        const Divider(color: AppColors.border),
                    itemBuilder: (context, index) {
                      final issue = report.issues[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          issue.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          issue.description,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            if (repair != null && hasRepairableIssues)
              TextButton(
                onPressed: () {
                  final navigator = Navigator.of(context);
                  repair().then((repaired) async {
                    if (!mounted) {
                      return;
                    }
                    widget.addLog(
                      'Manifest auto-repair fixed $repaired entries',
                    );
                    navigator.pop();
                    await widget.onScanGames();
                  });
                },
                child: const Text('Auto-Repair'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showProcessDebugDialog() async {
    final playtimeService = widget.playtimeService;
    if (playtimeService == null) {
      widget.addLog('Process debug is unavailable');
      return;
    }
    final entries = await playtimeService.getProcessDetectionDebugSnapshot();
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Process Detection Debug',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: SizedBox(
            width: 720,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: entries.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: AppColors.border),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    entry.isRunning
                        ? Icons.play_circle_outline_rounded
                        : Icons.pause_circle_outline_rounded,
                    color: entry.isRunning
                        ? AppColors.success
                        : AppColors.textMuted,
                  ),
                  title: Text(
                    entry.gameName,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    entry.matchedProcessPath ?? entry.reason,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _groupKeyForGame(GameInfo game) {
    final mainCatalogItemId = game.mainGameCatalogItemId.trim();
    final mainCatalogNamespace = game.mainGameCatalogNamespace.trim();
    final mainAppName = game.mainGameAppName.trim();

    if (mainCatalogItemId.isNotEmpty) {
      return 'main:${mainCatalogNamespace.toLowerCase()}:${mainCatalogItemId.toLowerCase()}:${mainAppName.toLowerCase()}';
    }

    final catalogItemId = game.catalogItemId.trim();
    final catalogNamespace = game.catalogNamespace.trim();
    if (catalogItemId.isNotEmpty) {
      return 'catalog:${catalogNamespace.toLowerCase()}:${catalogItemId.toLowerCase()}';
    }

    final installLocation = game.installLocation.trim();
    if (installLocation.isNotEmpty) {
      return 'path:${installLocation.toLowerCase().replaceAll('/', '\\')}';
    }

    return 'guid:${game.installationGuid.toLowerCase()}';
  }

  bool _isPrimaryGameForGroup(GameInfo game) {
    final mainCatalogItemId = game.mainGameCatalogItemId.trim();
    final mainAppName = game.mainGameAppName.trim();
    final catalogMatches =
        mainCatalogItemId.isNotEmpty &&
        game.catalogItemId.trim() == mainCatalogItemId;
    final appMatches =
        mainAppName.isNotEmpty && game.appName.trim() == mainAppName;
    return catalogMatches || appMatches;
  }

  List<GameInfo> _getRelatedAddons(GameInfo game) {
    final groupKey = _groupKeyForGame(game);
    final related = widget.allGames.where((candidate) {
      if (candidate.installationGuid == game.installationGuid) {
        return false;
      }
      if (_groupKeyForGame(candidate) != groupKey) {
        return false;
      }
      if (_isPrimaryGameForGroup(candidate)) {
        return false;
      }
      return true;
    }).toList();

    related.sort(
      (a, b) =>
          a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
    );
    return related;
  }

  @override
  Widget build(BuildContext context) {
    final filteredGames = _filteredGames;
    final totalInstallSize = widget.games.fold<int>(
      0,
      (sum, game) => sum + game.installSize,
    );
    final addonsCount = widget.allGames.length - widget.games.length;
    final uploadedCount = widget.uploadStatuses.values
        .where(
          (status) =>
              status.status == UploadStatusType.uploaded ||
              status.status == UploadStatusType.alreadyUploaded,
        )
        .length;
    final uploadCoverage = widget.allGames.isEmpty
        ? 0
        : ((uploadedCount / widget.allGames.length) * 100).round();

    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          _buildHeader(totalInstallSize, addonsCount, uploadCoverage),
          _buildToolbar(filteredGames.length),
          if (_selectionMode) _buildBulkActionBar(filteredGames),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildGameList(filteredGames)),
                if (_detailsGame != null) _buildDetailsPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    int totalInstallSize,
    int addonsCount,
    int uploadCoverage,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Library',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your installed games',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
          const Spacer(),
          _buildInsightPill(
            icon: Icons.storage_rounded,
            label: '${_formatBytes(totalInstallSize)} installed',
          ),
          const SizedBox(width: 8),
          _buildInsightPill(
            icon: Icons.extension_rounded,
            label: '$addonsCount add-ons',
          ),
          const SizedBox(width: 8),
          _buildInsightPill(
            icon: Icons.sports_esports_rounded,
            label: '$_unplayedInstalledCount unplayed',
          ),
          const SizedBox(width: 8),
          _buildInsightPill(
            icon: Icons.cloud_done_rounded,
            label: '$uploadCoverage% uploaded',
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.games_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.games.length} games',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(int gameCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
      child: Row(
        children: [
          _buildDisplayToggle(),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppColors.radiusMedium),
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
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 14, right: 10),
                    child: Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 44),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildIconButton(
            icon: Icons.terminal_rounded,
            onPressed: widget.onToggleConsole,
            tooltip: widget.showConsole ? 'Hide console' : 'Show console',
            isActive: widget.showConsole,
          ),
          const SizedBox(width: 8),
          _buildIconButton(
            icon: Icons.refresh_rounded,
            onPressed: widget.isLoading ? () {} : () => widget.onScanGames(),
            tooltip: 'Rescan games',
          ),
          const SizedBox(width: 8),
          _buildIconButton(
            icon: _selectionMode
                ? Icons.checklist_rounded
                : Icons.checklist_rtl_rounded,
            onPressed: () {
              setState(() {
                _selectionMode = !_selectionMode;
                _selectedGameIds.clear();
              });
            },
            tooltip: _selectionMode ? 'Disable bulk mode' : 'Enable bulk mode',
            isActive: _selectionMode,
          ),
          const SizedBox(width: 8),
          _buildIconButton(
            icon: Icons.health_and_safety_rounded,
            onPressed: _showManifestHealthDialog,
            tooltip: 'Manifest health and repair',
          ),
          const SizedBox(width: 8),
          _buildIconButton(
            icon: Icons.bug_report_rounded,
            onPressed: _showProcessDebugDialog,
            tooltip: 'Process detection debug',
          ),
          const SizedBox(width: 12),
          _buildUploadButton(),
        ],
      ),
    );
  }

  Widget _buildDisplayToggle() {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusSmall),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _buildDisplayToggleButton(
            label: 'Grouped',
            selected: _showGrouped,
            onTap: () => setState(() => _showGrouped = true),
          ),
          _buildDisplayToggleButton(
            label: 'All',
            selected: !_showGrouped,
            onTap: () => setState(() => _showGrouped = false),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayToggleButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
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
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(AppColors.radiusSmall),
              border: Border.all(
                color: isActive
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : AppColors.border,
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    final isDisabled = widget.isUploadingAll || widget.games.isEmpty;

    return MouseRegion(
      cursor: isDisabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: isDisabled ? null : () => widget.onUploadAll(),
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: isDisabled ? AppColors.surface : AppColors.primary,
            borderRadius: BorderRadius.circular(AppColors.radiusSmall),
            border: isDisabled ? Border.all(color: AppColors.border) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isUploadingAll)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                Icon(
                  Icons.cloud_upload_rounded,
                  size: 20,
                  color: isDisabled ? AppColors.textMuted : Colors.white,
                ),
              const SizedBox(width: 10),
              Text(
                widget.isUploadingAll ? 'Uploading...' : 'Upload All',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDisabled ? AppColors.textMuted : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBulkActionBar(List<GameInfo> filteredGames) {
    final selectedGames = filteredGames
        .where((game) => _selectedGameIds.contains(game.installationGuid))
        .toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(28, 0, 28, 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Text(
            '${selectedGames.length} selected',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: selectedGames.isEmpty
                ? null
                : () {
                    for (final game in selectedGames) {
                      _toggleFollow(game);
                    }
                  },
            icon: const Icon(Icons.favorite_border_rounded, size: 16),
            label: const Text('Toggle Follow'),
          ),
          TextButton.icon(
            onPressed: selectedGames.isEmpty
                ? null
                : () => _runUploadQueue(selectedGames),
            icon: const Icon(Icons.queue_rounded, size: 16),
            label: const Text('Queue Upload'),
          ),
          TextButton.icon(
            onPressed: selectedGames.isEmpty
                ? null
                : () {
                    final paths = selectedGames
                        .map((game) => game.installLocation)
                        .join('\n');
                    Clipboard.setData(ClipboardData(text: paths));
                    widget.addLog(
                      'Copied ${selectedGames.length} install paths',
                    );
                  },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy Paths'),
          ),
          const Spacer(),
          if (_isQueueRunning)
            Row(
              children: [
                Text(
                  'Queue $_queueCompleted/$_queueTotal',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () =>
                      setState(() => _isQueuePaused = !_isQueuePaused),
                  icon: Icon(
                    _isQueuePaused
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                    color: AppColors.primary,
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _queueCancelRequested = true),
                  icon: const Icon(Icons.stop_rounded, color: AppColors.error),
                ),
              ],
            )
          else if (_queueFailed.isNotEmpty)
            TextButton.icon(
              onPressed: () =>
                  _runUploadQueue(List<GameInfo>.from(_queueFailed)),
              icon: const Icon(Icons.replay_rounded, size: 16),
              label: Text('Retry Failed (${_queueFailed.length})'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailsPanel() {
    final game = _detailsGame;
    if (game == null) {
      return const SizedBox.shrink();
    }

    final relatedAddons = _getRelatedAddons(game);

    return Container(
      width: 360,
      margin: const EdgeInsets.only(right: 28, bottom: 28),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  game.displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _detailsGame = null),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            game.installLocation,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontFamily: 'JetBrainsMono',
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          if (_detailsLoading)
            const LinearProgressIndicator(color: AppColors.primary)
          else ...[
            _buildDetailRow('Version', game.version),
            _buildDetailRow('Install size', game.formattedSize),
            _buildDetailRow('Manifest hash', game.manifestHash ?? 'Unknown'),
            _buildDetailRow(
              'Last played',
              _detailsLastPlayedAt?.toLocal().toString().substring(0, 16) ??
                  'Never',
            ),
            _buildDetailRow(
              'Total playtime',
              _formatDuration(_detailsTotalPlaytime ?? Duration.zero),
            ),
            const SizedBox(height: 12),
            _buildTimelineChart(),
            if (relatedAddons.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                'Add-ons',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ...relatedAddons
                  .take(5)
                  .map(
                    (addon) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.extension_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              addon.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineChart() {
    if (_detailsTimeline.isEmpty) {
      return const Text(
        'No timeline data yet',
        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
      );
    }

    final maxSeconds = _detailsTimeline
        .map((bucket) => bucket.playtime.inSeconds)
        .fold<int>(0, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '14-day Timeline',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 64,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: _detailsTimeline.map((bucket) {
              final ratio = maxSeconds == 0
                  ? 0.0
                  : bucket.playtime.inSeconds / maxSeconds;
              final height = (ratio * 52).clamp(4.0, 52.0);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Tooltip(
                    message:
                        '${bucket.day.month}/${bucket.day.day}: ${_formatDuration(bucket.playtime)}',
                    child: Container(
                      height: height,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  Widget _buildGameList(List<GameInfo> games) {
    if (widget.isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Scanning Library',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Looking for installed games...',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_displayGames.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppColors.radiusLarge),
              ),
              child: const Icon(
                Icons.games_rounded,
                size: 48,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Games Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.manifestPath,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'JetBrainsMono',
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => widget.onScanGames(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Scan Again'),
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppColors.radiusLarge),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 48,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No results for "$_searchQuery"',
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
      itemCount: games.length,
      separatorBuilder: (_, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final game = games[index];
        final relatedAddons = _getRelatedAddons(game);
        return GameTile(
          game: game,
          addonCount: relatedAddons.length,
          showSelection: _selectionMode,
          selected: _selectedGameIds.contains(game.installationGuid),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedGameIds.add(game.installationGuid);
              } else {
                _selectedGameIds.remove(game.installationGuid);
              }
            });
          },
          uploadStatus: widget.uploadStatuses[game.installationGuid],
          isUploading: widget.uploadingGames.contains(game.installationGuid),
          onUpload: () => widget.onUploadManifest(game),
          onMove: () => _moveGame(game),
          isFollowing: widget.followService.isFollowing(game.catalogItemId),
          onFollowToggle: () => _toggleFollow(game),
          onTap: () => _openDetailsDrawer(game),
        );
      },
    );
  }
}
