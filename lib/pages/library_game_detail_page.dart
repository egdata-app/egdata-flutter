import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../database/database_service.dart';
import '../main.dart';
import '../models/followed_game.dart';
import '../models/game_info.dart';
import '../models/library_game.dart';
import '../models/upload_status.dart';
import '../services/api_service.dart';
import '../services/follow_service.dart';
import '../services/playtime_service.dart';
import '../utils/image_utils.dart';
import '../utils/system_requirements.dart';
import '../widgets/follow_button.dart';
import '../widgets/offer_changelog_card.dart';
import '../widgets/screenshot_carousel.dart';

/// Full-page, store-style detail view for a single library entry.
///
/// Renders rich offer data (description, screenshots, features, system
/// requirements, achievements, changelog, related) when an offer is linked,
/// and falls back to cached library metadata otherwise. Library-specific
/// actions (Play / Install / Move / Sync manifest) live in a sticky action
/// bar at the top.
class LibraryGameDetailPage extends StatefulWidget {
  final LibraryGame game;
  final FollowService followService;
  final PlaytimeService? playtimeService;
  final void Function(LibraryGame) onLaunch;
  final void Function(LibraryGame) onInstall;
  final void Function(GameInfo) onMove;
  final void Function(LibraryGame) onSyncManifest;
  final VoidCallback onBack;

  const LibraryGameDetailPage({
    super.key,
    required this.game,
    required this.followService,
    required this.onLaunch,
    required this.onInstall,
    required this.onMove,
    required this.onSyncManifest,
    required this.onBack,
    this.playtimeService,
  });

  @override
  State<LibraryGameDetailPage> createState() => _LibraryGameDetailPageState();
}

class _LibraryGameDetailPageState extends State<LibraryGameDetailPage> {
  final ApiService _apiService = ApiService();

  Offer? _offer;
  OfferFeatures? _features;
  List<AchievementSet>? _achievements;
  OfferHltb? _hltb;
  OfferMedia? _media;
  List<Offer>? _relatedOffers;
  ChangelogResponse? _changelog;

  bool _loadingOffer = true;
  bool _loadingDetails = false;
  bool _hasOffer = false;

  Duration _totalPlaytime = Duration.zero;
  DateTime? _lastPlayedAt;

  bool _isFollowing = false;
  bool _followBusy = false;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.game.catalogItemId.isNotEmpty &&
        widget.followService.isFollowing(widget.game.catalogItemId);
    _loadPlaytime();
    _loadOffer();
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  Future<void> _loadPlaytime() async {
    final playtimeService = widget.playtimeService;
    if (playtimeService == null) return;
    final catalogItemId = widget.game.catalogItemId;
    if (catalogItemId.isEmpty) return;

    final results = await Future.wait([
      playtimeService.getTotalPlaytime(catalogItemId),
      playtimeService.getRecentSessions(limit: 50),
    ]);
    if (!mounted) return;
    final total = results[0] as Duration;
    final sessions = results[1] as List<PlaytimeSessionEntry>;
    DateTime? lastPlayed;
    for (final session in sessions) {
      if (session.gameId == catalogItemId) {
        lastPlayed = session.startTime;
        break;
      }
    }
    setState(() {
      _totalPlaytime = total;
      _lastPlayedAt = lastPlayed;
    });
  }

