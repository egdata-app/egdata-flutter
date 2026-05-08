import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../models/followed_game.dart';
import '../models/daily_playtime_bucket.dart';
import '../models/game_info.dart';
import '../models/library_game.dart';
import '../models/settings.dart';
import '../database/database_service.dart';
import '../models/manifest_health_issue.dart';
import '../models/upload_status.dart';
import '../services/follow_service.dart';
import '../services/library_metadata_service.dart';
import '../services/playtime_service.dart';
import '../widgets/playtime_completion_card.dart';
import '../services/api_service.dart';
import '../services/epic_auth_service.dart';
import '../services/upload_service.dart';
import '../services/sync_queue_service.dart';
import '../widgets/follow_button.dart';
import '../utils/epic_protocol.dart';
import '../utils/image_utils.dart';
import 'library_game_detail_page.dart';
import 'move_game_page.dart';

class LibraryPage extends StatefulWidget {
  final List<GameInfo> games;
  final List<GameInfo> allGames;
  final List<OwnedGameEntry> ownedGames;
  final Map<String, UploadStatus> uploadStatuses;
  final Set<String> uploadingGames;
  final bool isLoading;
  final bool isUploadingAll;
  final bool isFetchingOwnedLibrary;
  final String libraryViewMode;
  final AppSettings? settings;
  final ValueChanged<AppSettings>? onLibraryFiltersChanged;
  final FollowService followService;
  final PlaytimeService? playtimeService;
  final EpicAuthService? epicAuthService;
  final UploadService? uploadService;
  final SyncQueueService? syncQueueService;
  final LibraryMetadataService? metadataService;
  final Future<void> Function()? onRefreshMetadata;
  final String manifestPath;
  final Future<void> Function() onScanGames;
  final Future<void> Function()? onFetchOwnedLibrary;
  final Future<void> Function(List<OwnedGameEntry>)? onSyncOwnedGames;
  final Future<void> Function(GameInfo) onUploadManifest;
  final Future<void> Function() onUploadAll;
  final Future<ManifestHealthReport> Function()? onManifestHealthCheck;
  final Future<int> Function()? onManifestAutoRepair;
  final VoidCallback onToggleConsole;
  final bool showConsole;
  final Function(String) addLog;
  final ValueChanged<String>? onLibraryViewModeChanged;
  final VoidCallback? onNavigateToDashboard;

  const LibraryPage({
    super.key,
    required this.games,
    required this.allGames,
    this.ownedGames = const [],
    required this.uploadStatuses,
    required this.uploadingGames,
    required this.isLoading,
    required this.isUploadingAll,
    this.isFetchingOwnedLibrary = false,
    this.libraryViewMode = 'grid',
    this.settings,
    this.onLibraryFiltersChanged,
    required this.followService,
    this.playtimeService,
    this.epicAuthService,
    this.uploadService,
    this.syncQueueService,
    this.metadataService,
    this.onRefreshMetadata,
    required this.manifestPath,
    required this.onScanGames,
    this.onFetchOwnedLibrary,
    this.onSyncOwnedGames,
    required this.onUploadManifest,
    required this.onUploadAll,
    this.onManifestHealthCheck,
    this.onManifestAutoRepair,
    required this.onToggleConsole,
    required this.showConsole,
    required this.addLog,
    this.onLibraryViewModeChanged,
    this.onNavigateToDashboard,
  });

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  final bool _showGrouped = true;
  LibraryFilter _filter = LibraryFilter.all;
  LibraryOfferTypeFilter _offerTypeFilter = LibraryOfferTypeFilter.any;
  String? _selectedTag;
  bool _onlyOnSale = false;
  bool _onlyFree = false;
  CustomCategory? _selectedCategory;
  bool _categoryRestored = false;
  LibrarySortBy _sortBy = LibrarySortBy.title;
  bool _sortAscending = true;
  bool _selectionMode = false;
  final Set<String> _selectedGameIds = {};
  bool _isQueueRunning = false;
  bool _isQueuePaused = false;
  bool _queueCancelRequested = false;
  int _queueCompleted = 0;
  int _queueTotal = 0;
  final List<GameInfo> _queueFailed = [];
  GameInfo? _detailsGame;
  bool _detailsLoading = false;
  Duration? _detailsTotalPlaytime;
  DateTime? _detailsLastPlayedAt;
  OfferIgdb? _detailsIgdb;
  OfferHltb? _detailsHltb;
  List<DailyPlaytimeBucket> _detailsTimeline = const [];

  /// Active library entry for the inline store-style detail view.
  /// When non-null, the library page renders [LibraryGameDetailPage] in place
  /// of the list so the desktop sidebar stays visible.
  LibraryGame? _detailLibraryGame;

  /// Cached `catalogItemId → total playtime` for card chips.
  Map<String, Duration> _playtimeByGameId = const {};

  /// True while the unified top-bar refresh is running (scan + fetch + sync).
  bool _isRefreshing = false;

  /// Human-readable label for the current refresh phase, or null when idle.
  String? _refreshStep;

  /// Step counter for the current refresh: `_refreshStepIndex / _refreshStepCount`.
  int _refreshStepIndex = 0;
  int _refreshStepCount = 0;

  /// Collapsible sidebar section state.
  final Map<String, bool> _sectionExpanded = {
    'genre': true,
    'status': true,
    'type': true,
    'tags': true,
    'highlights': true,
  };

  LibraryViewMode get _viewMode => widget.libraryViewMode == 'list'
      ? LibraryViewMode.list
      : LibraryViewMode.grid;

  List<LibraryGame> get _mergedLibraryGames {
    final queue = widget.syncQueueService;
    return LibraryGame.merge(
      installedGames: widget.games,
      ownedGames: widget.ownedGames,
      localUploadStatuses: widget.uploadStatuses,
      ownedUploadStatuses: queue?.ownedUploadStatuses ?? const {},
      uploadingInstalledIds: widget.uploadingGames,
      syncingOwnedKeys: queue?.syncingIdentityKeys ?? const {},
      metadataByCatalogItemId: widget.metadataService?.cache ?? const {},
    );
  }

