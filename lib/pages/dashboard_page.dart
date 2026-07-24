import 'dart:async';

import 'package:flutter/material.dart';

import '../database/database_service.dart';
import '../main.dart';
import '../models/epic_progress.dart';
import '../models/game_info.dart';
import '../models/playtime_stats.dart';
import '../services/epic_auth_service.dart';
import '../services/epic_progress_service.dart';
import '../services/playtime_service.dart';
import '../utils/epic_protocol.dart';
import '../utils/image_utils.dart';

class DashboardPage extends StatefulWidget {
  final PlaytimeService? playtimeService;
  final List<GameInfo> installedGames;
  final List<OwnedGameEntry> ownedGames;
  final int ownedGamesCount;
  final DatabaseService? db;
  final EpicAuthService? epicAuthService;
  final EpicProgressService? epicProgressService;
  final Map<String, EpicGameProgress> progressByCatalogItemId;
  final EpicProgressProofResult? progressProof;
  final Future<void> Function({bool forceRefresh})? onRefreshOfficialProgress;
  final VoidCallback? onOpenLibrary;
  final VoidCallback? onOpenProgress;
  final VoidCallback? onOpenSyncCenter;
  final ValueChanged<GameInfo>? onOpenGameDetails;

  const DashboardPage({
    super.key,
    this.playtimeService,
    this.installedGames = const [],
    this.ownedGames = const [],
    this.ownedGamesCount = 0,
    this.db,
    this.epicAuthService,
    this.epicProgressService,
    this.progressByCatalogItemId = const {},
    this.progressProof,
    this.onRefreshOfficialProgress,
    this.onOpenLibrary,
    this.onOpenProgress,
    this.onOpenSyncCenter,
    this.onOpenGameDetails,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const Color _epicBlue = Color(0xFF0078F2);
  static const Color _panel = Color(0xFF141414);
  static const Color _panelRaised = Color(0xFF1A1A1A);
  static const Color _panelHover = Color(0xFF202020);

  PlaytimeStats? _playtimeStats;
  Map<String, EpicGameProgress> _progressByCatalogItemId = {};
  PlaytimeSessionEntry? _activeSession;
  StreamSubscription<PlaytimeStats>? _statsSubscription;
  StreamSubscription<PlaytimeSessionEntry?>? _activeGameSubscription;
  StreamSubscription<int>? _uploadCountSubscription;
  Timer? _durationTimer;
  int _uploadCount = 0;
  bool _isRefreshingProgress = false;
  EpicProgressProofResult? _progressProof;

  @override
  void initState() {
    super.initState();
    _loadPlaytimeStats();
    _loadUploadCount();
    if (_hasProvidedProgress) {
      _applyProvidedProgress();
    } else {
      _loadProgressSnapshot();
    }

    _statsSubscription = widget.playtimeService?.statsStream.listen((stats) {
      if (mounted) {
        setState(() => _playtimeStats = stats);
      }
    });

    _activeGameSubscription = widget.playtimeService?.activeGameStream.listen((
      session,
    ) {
      if (mounted) {
        final wasActive = _activeSession != null;
        final isActive = session != null;
        setState(() => _activeSession = session);

        if (isActive && !wasActive) {
          _startDurationTimer();
        } else if (!isActive && wasActive) {
          _stopDurationTimer();
        }
      }
    });

    _uploadCountSubscription = widget.db?.uploadCountStream.listen((count) {
      if (mounted) {
        setState(() => _uploadCount = count);
      }
    });
  }

  @override
  void didUpdateWidget(covariant DashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.installedGames != widget.installedGames ||
        oldWidget.ownedGames != widget.ownedGames ||
        oldWidget.epicProgressService != widget.epicProgressService ||
        oldWidget.progressByCatalogItemId != widget.progressByCatalogItemId ||
        oldWidget.progressProof != widget.progressProof) {
      if (_hasProvidedProgress) {
        _applyProvidedProgress();
        return;
      }
      _loadProgressSnapshot();
    }
  }

  @override
  void dispose() {
    _statsSubscription?.cancel();
    _activeGameSubscription?.cancel();
    _uploadCountSubscription?.cancel();
    _stopDurationTimer();
    super.dispose();
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _activeSession != null) {
        setState(() {});
      }
    });
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  Future<void> _loadPlaytimeStats() async {
    if (widget.playtimeService == null) return;
    final stats = await widget.playtimeService!.getWeeklyStats();
    if (mounted) {
      setState(() => _playtimeStats = stats);
    }
  }

  Future<void> _loadUploadCount() async {
    if (widget.db == null) return;
    final count = await widget.db!.getManifestUploadCount();
    if (mounted) {
      setState(() => _uploadCount = count);
    }
  }

  bool get _hasProvidedProgress =>
      widget.progressProof != null || widget.progressByCatalogItemId.isNotEmpty;

  void _applyProvidedProgress() {
    if (!mounted) return;
    setState(() {
      _progressProof = widget.progressProof;
      _progressByCatalogItemId = widget.progressByCatalogItemId;
      _isRefreshingProgress = false;
    });
  }

  Future<void> _loadProgressSnapshot({bool forceRefresh = false}) async {
    if (forceRefresh && widget.onRefreshOfficialProgress != null) {
      setState(() => _isRefreshingProgress = true);
      try {
        await widget.onRefreshOfficialProgress!(forceRefresh: true);
      } finally {
        if (mounted) {
          setState(() => _isRefreshingProgress = false);
        }
      }
      return;
    }

    if (!forceRefresh && _hasProvidedProgress) {
      _applyProvidedProgress();
      return;
    }
    if (!forceRefresh && widget.onRefreshOfficialProgress != null) {
      return;
    }

    final service = widget.epicProgressService;
    if (service == null) return;

    setState(() => _isRefreshingProgress = true);
    try {
      final catalogIds = <String>[];
      final artifactIds = <String, String>{};
      final productIds = <String, String>{};
      for (final game in widget.installedGames) {
        final catalogItemId = game.catalogItemId.trim();
        if (catalogItemId.isEmpty) continue;
        catalogIds.add(catalogItemId);
        if (game.appName.trim().isNotEmpty) {
          artifactIds[catalogItemId] = game.appName.trim();
        }
      }
      for (final game in widget.ownedGames) {
        final catalogItemId = game.catalogItemId.trim();
        if (catalogItemId.isEmpty) continue;
        final appName = game.appName.trim();
        final productId = game.assetId.trim();
        if (appName.isNotEmpty) {
          artifactIds.putIfAbsent(catalogItemId, () => appName);
        }
        if (productId.isNotEmpty &&
            productId.toLowerCase() != appName.toLowerCase()) {
          productIds[catalogItemId] = productId;
        }
      }

      if (catalogIds.isEmpty) {
        final proof = await service.verifyOfficialProgressAccess(
          forceRefresh: forceRefresh,
        );
        if (mounted) {
          setState(() {
            _progressProof = proof;
            _progressByCatalogItemId = {};
          });
        }
        return;
      }

      final snapshot = await service.loadProgressSnapshot(
        catalogIds,
        artifactIdByCatalogItemId: artifactIds,
        productIdByCatalogItemId: productIds,
        achievementProductLimit: 24,
        forceRefresh: forceRefresh,
      );
      if (mounted) {
        setState(() {
          _progressProof = snapshot.proof;
          _progressByCatalogItemId = snapshot.gamesByCatalogItemId;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _progressProof =
              EpicProgressProofResult.blockedByPlaytimeProbeFailure(
                failure: e.toString(),
              );
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshingProgress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPrimaryGrid(),
                  const SizedBox(height: 20),
                  _buildRecentGamesShelf(),
                  const SizedBox(height: 20),
                  _buildBottomPanels(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    final authConnected = widget.epicAuthService?.isAuthenticated ?? false;
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.transparent,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: widget.onOpenLibrary,
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Search EGData...',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          _topPill(
            icon: Icons.sync_rounded,
            label: _topSyncLabel(),
            color: _proofColor(_progressProof),
          ),
          const SizedBox(width: 10),
          _topPill(
            icon: authConnected
                ? Icons.account_circle_rounded
                : Icons.login_rounded,
            label: authConnected ? 'Epic connected' : 'Epic sign in',
            color: authConnected ? AppColors.success : AppColors.textMuted,
          ),
        ],
      ),
    );
  }

  Widget _topPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color == AppColors.textMuted
                  ? AppColors.textSecondary
                  : color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 820;
        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildContinuePlayingCard(),
              const SizedBox(height: 16),
              _buildLibraryStatusCard(),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildContinuePlayingCard()),
            const SizedBox(width: 16),
            SizedBox(width: 226, child: _buildLibraryStatusCard()),
          ],
        );
      },
    );
  }

  Widget _buildContinuePlayingCard() {
    final game = _heroGame();
    final imageUrl = _heroImage(game);
    final progress = _progressForGame(game);
    final playtime = _bestPlaytimeForGame(game, progress);
    final playtimeLabel = progress?.officialPlaytime != null
        ? 'Official playtime'
        : 'Local playtime';
    final achievementPercent = progress?.achievementPercent;

    return Container(
      height: 268,
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(AppColors.radiusSmall),
        border: Border.all(color: AppColors.borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null)
            Image.network(
              ImageUtils.getOptimizedUrl(imageUrl, width: 1200, height: 560),
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
              errorBuilder: (_, _, _) => Container(color: _panel),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.background.withValues(alpha: 0.97),
                  AppColors.background.withValues(alpha: 0.87),
                  AppColors.background.withValues(
                    alpha: imageUrl == null ? 0.9 : 0.28,
                  ),
                ],
                stops: const [0, 0.56, 1],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _activeSession == null ? 'CONTINUE PLAYING' : 'NOW PLAYING',
                  style: const TextStyle(
                    color: _epicBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  game?.displayName ?? 'No installed games found',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _heroSubtitle(game),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: _featureMetric(
                        label: playtimeLabel,
                        value: playtime == null
                            ? '-'
                            : _formatPlaytime(playtime),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(child: _achievementMetric(achievementPercent)),
                    const SizedBox(width: 18),
                    Expanded(
                      child: _featureMetric(
                        label: 'Install location',
                        value: _installLocationLabel(game),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: game == null ? null : () => _launchGame(game),
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: const Text('Launch'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _epicBlue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _panelHover,
                        disabledForegroundColor: AppColors.textMuted,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _secondaryAction(
                      icon: Icons.info_outline_rounded,
                      label: 'Details',
                      onTap: game == null
                          ? widget.onOpenLibrary
                          : () {
                              final open = widget.onOpenGameDetails;
                              if (open != null) {
                                open(game);
                              } else {
                                widget.onOpenLibrary?.call();
                              }
                            },
                    ),
                    const Spacer(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureMetric({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _achievementMetric(double? achievementPercent) {
    final progress = _achievementFraction(achievementPercent);
    final value = progress == null
        ? 'Not loaded'
        : '${(progress * 100).round()}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ACHIEVEMENTS',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: _panelHover,
                  color: _epicBlue,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _secondaryAction({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        disabledForegroundColor: AppColors.textMuted,
        side: const BorderSide(color: AppColors.borderLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildLibraryStatusCard() {
    final missingMetadata = _missingMetadataCount;
    final missingManifests = _missingManifestCount;
    final hasDataIssues = missingMetadata > 0 || missingManifests > 0;

    return SizedBox(
      height: 268,
      child: _panelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Library Status',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            _statusLine(
              label: 'Owned',
              value: widget.ownedGamesCount > 0
                  ? widget.ownedGamesCount.toString()
                  : '-',
            ),
            _statusLine(
              label: 'Installed',
              value: '${widget.installedGames.length}',
            ),
            _statusLine(label: 'Updates', value: '-'),
            _statusLine(label: 'Missing metadata', value: '$missingMetadata'),
            const Spacer(),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Sync Center',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _statusBadge(
                  hasDataIssues ? 'Review' : 'Good',
                  hasDataIssues ? AppColors.warning : AppColors.success,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _panelCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(AppColors.radiusSmall),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: child,
    );
  }

  Widget _statusLine({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildRecentGamesShelf() {
    final games = _recentGamesForShelf();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Games',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        if (games.isEmpty)
          _emptyPanel(
            icon: Icons.sports_esports_rounded,
            title: 'No installed games yet',
            subtitle: 'Scan your Epic library to populate this launcher view.',
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              if (compact) {
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: games
                      .map(
                        (game) => SizedBox(width: 150, child: _gameTile(game)),
                      )
                      .toList(),
                );
              }
              return Row(
                children: [
                  for (var index = 0; index < games.length; index++) ...[
                    Expanded(child: _gameTile(games[index])),
                    if (index != games.length - 1) const SizedBox(width: 12),
                  ],
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _gameTile(GameInfo game) {
    final coverUrl = _coverImage(game);
    final progress = _progressForGame(game);
    final playtime = _bestPlaytimeForGame(game, progress);

    return Container(
      height: 176,
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(AppColors.radiusSmall),
        border: Border.all(color: AppColors.borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (coverUrl != null)
                  Image.network(
                    ImageUtils.getOptimizedUrl(
                      coverUrl,
                      width: 300,
                      height: 300,
                    ),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _coverPlaceholder(),
                  )
                else
                  _coverPlaceholder(),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _statusBadge(
                    _tileStatus(game),
                    _tileStatusColor(game),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        playtime == null ? '-' : _formatPlaytime(playtime),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Text(
                      _achievementTileLabel(progress),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      color: _panelRaised,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.textMuted,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildBottomPanels() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 860;
        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildEpicProgressPanel(),
              const SizedBox(height: 16),
              _buildDataQueuePanel(),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildEpicProgressPanel()),
            const SizedBox(width: 16),
            Expanded(child: _buildDataQueuePanel()),
          ],
        );
      },
    );
  }

  Widget _buildEpicProgressPanel() {
    final proof = _progressProof;
    final totalOfficial = _totalOfficialPlaytime;
    final unlockedAchievements = _unlockedAchievementTotal;
    final statusColor = _proofColor(proof);

    return _panelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: _epicBlue, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Epic Progress',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _isRefreshingProgress
                    ? null
                    : () => _loadProgressSnapshot(forceRefresh: true),
                child: Text(
                  _isRefreshingProgress ? 'Refreshing' : 'Force Refresh',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _smallDataBox(
                  label: 'Total playtime synced',
                  value: totalOfficial == null
                      ? '-'
                      : _formatPlaytime(totalOfficial),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _smallDataBox(
                  label: 'Achievements earned',
                  value: unlockedAchievements == null
                      ? '-'
                      : unlockedAchievements.toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            proof == null
                ? 'Last overall refresh: not checked'
                : 'Last overall refresh: ${_formatCheckedAt(proof.checkedAt)}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          _progressStatusBox(proof, statusColor),
        ],
      ),
    );
  }

  Widget _smallDataBox({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _panelRaised,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressStatusBox(EpicProgressProofResult? proof, Color color) {
    final title = proof?.title ?? 'Checking official progress';
    final message =
        proof?.message ??
        'EGData is checking Epic playtime access and user progress support.';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            proof?.isAvailable == true
                ? Icons.check_circle_outline_rounded
                : Icons.warning_amber_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataQueuePanel() {
    return _panelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storage_rounded, color: _epicBlue, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Sync Center',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: widget.onOpenSyncCenter,
                child: const Text('Open'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _queueRow(
            icon: Icons.description_outlined,
            label: 'Manifests indexed',
            value: '${widget.installedGames.length}',
            color: AppColors.textSecondary,
          ),
          _queueRow(
            icon: Icons.cloud_done_outlined,
            label: 'Contributions uploaded',
            value: '$_uploadCount',
            color: AppColors.success,
          ),
          _queueRow(
            icon: Icons.build_outlined,
            label: 'Repair suggested',
            value: '$_missingManifestCount',
            color: _missingManifestCount > 0
                ? AppColors.warning
                : AppColors.success,
          ),
          _queueRow(
            icon: Icons.sell_outlined,
            label: 'Missing metadata',
            value: '$_missingMetadataCount',
            color: _missingMetadataCount > 0
                ? AppColors.warning
                : AppColors.success,
          ),
          const SizedBox(height: 10),
          const Divider(color: AppColors.border),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: _epicBlue,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Background worker active',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                'Scan: ${_scanTimestamp()}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _queueRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _panelRaised,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyPanel({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(AppColors.radiusSmall),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  GameInfo? _heroGame() {
    if (_activeSession != null) {
      for (final game in widget.installedGames) {
        if (game.catalogItemId == _activeSession!.gameId ||
            game.displayName == _activeSession!.gameName) {
          return game;
        }
      }
    }

    final mostPlayed = _playtimeStats?.mostPlayedGame;
    if (mostPlayed != null) {
      for (final game in widget.installedGames) {
        if (game.catalogItemId == mostPlayed.gameId ||
            game.displayName == mostPlayed.gameName) {
          return game;
        }
      }
    }

    if (widget.installedGames.isEmpty) return null;
    return widget.installedGames.first;
  }

  String? _heroImage(GameInfo? game) {
    if (_activeSession?.thumbnailUrl != null) {
      return _activeSession!.thumbnailUrl;
    }
    if (game == null) return null;
    return game.metadata?.dieselGameBox ??
        game.metadata?.firstImageUrl ??
        game.metadata?.dieselGameBoxTall;
  }

  String? _coverImage(GameInfo game) {
    return game.metadata?.dieselGameBoxTall ??
        game.metadata?.dieselGameBox ??
        game.metadata?.firstImageUrl;
  }

  String _heroSubtitle(GameInfo? game) {
    if (_activeSession != null) {
      return 'Session running for ${_formatPlaytime(_activeSession!.duration)}';
    }
    if (game == null) {
      return 'Scan installed games to build your launcher home.';
    }
    return 'Last played: ${_lastPlayedLabel(game)}';
  }

  String _lastPlayedLabel(GameInfo game) {
    final local = _playtimeStats?.playtimeByGame[game.catalogItemId];
    if (local != null && local > Duration.zero) return 'this week';
    return 'installed locally';
  }

  EpicGameProgress? _progressForGame(GameInfo? game) {
    if (game == null || game.catalogItemId.trim().isEmpty) return null;
    return _progressByCatalogItemId[game.catalogItemId];
  }

  Duration? _bestPlaytimeForGame(GameInfo? game, EpicGameProgress? progress) {
    if (progress?.officialPlaytime != null) return progress!.officialPlaytime;
    if (game == null) return null;
    return _playtimeStats?.playtimeByGame[game.catalogItemId];
  }

  List<GameInfo> _recentGamesForShelf() {
    final games = widget.installedGames.toList(growable: false);
    if (_playtimeStats == null || _playtimeStats!.playtimeByGame.isEmpty) {
      return games.take(5).toList(growable: false);
    }

    final sorted = games.toList()
      ..sort((a, b) {
        final bTime =
            _playtimeStats!.playtimeByGame[b.catalogItemId] ?? Duration.zero;
        final aTime =
            _playtimeStats!.playtimeByGame[a.catalogItemId] ?? Duration.zero;
        return bTime.compareTo(aTime);
      });
    return sorted.take(5).toList(growable: false);
  }

  String _installLocationLabel(GameInfo? game) {
    if (game == null || game.installLocation.trim().isEmpty) return '-';
    final location = game.installLocation.trim();
    if (location.length <= 34) return location;
    return '...${location.substring(location.length - 31)}';
  }

  String _tileStatus(GameInfo game) {
    if (game.metadata == null) return 'Metadata';
    if (game.manifestLocation == null || game.manifestLocation!.isEmpty) {
      return 'Manifest';
    }
    return 'Installed';
  }

  Color _tileStatusColor(GameInfo game) {
    if (game.metadata == null) return AppColors.warning;
    if (game.manifestLocation == null || game.manifestLocation!.isEmpty) {
      return AppColors.warning;
    }
    return AppColors.success;
  }

  String _achievementTileLabel(EpicGameProgress? progress) {
    final fraction = _achievementFraction(progress?.achievementPercent);
    if (fraction == null) return '-';
    return '${(fraction * 100).round()}%';
  }

  double? _achievementFraction(double? value) {
    if (value == null) return null;
    if (value > 1) return (value / 100).clamp(0.0, 1.0);
    return value.clamp(0.0, 1.0);
  }

  int get _missingMetadataCount =>
      widget.installedGames.where((game) => game.metadata == null).length;

  int get _missingManifestCount => widget.installedGames
      .where(
        (game) =>
            game.manifestLocation == null || game.manifestLocation!.isEmpty,
      )
      .length;

  Duration? get _totalOfficialPlaytime {
    var total = Duration.zero;
    var hasValue = false;
    for (final progress in _progressByCatalogItemId.values) {
      final playtime = progress.officialPlaytime;
      if (playtime == null) continue;
      total += playtime;
      hasValue = true;
    }
    return hasValue ? total : null;
  }

  int? get _unlockedAchievementTotal {
    var total = 0;
    var hasValue = false;
    for (final progress in _progressByCatalogItemId.values) {
      final unlocked = progress.unlockedAchievements;
      if (unlocked == null) continue;
      total += unlocked;
      hasValue = true;
    }
    return hasValue ? total : null;
  }

  String _topSyncLabel() {
    final proof = _progressProof;
    if (_isRefreshingProgress) return 'Syncing progress';
    if (proof == null) return 'Progress not checked';
    if (proof.isAvailable) return 'Progress synced';
    if (proof.needsLogin) return 'Login needed';
    return 'Progress blocked';
  }

  Color _proofColor(EpicProgressProofResult? proof) {
    if (proof == null) return AppColors.textMuted;
    if (proof.isAvailable) return AppColors.success;
    if (proof.needsLogin) return AppColors.warning;
    return AppColors.error;
  }

  Future<void> _launchGame(GameInfo game) async {
    if (game.appName.trim().isEmpty) return;
    final launched = await EpicProtocol.launch(
      EpicProtocol.launchApp(
        game.appName,
        namespace: game.catalogNamespace.trim().isEmpty
            ? null
            : game.catalogNamespace.trim(),
        itemId: game.catalogItemId.trim().isEmpty
            ? null
            : game.catalogItemId.trim(),
      ),
    );
    if (!mounted || launched) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not launch ${game.displayName}.'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  String _formatPlaytime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String _formatCheckedAt(DateTime checkedAt) {
    final now = DateTime.now();
    final hh = checkedAt.hour.toString().padLeft(2, '0');
    final mm = checkedAt.minute.toString().padLeft(2, '0');
    if (checkedAt.year == now.year &&
        checkedAt.month == now.month &&
        checkedAt.day == now.day) {
      return 'Today, $hh:$mm';
    }
    return '${checkedAt.month}/${checkedAt.day}, $hh:$mm';
  }

  String _scanTimestamp() {
    final now = DateTime.now();
    return 'Today, ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}