  Future<void> _loadOffer() async {
    final cachedOfferId = widget.game.metadata?.offerId;
    Offer? offer;
    try {
      if (cachedOfferId != null && cachedOfferId.isNotEmpty) {
        offer = await _apiService.getOffer(cachedOfferId);
      } else if (widget.game.catalogItemId.isNotEmpty) {
        offer = await _apiService.getItemOffer(widget.game.catalogItemId);
      }
    } catch (_) {
      offer = null;
    }

    if (!mounted) return;
    if (offer == null) {
      setState(() {
        _loadingOffer = false;
        _hasOffer = false;
      });
      return;
    }

    setState(() {
      _offer = offer;
      _hasOffer = true;
      _loadingOffer = false;
      _loadingDetails = true;
    });

    final offerId = offer.id;
    final results = await Future.wait([
      _apiService
          .getOfferFeatures(offerId)
          .catchError(
            (_) => OfferFeatures(launcher: '', features: [], epicFeatures: []),
          ),
      _apiService
          .getOfferAchievements(offerId)
          .catchError((_) => <AchievementSet>[]),
      _apiService.getOfferHltb(offerId).catchError((_) => null),
      _apiService.getOfferMedia(offerId).catchError((_) => null),
      _apiService.getOfferRelated(offerId).catchError((_) => <Offer>[]),
      _apiService
          .getOfferChangelog(offerId, page: 1, limit: 5)
          .catchError(
            (_) => ChangelogResponse(
              elements: [],
              page: 1,
              limit: 5,
              totalCount: 0,
              totalPages: 0,
              hasNextPage: false,
              hasPreviousPage: false,
            ),
          ),
    ]);

    if (!mounted) return;
    setState(() {
      _features = results[0] as OfferFeatures;
      _achievements = results[1] as List<AchievementSet>;
      _hltb = results[2] as OfferHltb?;
      _media = results[3] as OfferMedia?;
      _relatedOffers = results[4] as List<Offer>;
      _changelog = results[5] as ChangelogResponse;
      _loadingDetails = false;
    });
  }

  Future<void> _toggleFollow() async {
    if (_followBusy || widget.game.catalogItemId.isEmpty) return;
    setState(() => _followBusy = true);
    try {
      final id = widget.game.catalogItemId;
      if (_isFollowing) {
        await widget.followService.unfollowGame(id);
      } else {
        // FollowService stores by catalogItemId on desktop (matches existing
        // _toggleFollowLibraryGame in library_page.dart).
        await widget.followService.followGame(
          FollowedGame(
            offerId: id,
            title: widget.game.title,
            namespace: widget.game.namespace,
            thumbnailUrl: widget.game.boxArtUrl ?? widget.game.wideImageUrl,
            followedAt: DateTime.now(),
          ),
        );
      }
      if (mounted) {
        setState(() => _isFollowing = !_isFollowing);
      }
    } finally {
      if (mounted) setState(() => _followBusy = false);
    }
  }