  List<LibraryGame> get _filteredLibraryGames {
    final query = _searchQuery.trim().toLowerCase();
    final tagFilter = _selectedTag;
    final categoryFilter = _selectedCategory;
    final results = _mergedLibraryGames.where((game) {
      final filterMatches = switch (_filter) {
        LibraryFilter.all => true,
        LibraryFilter.installed => game.isInstalled,
        LibraryFilter.notInstalled => !game.isInstalled,
        LibraryFilter.favorites =>
          game.catalogItemId.isNotEmpty &&
              widget.followService.isFollowing(game.catalogItemId),
        LibraryFilter.uploads => game.hasUploadActivity,
      };
      if (!filterMatches) return false;
      if (!_offerTypeFilter.matches(game.offerType)) return false;
      if (_onlyOnSale && !game.isOnSale) return false;
      if (_onlyFree && !game.isFreeMetadata) return false;
      if (tagFilter != null && !game.tags.contains(tagFilter)) return false;
      if (categoryFilter != null &&
          !categoryFilter.gameIdentityKeys.contains(game.identityKey))
        return false;
      if (query.isEmpty) return true;
      return game.title.toLowerCase().contains(query) ||
          game.appName.toLowerCase().contains(query) ||
          game.namespace.toLowerCase().contains(query) ||
          game.installLocation.toLowerCase().contains(query) ||
          game.statusLabel.toLowerCase().contains(query) ||
          (game.developerDisplayName ?? '').toLowerCase().contains(query) ||
          (game.publisherDisplayName ?? '').toLowerCase().contains(query) ||
          game.tags.any((tag) => tag.toLowerCase().contains(query));
    }).toList();

    int compare(LibraryGame a, LibraryGame b) {
      int cmp;
      switch (_sortBy) {
        case LibrarySortBy.title:
          cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
        case LibrarySortBy.releaseDate:
          final ad = a.releaseDate;
          final bd = b.releaseDate;
          if (ad == null && bd == null) {
            cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          } else if (ad == null) {
            cmp = 1;
          } else if (bd == null) {
            cmp = -1;
          } else {
            cmp = ad.compareTo(bd);
          }
          break;
        case LibrarySortBy.lastModified:
          final ad = a.lastModifiedDate;
          final bd = b.lastModifiedDate;
          if (ad == null && bd == null) {
            cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          } else if (ad == null) {
            cmp = 1;
          } else if (bd == null) {
            cmp = -1;
          } else {
            cmp = ad.compareTo(bd);
          }
          break;
      }
      return _sortAscending ? cmp : -cmp;
    }

    results.sort(compare);
    return results;
  }

  /// Sorted unique tags across the (currently merged) library, capped at
  /// 24 to keep the sidebar list usable.
  List<String> get _availableTags {
    final counts = <String, int>{};
    for (final game in _mergedLibraryGames) {
      for (final tag in game.tags) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        if (byCount != 0) return byCount;
        return a.key.toLowerCase().compareTo(b.key.toLowerCase());
      });
    return sorted.take(24).map((e) => e.key).toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _hydrateFiltersFromSettings();
    widget.syncQueueService?.addListener(_onSyncQueueChanged);
    widget.metadataService?.addListener(_onMetadataChanged);
    widget.followService.followedGamesStream.listen((_) {
      if (mounted) setState(() {});
    });
    _searchFocusNode.addListener(_onSearchFocusChanged);
    _loadPlaytime();
  }

  void _hydrateFiltersFromSettings() {
    final s = widget.settings;
    if (s == null) return;
    _filter = LibraryFilter.values.firstWhere(
      (e) => e.name == s.libraryFilter,
      orElse: () => LibraryFilter.all,
    );
    _offerTypeFilter = LibraryOfferTypeFilter.values.firstWhere(
      (e) => e.name == s.libraryOfferTypeFilter,
      orElse: () => LibraryOfferTypeFilter.any,
    );
    _selectedTag = s.librarySelectedTag;
    _onlyOnSale = s.libraryOnlyOnSale;
    _onlyFree = s.libraryOnlyFree;
    _sortBy = LibrarySortBy.values.firstWhere(
      (e) => e.name == s.librarySortBy,
      orElse: () => LibrarySortBy.title,
    );
    _sortAscending = s.librarySortAscending;
    // _selectedCategory is resolved lazily once categories load
    // (see _buildQuickFilterChips's FutureBuilder).
  }

  // Fire-and-forget; persists current filters so they survive an app restart.
  void _persistFilters() {
    final cb = widget.onLibraryFiltersChanged;
    final s = widget.settings;
    if (cb == null || s == null) return;
    cb(
      s.copyWith(
        libraryFilter: _filter.name,
        libraryOfferTypeFilter: _offerTypeFilter.name,
        librarySelectedTag: _selectedTag,
        librarySelectedCategoryName: _selectedCategory?.name,
        libraryOnlyOnSale: _onlyOnSale,
        libraryOnlyFree: _onlyFree,
        librarySortBy: _sortBy.name,
        librarySortAscending: _sortAscending,
      ),
    );
  }

  Future<void> _loadPlaytime() async {
    final service = widget.playtimeService;
    if (service == null) return;
    try {
      final stats = await service.getAllPlaytimeStats();
      if (!mounted) return;
      setState(() {
        _playtimeByGameId = stats;
      });
    } catch (_) {
      // Non-fatal: cards just won't show hours.
    }
  }

  /// Single user-facing "refresh library" action. Re-scans installed
  /// games on disk, refreshes the owned-from-Epic list (when logged in),
  /// and refreshes offer metadata. Each step is best-effort: a failure
  /// in one phase doesn't abort the others.
  Future<void> _refreshAll() async {
    if (_isRefreshing) return;
    final fetchOwned = widget.onFetchOwnedLibrary;
    final isAuthed = widget.epicAuthService?.isAuthenticated ?? false;
    final willFetchEpic = fetchOwned != null && isAuthed;
    final refreshMetadata = widget.onRefreshMetadata;
    final willRefreshMeta = refreshMetadata != null;

    // Steps: scan + (fetch owned)? + (metadata)? + playtime
    final totalSteps = 2 + (willFetchEpic ? 1 : 0) + (willRefreshMeta ? 1 : 0);

    setState(() {
      _isRefreshing = true;
      _refreshStepCount = totalSteps;
      _refreshStepIndex = 0;
      _refreshStep = null;
    });

    void announce(String label) {
      if (!mounted) return;
      setState(() {
        _refreshStepIndex++;
        _refreshStep = label;
      });
    }

    try {
      announce('Scanning local games…');
      try {
        await widget.onScanGames();
      } catch (e) {
        widget.addLog('Scan failed: $e');
      }

      if (willFetchEpic) {
        announce('Fetching Epic library…');
        try {
          await fetchOwned();
        } catch (e) {
          widget.addLog('Epic library fetch failed: $e');
        }
      }

      if (willRefreshMeta) {
        announce('Syncing offer metadata…');
        try {
          await refreshMetadata();
        } catch (e) {
          widget.addLog('Metadata refresh failed: $e');
        }
      }

      announce('Updating playtime…');
      await _loadPlaytime();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _refreshStep = null;
          _refreshStepIndex = 0;
          _refreshStepCount = 0;
        });
      }
    }
  }

  Widget _buildUnifiedRefreshButton() {
    final running = _isRefreshing || widget.isLoading;
    final tooltip = running
        ? 'Refreshing library…'
        : 'Refresh local games, Epic library, and metadata';
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: running ? null : _refreshAll,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: running
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: running
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : AppColors.border,
            ),
          ),
          alignment: Alignment.center,
          child: running
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : const Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
        ),
      ),
    );
  }

  /// Inline status banner shown below the chips during a refresh.
  /// Displays the current step (e.g. "Fetching Epic library… 2 / 4")
  /// and a determinate progress bar while metadata sync is in flight.
  Widget _buildRefreshBanner() {
    if (!_isRefreshing && _refreshStep == null) {
      return const SizedBox.shrink();
    }

    final metadata = widget.metadataService;
    final isMetaPhase = metadata != null && metadata.isSyncing;
    final double? subProgress = isMetaPhase && metadata.syncTotal > 0
        ? metadata.syncProgress / metadata.syncTotal
        : null;
    final overallProgress = _refreshStepCount > 0
        ? _refreshStepIndex / _refreshStepCount
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 22, 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _refreshStep ?? 'Refreshing library…',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (_refreshStepCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Step $_refreshStepIndex of $_refreshStepCount',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: subProgress ?? overallProgress,
                minHeight: 3,
                backgroundColor: AppColors.surfaceLight,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
            ),
            if (isMetaPhase && metadata.syncTotal > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${metadata.syncProgress} / ${metadata.syncTotal} items',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _onSearchFocusChanged() {
    if (mounted) setState(() {});
  }

  void _onMetadataChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant LibraryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.syncQueueService != widget.syncQueueService) {
      oldWidget.syncQueueService?.removeListener(_onSyncQueueChanged);
      widget.syncQueueService?.addListener(_onSyncQueueChanged);
    }
    if (oldWidget.metadataService != widget.metadataService) {
      oldWidget.metadataService?.removeListener(_onMetadataChanged);
      widget.metadataService?.addListener(_onMetadataChanged);
    }
  }

  @override
  void dispose() {
    widget.syncQueueService?.removeListener(_onSyncQueueChanged);
    widget.metadataService?.removeListener(_onMetadataChanged);
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSyncQueueChanged() {
    if (mounted) setState(() {});
  }

  void _toggleFollowLibraryGame(LibraryGame game) async {
    final offerId = game.catalogItemId;
    if (offerId.isEmpty) return;
    if (widget.followService.isFollowing(offerId)) {
      await widget.followService.unfollowGame(offerId);
      widget.addLog('Unfollowed ${game.title}');
    } else {
      await widget.followService.followGame(
        FollowedGame(
          offerId: offerId,
          title: game.title,
          namespace: game.namespace,
          thumbnailUrl: game.boxArtUrl ?? game.wideImageUrl,
          followedAt: DateTime.now(),
        ),
      );
      widget.addLog('Following ${game.title}');
    }
    setState(() {});
  }

  Future<void> _syncLibraryGames(List<LibraryGame> games) async {
    final installedGames = games
        .where((game) => game.isInstalled)
        .map((game) => game.installedGame!)
        .toList();
    final cloudGames = games
        .where((game) => !game.isInstalled && game.ownedGame != null)
        .map((game) => game.ownedGame!)
        .toList();

    if (installedGames.isNotEmpty) {
      await _runUploadQueue(installedGames);
    }
    if (cloudGames.isNotEmpty) {
      await widget.onSyncOwnedGames?.call(cloudGames);
    }
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

  void _openLibraryDetail(LibraryGame game) {
    setState(() => _detailLibraryGame = game);
  }

  void _closeLibraryDetail() {
    setState(() => _detailLibraryGame = null);
  }

  /// Re-resolves the in-detail [LibraryGame] against the latest merged list
  /// so live state (install status, playtime, upload progress) stays fresh
  /// while the detail view is open.
  LibraryGame _refreshDetailGame(LibraryGame current) {
    final updated = _mergedLibraryGames.firstWhere(
      (g) => g.identityKey == current.identityKey,
      orElse: () => current,
    );
    return updated;
  }

  Future<void> _runUploadQueue(List<GameInfo> games) async {
    if (games.isEmpty || _isQueueRunning) {
      return;
    }

    // Expand the queue to include addons if in grouped mode
    final expandedGames = <GameInfo>[];
    for (final game in games) {
      expandedGames.add(game);
      if (_showGrouped) {
        expandedGames.addAll(_getRelatedAddons(game));
      }
    }

    setState(() {
      _isQueueRunning = true;
      _isQueuePaused = false;
      _queueCancelRequested = false;
      _queueCompleted = 0;
      _queueTotal = expandedGames.length;
      _queueFailed.clear();
    });

    for (final game in expandedGames) {
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
      _detailsIgdb = null;
      _detailsHltb = null;
    });

    final apiService = ApiService();
    final playtimeService = widget.playtimeService;

    // First, try to get the offer for this item
    final offer = await apiService
        .getItemOffer(game.catalogItemId)
        .catchError((_) => null);

    // Fetch playtime and API data in parallel
    final results = await Future.wait([
      if (playtimeService != null)
        playtimeService.getTotalPlaytime(game.catalogItemId)
      else
        Future.value(Duration.zero),
      if (playtimeService != null)
        playtimeService.getRecentSessions(limit: 50)
      else
        Future.value(<PlaytimeSessionEntry>[]),
      if (playtimeService != null)
        playtimeService.getDailyTimeline(game.catalogItemId, days: 14)
      else
        Future.value(<DailyPlaytimeBucket>[]),
      if (offer != null)
        apiService.getOfferIgdb(offer.id).catchError((_) => null)
      else
        Future.value(null),
      if (offer != null)
        apiService.getOfferHltb(offer.id).catchError((_) => null)
      else
        Future.value(null),
    ]);

    if (mounted && _detailsGame?.installationGuid == game.installationGuid) {
      final total = results[0] as Duration;
      final sessions = results[1] as List<PlaytimeSessionEntry>;
      final timeline = results[2] as List<DailyPlaytimeBucket>;
      final igdb = results[3] as OfferIgdb?;
      final hltb = results[4] as OfferHltb?;

      DateTime? lastPlayedAt;
      for (final session in sessions) {
        if (session.gameId == game.catalogItemId) {
          lastPlayedAt = session.startTime;
          break;
        }
      }

      setState(() {
        _detailsTotalPlaytime = total;
        _detailsLastPlayedAt = lastPlayedAt;
        _detailsTimeline = timeline;
        _detailsIgdb = igdb;
        _detailsHltb = hltb;
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
    if (_detailLibraryGame != null) {
      final detailGame = _refreshDetailGame(_detailLibraryGame!);
      // Wrapped in a nested Navigator so sub-routes pushed from the detail
      // page (e.g. the full-screen screenshot carousel) stay inside the
      // library content slot instead of covering the desktop shell sidebar.
      return Navigator(
        onGenerateRoute: (_) => MaterialPageRoute(
          builder: (_) => LibraryGameDetailPage(
            key: ValueKey(detailGame.identityKey),
            game: detailGame,
            followService: widget.followService,
            playtimeService: widget.playtimeService,
            onLaunch: _launchGame,
            onInstall: _installGame,
            onMove: _moveGame,
            onSyncManifest: (g) => _syncLibraryGames([g]),
            onBack: _closeLibraryDetail,
          ),
        ),
      );
    }

    final filteredLibraryGames = _filteredLibraryGames;
    final mergedCount = _mergedLibraryGames.length;
    final installedCount = _countForFilter(LibraryFilter.installed);

    return Container(
      color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                _buildQuickFilterChips(),
                _buildRefreshBanner(),
                _buildSummaryLine(
                  total: mergedCount,
                  installed: installedCount,
                  filtered: filteredLibraryGames.length,
                ),
                if (_selectionMode) _buildBulkActionBar(filteredLibraryGames),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildLibraryContent(filteredLibraryGames),
                      ),
                      if (_detailsGame != null) _buildDetailsPanel(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildFilterPanel(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 22, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
          const SizedBox(width: 24),
          Expanded(child: _buildSearchField(compact: true)),
          const SizedBox(width: 16),
          _buildSortMenu(),
          const SizedBox(width: 12),
          _buildViewToggle(),
          const SizedBox(width: 12),
          _buildUnifiedRefreshButton(),
        ],
      ),
    );
  }

  Widget _buildSortMenu() {
    final label = _sortBy.label + (_sortAscending ? ' ↑' : ' ↓');
    return PopupMenuButton<String>(
      tooltip: 'Sort by',
      color: AppColors.surface,
      offset: const Offset(0, 44),
      onSelected: (value) {
        setState(() {
          if (value == 'dir') {
            _sortAscending = !_sortAscending;
            return;
          }
          final next = LibrarySortBy.values.firstWhere(
            (o) => o.name == value,
            orElse: () => _sortBy,
          );
          if (_sortBy == next) {
            _sortAscending = !_sortAscending;
          } else {
            _sortBy = next;
            _sortAscending = next == LibrarySortBy.title;
          }
        });
        _persistFilters();
      },
      itemBuilder: (context) => [
        for (final option in LibrarySortBy.values)
          PopupMenuItem<String>(
            value: option.name,
            child: Row(
              children: [
                if (_sortBy == option)
                  const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: AppColors.primary,
                  )
                else
                  const SizedBox(width: 16),
                const SizedBox(width: 6),
                Text(option.label),
              ],
            ),
          ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'dir',
          child: Row(
            children: [
              Icon(
                _sortAscending
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(_sortAscending ? 'Ascending' : 'Descending'),
            ],
          ),
        ),
      ],
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sort by ',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilterChips() {
    return FutureBuilder<List<CustomCategory>>(
      future: DatabaseService.getInstance().then(
        (db) => db.getCustomCategories(),
      ),
      builder: (context, snapshot) {
        final categories = snapshot.data ?? [];
        final pendingName = widget.settings?.librarySelectedCategoryName;
        if (!_categoryRestored &&
            snapshot.hasData &&
            _selectedCategory == null &&
            pendingName != null) {
          _categoryRestored = true;
          CustomCategory? match;
          for (final c in categories) {
            if (c.name == pendingName) {
              match = c;
              break;
            }
          }
          final resolved = match;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (resolved != null) {
              setState(() => _selectedCategory = resolved);
            } else {
              // Persisted category no longer exists; clear it from settings.
              _persistFilters();
            }
          });
        }
        final allSelected = _selectedCategory == null;
        final allCount = _mergedLibraryGames.length;
        return Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 22, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      setState(() {
                        _filter = LibraryFilter.all;
                        _selectedCategory = null;
                      });
                      _persistFilters();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: allSelected
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: allSelected
                              ? AppColors.primary.withValues(alpha: 0.45)
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'All',
                            style: TextStyle(
                              color: allSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: allSelected
                                  ? AppColors.primary.withValues(alpha: 0.2)
                                  : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$allCount',
                              style: TextStyle(
                                color: allSelected
                                    ? AppColors.primary
                                    : AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  for (final category in categories) ...[
                    _buildCategoryChip(category),
                    const SizedBox(width: 8),
                  ],
                  _buildCategoryAddChip(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip(CustomCategory category) {
    final selected = _selectedCategory == category;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        setState(() {
          _filter = LibraryFilter.all;
          _selectedCategory = selected ? null : category;
        });
        _persistFilters();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.45)
                : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              category.name,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryAddChip() {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: _showCreateCategoryDialog,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            const Text(
              'New Category',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateCategoryDialog() async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'New Category',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Category name',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final navigator = Navigator.of(context);
                final db = await DatabaseService.getInstance();
                await db.saveCustomCategory(
                  CustomCategory(
                    name: controller.text.trim(),
                    gameIdentityKeys: [],
                  ),
                );
                if (mounted) {
                  setState(() {});
                  navigator.pop();
                }
              }
            },
            child: const Text(
              'Create',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterChip(
    LibraryFilter filter,
    String label,
    IconData? icon,
  ) {
    final selected = _filter == filter;
    final count = _countForFilter(filter);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        setState(() => _filter = filter);
        _persistFilters();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.45)
                : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: selected ? AppColors.primary : AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryLine({
    required int total,
    required int installed,
    required int filtered,
  }) {
    final showFilteredHint = filtered != total && total > 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 6, 22, 14),
      child: Row(
        children: [
          Text(
            '$total games total',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '$installed installed',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (showFilteredHint) ...[
            const SizedBox(width: 16),
            Text(
              'showing $filtered',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const Spacer(),
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
            tooltip: 'Manifest health',
          ),
          const SizedBox(width: 8),
          _buildIconButton(
            icon: Icons.bug_report_rounded,
            onPressed: _showProcessDebugDialog,
            tooltip: 'Process debug',
          ),
          const SizedBox(width: 8),
          _buildIconButton(
            icon: Icons.terminal_rounded,
            onPressed: widget.onToggleConsole,
            tooltip: widget.showConsole ? 'Hide console' : 'Show console',
            isActive: widget.showConsole,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    final tags = _availableTags;
    final hasFilters = _hasActiveFilters();

    return Container(
      width: 268,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(left: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sidebar header: Filters + Clear All
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 24, 14, 14),
            child: Row(
              children: [
                const Icon(
                  Icons.tune_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Filters',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                if (hasFilters)
                  InkWell(
                    onTap: _clearAllFilters,
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Text(
                        'Clear All',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildSidebarSection(
                  id: 'status',
                  title: 'Installed Status',
                  child: Column(
                    children: [
                      _buildFilterCheckRow(
                        label: 'Installed',
                        count: _countForFilter(LibraryFilter.installed),
                        checked: _filter == LibraryFilter.installed,
                        onTap: () {
                          setState(() {
                            _filter = _filter == LibraryFilter.installed
                                ? LibraryFilter.all
                                : LibraryFilter.installed;
                          });
                          _persistFilters();
                        },
                      ),
                      _buildFilterCheckRow(
                        label: 'Not Installed',
                        count: _countForFilter(LibraryFilter.notInstalled),
                        checked: _filter == LibraryFilter.notInstalled,
                        onTap: () {
                          setState(() {
                            _filter = _filter == LibraryFilter.notInstalled
                                ? LibraryFilter.all
                                : LibraryFilter.notInstalled;
                          });
                          _persistFilters();
                        },
                      ),
                      _buildFilterCheckRow(
                        label: 'Favorites',
                        count: _countForFilter(LibraryFilter.favorites),
                        checked: _filter == LibraryFilter.favorites,
                        onTap: () {
                          setState(() {
                            _filter = _filter == LibraryFilter.favorites
                                ? LibraryFilter.all
                                : LibraryFilter.favorites;
                          });
                          _persistFilters();
                        },
                      ),
                      _buildFilterCheckRow(
                        label: 'Has Uploads',
                        count: _countForFilter(LibraryFilter.uploads),
                        checked: _filter == LibraryFilter.uploads,
                        onTap: () {
                          setState(() {
                            _filter = _filter == LibraryFilter.uploads
                                ? LibraryFilter.all
                                : LibraryFilter.uploads;
                          });
                          _persistFilters();
                        },
                      ),
                    ],
                  ),
                ),
                _buildSidebarSection(
                  id: 'type',
                  title: 'Type',
                  child: Column(
                    children: [
                      for (final type in LibraryOfferTypeFilter.values)
                        if (type != LibraryOfferTypeFilter.any)
                          _buildFilterCheckRow(
                            label: type.label,
                            count: _countForOfferType(type),
                            checked: _offerTypeFilter == type,
                            onTap: () {
                              setState(() {
                                _offerTypeFilter = _offerTypeFilter == type
                                    ? LibraryOfferTypeFilter.any
                                    : type;
                              });
                              _persistFilters();
                            },
                          ),
                    ],
                  ),
                ),
                _buildSidebarSection(
                  id: 'highlights',
                  title: 'Highlights',
                  child: Column(
                    children: [
                      _buildFilterCheckRow(
                        label: 'On Sale',
                        checked: _onlyOnSale,
                        onTap: () {
                          setState(() => _onlyOnSale = !_onlyOnSale);
                          _persistFilters();
                        },
                      ),
                      _buildFilterCheckRow(
                        label: 'Free',
                        checked: _onlyFree,
                        onTap: () {
                          setState(() => _onlyFree = !_onlyFree);
                          _persistFilters();
                        },
                      ),
                    ],
                  ),
                ),
                if (tags.isNotEmpty)
                  _buildSidebarSection(
                    id: 'tags',
                    title: 'Tags',
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: tags
                            .map((tag) => _buildTagChip(tag))
                            .toList(growable: false),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return _filter != LibraryFilter.all ||
        _offerTypeFilter != LibraryOfferTypeFilter.any ||
        _selectedTag != null ||
        _selectedCategory != null ||
        _onlyOnSale ||
        _onlyFree ||
        _searchQuery.isNotEmpty;
  }

  void _clearAllFilters() {
    setState(() {
      _filter = LibraryFilter.all;
      _offerTypeFilter = LibraryOfferTypeFilter.any;
      _selectedTag = null;
      _selectedCategory = null;
      _onlyOnSale = false;
      _onlyFree = false;
      _searchController.clear();
      _searchQuery = '';
    });
    _persistFilters();
  }

  int _countForOfferType(LibraryOfferTypeFilter type) {
    if (type == LibraryOfferTypeFilter.any) return _mergedLibraryGames.length;
    return _mergedLibraryGames.where((g) => type.matches(g.offerType)).length;
  }

  Widget _buildSidebarSection({
    required String id,
    required String title,
    required Widget child,
  }) {
    final expanded = _sectionExpanded[id] ?? true;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _sectionExpanded[id] = !expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 14, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: expanded ? child : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCheckRow({
    required String label,
    int? count,
    required bool checked,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: checked ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: checked ? AppColors.primary : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: checked
                  ? const Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: Colors.black,
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: checked
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: checked ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (count != null)
              Text(
                '$count',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    final selected = _selectedTag == tag;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        setState(() => _selectedTag = selected ? null : tag);
        _persistFilters();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.18)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.5)
                : AppColors.border,
          ),
        ),
        child: Text(
          tag,
          style: TextStyle(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  int _countForFilter(LibraryFilter filter) {
    final games = _mergedLibraryGames;
    return switch (filter) {
      LibraryFilter.all => games.length,
      LibraryFilter.installed => games.where((g) => g.isInstalled).length,
      LibraryFilter.notInstalled => games.where((g) => !g.isInstalled).length,
      LibraryFilter.favorites =>
        games
            .where(
              (g) =>
                  g.catalogItemId.isNotEmpty &&
                  widget.followService.isFollowing(g.catalogItemId),
            )
            .length,
      LibraryFilter.uploads => games.where((g) => g.hasUploadActivity).length,
    };
  }

  Widget _buildSearchField({bool compact = false}) {
    final focused = _searchFocusNode.hasFocus;
    final height = compact ? 40.0 : 46.0;
    final iconSize = compact ? 18.0 : 20.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusSmall),
        border: Border.all(
          color: focused
              ? AppColors.primary.withValues(alpha: 0.55)
              : AppColors.border,
          width: 1,
        ),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: Icon(
              Icons.search_rounded,
              size: iconSize,
              color: focused ? AppColors.primary : AppColors.textMuted,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: (value) => setState(() => _searchQuery = value),
              cursorColor: AppColors.primary,
              cursorWidth: 1.5,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
              decoration: const InputDecoration(
                isCollapsed: true,
                hintText: 'Search games...',
                hintStyle: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: iconSize - 2,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
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
          _buildIconSegmentButton(
            icon: Icons.grid_view_rounded,
            selected: _viewMode == LibraryViewMode.grid,
            tooltip: 'Grid view',
            onTap: () => widget.onLibraryViewModeChanged?.call('grid'),
          ),
          _buildIconSegmentButton(
            icon: Icons.view_list_rounded,
            selected: _viewMode == LibraryViewMode.list,
            tooltip: 'List view',
            onTap: () => widget.onLibraryViewModeChanged?.call('list'),
          ),
        ],
      ),
    );
  }

  Widget _buildIconSegmentButton({
    required IconData icon,
    required bool selected,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
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

  Widget _buildBulkActionBar(List<LibraryGame> filteredGames) {
    final selectedGames = filteredGames
        .where((game) => _selectedGameIds.contains(game.identityKey))
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
                      _toggleFollowLibraryGame(game);
                    }
                  },
            icon: const Icon(Icons.favorite_border_rounded, size: 16),
            label: const Text('Toggle Follow'),
          ),
          TextButton.icon(
            onPressed: selectedGames.isEmpty
                ? null
                : () => _syncLibraryGames(selectedGames),
            icon: const Icon(Icons.queue_rounded, size: 16),
            label: const Text('Sync Selected'),
          ),
          TextButton.icon(
            onPressed: selectedGames.isEmpty
                ? null
                : () {
                    final paths = selectedGames
                        .map((game) => game.installLocation)
                        .where((path) => path.isNotEmpty)
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
            const SizedBox(height: 16),
            PlaytimeCompletionCard(
              offerId: game.catalogItemId,
              igdb: _detailsIgdb,
              hltb: _detailsHltb,
              playtimeService: widget.playtimeService,
            ),
            const SizedBox(height: 16),
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

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    bool isMono = false,
  }) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontFamily: isMono ? 'JetBrainsMono' : null,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryContent(List<LibraryGame> games) {
    if (widget.isLoading && widget.ownedGames.isEmpty) {
      return _buildLibraryLoadingState();
    }

    if (_mergedLibraryGames.isEmpty) {
      return _buildLibraryEmptyState();
    }

    if (games.isEmpty && _searchQuery.isNotEmpty) {
      return _buildNoSearchResults();
    }

    if (games.isEmpty) {
      return _buildNoFilterResults();
    }

    return _viewMode == LibraryViewMode.grid
        ? _buildLibraryGrid(games)
        : _buildLibraryRows(games);
  }

  Widget _buildLibraryLoadingState() {
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
            'Looking for installed games and cached Epic ownership...',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryEmptyState() {
    final isAuthenticated = widget.epicAuthService?.isAuthenticated ?? false;
    final title = isAuthenticated
        ? 'Fetch Your Epic Library'
        : 'Connect Epic Games';
    final body = isAuthenticated
        ? 'Fetch your Epic-owned games to browse installed and not-installed titles together.'
        : 'Log in with Epic Games to show owned games and upload cloud manifests without installing them.';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
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
                Icons.library_books_rounded,
                size: 48,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: widget.isFetchingOwnedLibrary
                  ? null
                  : () => widget.onFetchOwnedLibrary?.call(),
              icon: widget.isFetchingOwnedLibrary
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      isAuthenticated
                          ? Icons.download_rounded
                          : Icons.login_rounded,
                    ),
              label: Text(
                isAuthenticated
                    ? 'Fetch Epic Library'
                    : 'Login with Epic Games',
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: widget.onScanGames,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Scan Installed Games'),
            ),
            if (widget.manifestPath.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                widget.manifestPath,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'JetBrainsMono',
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoSearchResults() {
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

  Widget _buildNoFilterResults() {
    final label = switch (_filter) {
      LibraryFilter.all => 'No games',
      LibraryFilter.installed => 'No installed games',
      LibraryFilter.notInstalled => 'No not-installed games',
      LibraryFilter.favorites => 'No favorites yet',
      LibraryFilter.uploads => 'No upload activity',
    };
    return Center(
      child: Text(
        label,
        style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildLibraryGrid(List<LibraryGame> games) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Storefront-style cover tiles: dense, poster-first, and with minimal
        // chrome below the artwork.
        const targetMin = 156.0;
        final available = constraints.maxWidth - 56; // horizontal padding
        final columns = (available / targetMin).floor().clamp(2, 8).toInt();
        final cardWidth = (available - (columns - 1) * 16) / columns;
        final cardHeight = (cardWidth * 4 / 3) + 66;

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: cardHeight,
            mainAxisSpacing: 18,
            crossAxisSpacing: 16,
          ),
          itemCount: games.length,
          itemBuilder: (context, index) => _buildLibraryCard(games[index]),
        );
      },
    );
  }

  Widget _buildLibraryRows(List<LibraryGame> games) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
      itemCount: games.length,
      separatorBuilder: (_, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _buildLibraryRow(games[index]),
    );
  }

  Widget _buildLibraryCard(LibraryGame game) {
    final imageUrl = game.boxArtUrl ?? game.wideImageUrl;
    final selected = _selectedGameIds.contains(game.identityKey);
    final playtime = _playtimeByGameId[game.catalogItemId];

    return _HoverRegion(
      cursor: SystemMouseCursors.click,
      builder: (context, isHovered) {
        return GestureDetector(
          onTap: () => _openLibraryDetail(game),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            transform: Matrix4.translationValues(0, isHovered ? -3 : 0, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : isHovered
                            ? AppColors.borderLight
                            : Colors.transparent,
                        width: selected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isHovered ? 0.42 : 0.28,
                          ),
                          blurRadius: isHovered ? 18 : 10,
                          offset: Offset(0, isHovered ? 10 : 5),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        imageUrl != null
                            ? Image.network(
                                ImageUtils.getOptimizedUrl(
                                  imageUrl,
                                  width: 360,
                                  height: 480,
                                ),
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    _buildCardPlaceholder(),
                              )
                            : _buildCardPlaceholder(),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.08),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.72),
                              ],
                              stops: const [0, 0.52, 1],
                            ),
                          ),
                        ),
                        if (!game.isInstalled)
                          Container(
                            color: Colors.black.withValues(alpha: 0.22),
                          ),
                        if (_selectionMode)
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.52),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding: const EdgeInsets.all(2),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: selected,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value ?? false) {
                                        _selectedGameIds.add(game.identityKey);
                                      } else {
                                        _selectedGameIds.remove(
                                          game.identityKey,
                                        );
                                      }
                                    });
                                  },
                                  activeColor: AppColors.primary,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IgnorePointer(
                            ignoring: !isHovered,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 120),
                              opacity: isHovered ? 1 : 0,
                              child: _buildCardMenu(game),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 10,
                          right: 10,
                          bottom: 10,
                          child: IgnorePointer(
                            ignoring: !isHovered,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 120),
                              opacity: isHovered ? 1 : 0,
                              child: _buildCardOverlayAction(game),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  game.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isHovered
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      Icons.play_arrow_rounded,
                      size: 13,
                      color: _statusColor(game),
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        playtime != null && playtime.inMinutes > 0
                            ? '${_formatHours(playtime)} hrs'
                            : game.statusLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatHours(Duration duration) {
    final hours = duration.inMinutes / 60.0;
    if (hours >= 10) return hours.toStringAsFixed(0);
    return hours.toStringAsFixed(1);
  }

  Widget _buildCardOverlayAction(LibraryGame game) {
    final installed = game.isInstalled;
    final IconData icon;
    final String label;
    final VoidCallback? onPressed;

    if (installed) {
      icon = Icons.play_arrow_rounded;
      label = 'Play';
      onPressed = () => _launchGame(game);
    } else if (game.ownedGame != null) {
      icon = Icons.download_rounded;
      label = 'Install';
      onPressed = () => _installGame(game);
    } else {
      icon = Icons.cloud_sync_rounded;
      label = 'Sync manifest';
      onPressed = game.isUploadRunning ? null : () => _syncLibraryGames([game]);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: SizedBox(
          height: 34,
          child: FilledButton.icon(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.88),
              foregroundColor: Colors.black,
              disabledBackgroundColor: Colors.black.withValues(alpha: 0.38),
              disabledForegroundColor: AppColors.textMuted,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              elevation: 0,
            ),
            icon: Icon(icon, size: 16),
            label: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchGame(LibraryGame game) async {
    final installed = game.installedGame;
    if (installed == null) return;
    final uri = EpicProtocol.launchApp(
      installed.appName,
      namespace: installed.catalogNamespace,
      itemId: installed.catalogItemId,
    );
    final ok = await EpicProtocol.launch(uri);
    widget.addLog(
      ok
          ? 'Launching ${installed.displayName}'
          : 'Could not launch ${installed.displayName} (Epic launcher missing?)',
    );
  }

  Future<void> _installGame(LibraryGame game) async {
    final owned = game.ownedGame;
    if (owned == null) return;
    final uri = EpicProtocol.installApp(
      owned.appName,
      namespace: owned.namespace,
      itemId: owned.catalogItemId,
    );
    final ok = await EpicProtocol.launch(uri);
    widget.addLog(
      ok
          ? 'Install requested for ${owned.title}'
          : 'Could not request install for ${owned.title}',
    );
  }

  Widget _buildLibraryRow(LibraryGame game) {
    final imageUrl = game.boxArtUrl ?? game.wideImageUrl;
    final selected = _selectedGameIds.contains(game.identityKey);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _openLibraryDetail(game),
        child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          if (_selectionMode) ...[
            Checkbox(
              value: selected,
              onChanged: (value) {
                setState(() {
                  if (value ?? false) {
                    _selectedGameIds.add(game.identityKey);
                  } else {
                    _selectedGameIds.remove(game.identityKey);
                  }
                });
              },
              activeColor: AppColors.primary,
            ),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 54,
            height: 54,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: imageUrl != null
                  ? Image.network(
                      ImageUtils.getOptimizedUrl(
                        imageUrl,
                        width: 108,
                        height: 108,
                      ),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _buildCardPlaceholder(),
                    )
                  : _buildCardPlaceholder(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildDetailChip(
                      icon: Icons.tag_rounded,
                      label: game.appName,
                      isMono: true,
                    ),
                    const SizedBox(width: 12),
                    _buildDetailChip(
                      icon: Icons.apps_rounded,
                      label: game.namespace,
                    ),
                    if (game.versionLabel.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      _buildDetailChip(
                        icon: Icons.update_rounded,
                        label: game.versionLabel,
                      ),
                    ],
                  ],
                ),
                if (game.installLocation.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    game.installLocation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontFamily: 'JetBrainsMono',
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildStatusChip(
            game.isInstalled ? 'Installed' : 'Not installed',
            game.isInstalled ? AppColors.success : AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          _buildStatusChip(game.statusLabel, _statusColor(game)),
          const SizedBox(width: 12),
          if (game.catalogItemId.isNotEmpty)
            FollowButton(
              isFollowing: widget.followService.isFollowing(game.catalogItemId),
              onToggle: () => _toggleFollowLibraryGame(game),
              compact: true,
            ),
          const SizedBox(width: 8),
          if (game.isInstalled) ...[
            _buildSmallActionButton(
              icon: Icons.drive_file_move_rounded,
              tooltip: 'Move game',
              onPressed: () => _moveGame(game.installedGame!),
            ),
            const SizedBox(width: 8),
          ],
          _buildSmallActionButton(
            icon: game.isInstalled
                ? Icons.cloud_upload_rounded
                : Icons.cloud_sync_rounded,
            tooltip: game.isInstalled
                ? 'Upload manifest'
                : 'Sync cloud manifest',
            onPressed: game.isUploadRunning
                ? null
                : () => _syncLibraryGames([game]),
          ),
        ],
      ),
        ),
      ),
    );
  }

  Widget _buildCardMenu(LibraryGame game) {
    final isFollowing =
        game.catalogItemId.isNotEmpty &&
        widget.followService.isFollowing(game.catalogItemId);
    return PopupMenuButton<String>(
      tooltip: 'More actions',
      color: AppColors.surface,
      padding: EdgeInsets.zero,
      splashRadius: 14,
      position: PopupMenuPosition.under,
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.more_horiz_rounded,
          size: 16,
          color: Colors.white,
        ),
      ),
      onSelected: (value) {
        switch (value) {
          case 'details':
            if (game.isInstalled) {
              _openDetailsDrawer(game.installedGame!);
            }
            break;
          case 'sync':
            _syncLibraryGames([game]);
            break;
          case 'follow':
            _toggleFollowLibraryGame(game);
            break;
          case 'move':
            if (game.isInstalled) {
              _moveGame(game.installedGame!);
            }
            break;
        }
      },
      itemBuilder: (context) => [
        if (game.isInstalled)
          const PopupMenuItem(
            value: 'details',
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16),
                SizedBox(width: 10),
                Text('View details'),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'sync',
          enabled: !game.isUploadRunning,
          child: Row(
            children: [
              Icon(
                game.isInstalled
                    ? Icons.cloud_upload_rounded
                    : Icons.cloud_sync_rounded,
                size: 16,
              ),
              const SizedBox(width: 10),
              Text(
                game.isInstalled ? 'Upload manifest' : 'Sync cloud manifest',
              ),
            ],
          ),
        ),
        if (game.catalogItemId.isNotEmpty)
          PopupMenuItem(
            value: 'follow',
            child: Row(
              children: [
                Icon(
                  isFollowing
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 16,
                  color: isFollowing ? AppColors.primary : null,
                ),
                const SizedBox(width: 10),
                Text(isFollowing ? 'Unfollow' : 'Follow'),
              ],
            ),
          ),
        if (game.isInstalled)
          const PopupMenuItem(
            value: 'move',
            child: Row(
              children: [
                Icon(Icons.drive_file_move_rounded, size: 16),
                SizedBox(width: 10),
                Text('Move install'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCardPlaceholder() {
    return Container(
      color: AppColors.surfaceLight,
      child: const Center(
        child: Icon(Icons.games_rounded, color: AppColors.textMuted, size: 32),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildSmallActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(
              icon,
              size: 17,
              color: onPressed == null
                  ? AppColors.textMuted
                  : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(LibraryGame game) {
    if (game.isUploadRunning) return AppColors.warning;
    final status = game.uploadStatus?.status;
    if (status == null) {
      return game.isInstalled ? AppColors.success : AppColors.textMuted;
    }
    switch (status) {
      case UploadStatusType.uploaded:
      case UploadStatusType.alreadyUploaded:
        return AppColors.success;
      case UploadStatusType.failed:
        return AppColors.error;
      case UploadStatusType.pending:
        return AppColors.textMuted;
      case UploadStatusType.uploading:
        return AppColors.warning;
    }
  }
}

/// Tracks pointer hover state and rebuilds via setState so the state survives
/// parent rebuilds (e.g. while syncing).
class _HoverRegion extends StatefulWidget {
  final Widget Function(BuildContext context, bool isHovered) builder;
  final MouseCursor cursor;

  const _HoverRegion({required this.builder, this.cursor = MouseCursor.defer});

  @override
  State<_HoverRegion> createState() => _HoverRegionState();
}

class _HoverRegionState extends State<_HoverRegion> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.cursor,
      onEnter: (_) {
        if (!_isHovered) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (_isHovered) setState(() => _isHovered = false);
      },
      child: widget.builder(context, _isHovered),
    );
  }
}