  Future<void> _openOnEgdata() async {
    final id = _offer?.id ?? widget.game.metadata?.offerId;
    if (id == null || id.isEmpty) return;
    final url = Uri.parse('https://egdata.app/offers/$id');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openInstallFolder() async {
    final path = widget.game.installLocation;
    if (path.isEmpty) return;
    final uri = Uri.file(path);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String? _heroImageUrl() {
    final offer = _offer;
    if (offer != null) {
      const wideTypes = [
        'DieselStoreFrontWide',
        'OfferImageWide',
        'DieselGameBoxWide',
        'Featured',
      ];
      for (final type in wideTypes) {
        final img =
            offer.keyImages.where((i) => i.type == type).firstOrNull;
        if (img != null && img.url.isNotEmpty) return img.url;
      }
      if (offer.keyImages.isNotEmpty) return offer.keyImages.first.url;
    }
    final cached = widget.game.metadata?.keyImages;
    if (cached != null) {
      for (final type in const [
        'DieselStoreFrontWide',
        'OfferImageWide',
        'DieselGameBoxWide',
        'Featured',
      ]) {
        final url = cached[type];
        if (url != null && url.isNotEmpty) return url;
      }
    }
    return widget.game.wideImageUrl ?? widget.game.boxArtUrl;
  }

  String? _boxImageUrl() {
    final offer = _offer;
    if (offer != null) {
      const types = ['DieselGameBoxTall', 'OfferImageTall', 'Thumbnail'];
      for (final type in types) {
        final img =
            offer.keyImages.where((i) => i.type == type).firstOrNull;
        if (img != null && img.url.isNotEmpty) return img.url;
      }
    }
    return widget.game.boxArtUrl ?? widget.game.wideImageUrl;
  }

  @override
  Widget build(BuildContext context) {
    // Use a single SingleChildScrollView + Column instead of CustomScrollView +
    // SliverList: with a heterogeneous, mostly-async-loaded section list the
    // sliver layout keeps refining its total extent as children get measured,
    // which makes the scrollbar and overall height jitter while scrolling.
    // A plain Column lays everything out up front for stable scroll bounds.
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildHeaderBar(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHero(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _buildSections(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppColors.textPrimary,
            onPressed: widget.onBack,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              widget.game.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_offer != null || widget.game.metadata?.offerId != null)
            IconButton(
              tooltip: 'Open on egdata.app',
              icon: Image.asset(
                'assets/logo.png',
                width: 18,
                height: 18,
                filterQuality: FilterQuality.medium,
              ),
              onPressed: _openOnEgdata,
            ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildHero() {
    final heroUrl = _heroImageUrl();
    final boxUrl = _boxImageUrl();
    return Stack(
      children: [
        SizedBox(
          height: 360,
          width: double.infinity,
          child: heroUrl != null
              ? Image.network(
                  ImageUtils.getOptimizedUrl(
                    heroUrl,
                    width: 1600,
                    height: 720,
                  ),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      Container(color: AppColors.surfaceLight),
                )
              : Container(color: AppColors.surfaceLight),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppColors.background.withValues(alpha: 0.4),
                  AppColors.background,
                ],
                stops: const [0, 0.6, 1],
              ),
            ),
          ),
        ),
        Positioned(
          left: 28,
          right: 28,
          bottom: 24,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (boxUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    width: 140,
                    height: 187,
                    child: Image.network(
                      ImageUtils.getOptimizedUrl(
                        boxUrl,
                        width: 280,
                        height: 374,
                      ),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          Container(color: AppColors.surfaceLight),
                    ),
                  ),
                ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.game.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _heroPill(
                          widget.game.isInstalled
                              ? 'Installed'
                              : 'Not installed',
                          widget.game.isInstalled
                              ? AppColors.success
                              : AppColors.textMuted,
                        ),
                        if ((_offer?.offerType ?? widget.game.offerType) != null)
                          _heroPill(
                            _formatOfferType(
                              _offer?.offerType ?? widget.game.offerType!,
                            ),
                            AppColors.primary,
                          ),
                        if ((_offer?.developerDisplayName ??
                                widget.game.developerDisplayName) !=
                            null)
                          Text(
                            _offer?.developerDisplayName ??
                                widget.game.developerDisplayName!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _heroPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  List<Widget> _buildSections() {
    final children = <Widget>[
      _buildActionBar(),
      const SizedBox(height: 24),
      _buildStatsStrip(),
      const SizedBox(height: 24),
    ];

    if (_loadingOffer) {
      children.add(_loadingPlaceholder('Loading store details…'));
    } else if (!_hasOffer) {
      children.add(_noOfferNotice());
    } else {
      final offer = _offer!;

      if (offer.description.isNotEmpty || offer.longDescription != null) {
        children.add(
          _section(
            'About',
            Text(
              offer.longDescription?.trim().isNotEmpty == true
                  ? offer.longDescription!
                  : offer.description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ),
        );
        children.add(const SizedBox(height: 24));
      }

      if (_loadingDetails) {
        children.add(_loadingPlaceholder('Loading screenshots…'));
        children.add(const SizedBox(height: 24));
      } else if (_media != null && _media!.images.isNotEmpty) {
        children.add(_section('Screenshots', _buildScreenshots()));
        children.add(const SizedBox(height: 24));
      }

      if (_features != null &&
          (_features!.features.isNotEmpty ||
              _features!.epicFeatures.isNotEmpty)) {
        children.add(_section('Features', _buildFeatures()));
        children.add(const SizedBox(height: 24));
      }

      final requirements = SystemRequirements.parse(offer.customAttributes);
      if (requirements.isNotEmpty) {
        children.add(
          _section('System Requirements', _buildRequirements(requirements)),
        );
        children.add(const SizedBox(height: 24));
      }

      if (offer.tags.isNotEmpty) {
        children.add(_section('Genres', _buildTags(offer.tags)));
        children.add(const SizedBox(height: 24));
      }

      if (_achievements != null && _achievements!.isNotEmpty) {
        children.add(
          _section('Achievements', _buildAchievementsCard(_achievements!)),
        );
        children.add(const SizedBox(height: 24));
      }

      if (_hltb != null && _hltb!.gameTimes.isNotEmpty) {
        children.add(_section('How Long To Beat', _buildHltb(_hltb!)));
        children.add(const SizedBox(height: 24));
      }

      if (_changelog != null && _changelog!.elements.isNotEmpty) {
        children.add(
          OfferChangelogCard(
            offerId: offer.id,
            preview: _changelog!.elements,
            totalCount: _changelog!.totalCount,
          ),
        );
        children.add(const SizedBox(height: 24));
      }

      if (_relatedOffers != null && _relatedOffers!.isNotEmpty) {
        children.add(_section('Related', _buildRelated(_relatedOffers!)));
        children.add(const SizedBox(height: 24));
      }

      children.add(_section('Details', _buildDetailsCard(offer)));
    }

    return children;
  }

  Widget _section(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildActionBar() {
    final game = widget.game;
    final installed = game.isInstalled;
    final canInstall = !installed && game.ownedGame != null;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (installed)
          _primaryButton(
            icon: Icons.play_arrow_rounded,
            label: 'Play',
            onPressed: () => widget.onLaunch(game),
          )
        else if (canInstall)
          _primaryButton(
            icon: Icons.download_rounded,
            label: 'Install',
            onPressed: () => widget.onInstall(game),
          ),
        _secondaryButton(
          icon: game.isInstalled
              ? Icons.cloud_upload_rounded
              : Icons.cloud_sync_rounded,
          label: game.isInstalled ? 'Upload manifest' : 'Sync manifest',
          onPressed:
              game.isUploadRunning ? null : () => widget.onSyncManifest(game),
        ),
        if (installed && game.installedGame != null)
          _secondaryButton(
            icon: Icons.drive_file_move_rounded,
            label: 'Move',
            onPressed: () => widget.onMove(game.installedGame!),
          ),
        if (game.catalogItemId.isNotEmpty)
          FollowButton(
            isFollowing: _isFollowing,
            isLoading: _followBusy,
            onToggle: _toggleFollow,
            compact: true,
          ),
        _statusPill(game),
      ],
    );
  }

  Widget _primaryButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 40,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.background,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _secondaryButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 40,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: onPressed == null
              ? AppColors.textMuted
              : AppColors.textPrimary,
          side: BorderSide(
            color: onPressed == null
                ? AppColors.border
                : AppColors.borderLight,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _statusPill(LibraryGame game) {
    final color = _statusColor(game);
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        game.statusLabel,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
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
    return switch (status) {
      UploadStatusType.uploaded || UploadStatusType.alreadyUploaded =>
        AppColors.success,
      UploadStatusType.failed => AppColors.error,
      UploadStatusType.pending => AppColors.textMuted,
      UploadStatusType.uploading => AppColors.warning,
    };
  }

  Widget _buildStatsStrip() {
    final game = widget.game;
    final stats = <_StatTile>[];

    if (widget.playtimeService != null) {
      stats.add(
        _StatTile(
          icon: Icons.timer_rounded,
          label: 'Playtime',
          value: _formatPlaytime(_totalPlaytime),
        ),
      );
    }
    if (_lastPlayedAt != null) {
      stats.add(
        _StatTile(
          icon: Icons.history_rounded,
          label: 'Last played',
          value: _formatRelativeDate(_lastPlayedAt!),
        ),
      );
    }
    if (game.isInstalled && game.installedGame != null) {
      final installed = game.installedGame!;
      stats.add(
        _StatTile(
          icon: Icons.sd_storage_rounded,
          label: 'Install size',
          value: installed.formattedSize,
        ),
      );
    }
    if (game.versionLabel.isNotEmpty) {
      stats.add(
        _StatTile(
          icon: Icons.update_rounded,
          label: 'Version',
          value: game.versionLabel,
        ),
      );
    }
    if (game.releaseDate != null) {
      stats.add(
        _StatTile(
          icon: Icons.event_rounded,
          label: 'Released',
          value: DateFormat.yMMMd().format(game.releaseDate!),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (stats.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final tileWidth = maxWidth >= 720
                  ? (maxWidth - 16 * 3) / 4
                  : maxWidth >= 480
                  ? (maxWidth - 16) / 2
                  : maxWidth;
              return Wrap(
                spacing: 16,
                runSpacing: 12,
                children: stats
                    .map((s) => SizedBox(width: tileWidth, child: s))
                    .toList(),
              );
            },
          ),
        if (game.installLocation.isNotEmpty) ...[
          const SizedBox(height: 12),
          _installLocationRow(game.installLocation),
        ],
      ],
    );
  }

  Widget _installLocationRow(String path) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.folder_rounded,
            size: 16,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              path,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontFamily: 'JetBrainsMono',
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _openInstallFolder,
            icon: const Icon(Icons.open_in_new_rounded, size: 14),
            label: const Text('Open', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingPlaceholder(String label) {
    return Container(
      height: 88,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _noOfferNotice() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.textMuted, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No store listing is linked to this library item, so detailed '
              'metadata, screenshots, and achievements are unavailable.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenshots() {
    final images = _media!.images;
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final image = images[index];
          return GestureDetector(
            onTap: () => _openScreenshot(index),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 356,
                height: 200,
                child: CachedNetworkImage(
                  imageUrl: image.src,
                  fit: BoxFit.cover,
                  placeholder: (_, _) =>
                      Container(color: AppColors.surfaceLight),
                  errorWidget: (_, _, _) => Container(
                    color: AppColors.surfaceLight,
                    child: const Icon(
                      Icons.broken_image_rounded,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openScreenshot(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ScreenshotCarousel(
          images: _media!.images,
          initialIndex: index,
        ),
      ),
    );
  }

  Widget _buildFeatures() {
    final all = [..._features!.features, ..._features!.epicFeatures];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: all.map((feature) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _featureIcon(feature),
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                feature,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  IconData _featureIcon(String feature) {
    final lower = feature.toLowerCase();
    if (lower.contains('single')) return Icons.person_rounded;
    if (lower.contains('multi') ||
        lower.contains('coop') ||
        lower.contains('co-op')) {
      return Icons.people_rounded;
    }
    if (lower.contains('controller')) return Icons.gamepad_rounded;
    if (lower.contains('cloud')) return Icons.cloud_rounded;
    if (lower.contains('achievement')) return Icons.emoji_events_rounded;
    if (lower.contains('online')) return Icons.public_rounded;
    return Icons.check_circle_rounded;
  }

  Widget _buildRequirements(SystemRequirements reqs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final twoColumn = constraints.maxWidth >= 600 &&
              reqs.minimum.isNotEmpty &&
              reqs.recommended.isNotEmpty;
          if (twoColumn) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _requirementsColumn('Minimum', reqs.minimum)),
                const SizedBox(width: 24),
                Expanded(
                  child: _requirementsColumn('Recommended', reqs.recommended),
                ),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (reqs.minimum.isNotEmpty) ...[
                _requirementsColumn('Minimum', reqs.minimum),
                if (reqs.recommended.isNotEmpty) const SizedBox(height: 16),
              ],
              if (reqs.recommended.isNotEmpty)
                _requirementsColumn('Recommended', reqs.recommended),
            ],
          );
        },
      ),
    );
  }

  Widget _requirementsColumn(String heading, List<RequirementRow> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        ...rows.map(
          (r) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 96,
                  child: Text(
                    r.label,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    r.value,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTags(List<Tag> tags) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            tag.name,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAchievementsCard(List<AchievementSet> sets) {
    final achievements = sets.expand((s) => s.achievements).toList();
    final totalXp = achievements.fold<int>(0, (sum, a) => sum + a.xp);
    final preview = achievements.take(8).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.warning,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${achievements.length} Achievements',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$totalXp XP total',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: preview.map((a) {
              return SizedBox(
                width: 64,
                height: 64,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: a.unlockedIconLink.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: a.unlockedIconLink,
                          fit: BoxFit.cover,
                          placeholder: (_, _) =>
                              Container(color: AppColors.surfaceLight),
                          errorWidget: (_, _, _) => Container(
                            color: AppColors.surfaceLight,
                            child: const Icon(
                              Icons.emoji_events_rounded,
                              color: AppColors.warning,
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.surfaceLight,
                          child: const Icon(
                            Icons.emoji_events_rounded,
                            color: AppColors.warning,
                          ),
                        ),
                ),
              );
            }).toList(),
          ),
          if (achievements.length > preview.length) ...[
            const SizedBox(height: 10),
            Text(
              '+${achievements.length - preview.length} more',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHltb(OfferHltb hltb) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: hltb.gameTimes.map((time) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time.category,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                Text(
                  time.time,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRelated(List<Offer> offers) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: offers.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final offer = offers[index];
          final thumb =
              offer.keyImages
                  .where((i) => i.type == 'DieselGameBoxTall')
                  .firstOrNull
                  ?.url ??
              offer.keyImages
                  .where((i) => i.type == 'Thumbnail')
                  .firstOrNull
                  ?.url ??
              (offer.keyImages.isNotEmpty
                  ? offer.keyImages.first.url
                  : null);
          return SizedBox(
            width: 130,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    width: 130,
                    height: 120,
                    child: thumb != null
                        ? CachedNetworkImage(
                            imageUrl: thumb,
                            fit: BoxFit.cover,
                            placeholder: (_, _) =>
                                Container(color: AppColors.surfaceLight),
                            errorWidget: (_, _, _) =>
                                Container(color: AppColors.surfaceLight),
                          )
                        : Container(color: AppColors.surfaceLight),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  offer.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _formatOfferType(offer.offerType),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailsCard(Offer offer) {
    final rows = <Widget>[];
    void add(String label, String? value) {
      if (value == null || value.isEmpty) return;
      rows.add(_detailRow(label, value));
    }

    add('Developer', offer.developerDisplayName);
    add('Publisher', offer.publisherDisplayName);
    add('Seller', offer.seller?.name);
    if (offer.releaseDate != null) {
      add('Release date', DateFormat.yMMMd().format(offer.releaseDate!));
    }
    add('Type', _formatOfferType(offer.offerType));
    add('Namespace', offer.namespace);
    add('Catalog item', widget.game.catalogItemId);
    add('App name', widget.game.appName);
    if (offer.refundType != null && offer.refundType!.isNotEmpty) {
      add(
        'Refund policy',
        offer.refundType!.replaceAll('_', ' ').toLowerCase(),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: rows),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatOfferType(String type) {
    switch (type) {
      case 'BASE_GAME':
        return 'Base Game';
      case 'DLC':
        return 'DLC';
      case 'ADD_ON':
      case 'ADDON':
        return 'Add-On';
      case 'BUNDLE':
        return 'Bundle';
      case 'EDITION':
        return 'Edition';
      case 'DEMO':
        return 'Demo';
      case 'CONSUMABLE':
        return 'Consumable';
      default:
        return type.replaceAll('_', ' ');
    }
  }

  String _formatPlaytime(Duration duration) {
    if (duration.inMinutes < 1) return 'Never played';
    final hours = duration.inMinutes / 60;
    if (hours < 1) return '${duration.inMinutes} min';
    if (hours < 10) return '${hours.toStringAsFixed(1)} hrs';
    return '${hours.toStringAsFixed(0)} hrs';
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat.yMMMd().format(date);
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
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
            ),
          ),
        ],
      ),
    );
  }
}
