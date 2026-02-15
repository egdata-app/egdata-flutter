import 'package:flutter/material.dart';
import '../main.dart';
import '../models/followed_game.dart';
import '../models/game_info.dart';
import '../models/upload_status.dart';
import '../services/follow_service.dart';
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
  final String manifestPath;
  final VoidCallback onScanGames;
  final Function(GameInfo) onUploadManifest;
  final VoidCallback onUploadAll;
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
    required this.manifestPath,
    required this.onScanGames,
    required this.onUploadManifest,
    required this.onUploadAll,
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

  List<GameInfo> get _filteredGames {
    if (_searchQuery.isEmpty) return widget.games;
    final query = _searchQuery.toLowerCase();
    return widget.games.where((game) {
      return game.displayName.toLowerCase().contains(query) ||
          game.appName.toLowerCase().contains(query) ||
          game.installLocation.toLowerCase().contains(query);
    }).toList();
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
      widget.onScanGames();
    }
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

  void _showRelatedAddons(GameInfo game, List<GameInfo> addons) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            '${game.displayName} Add-ons',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          content: SizedBox(
            width: 520,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: addons.length,
                separatorBuilder: (_, index) =>
                    const Divider(color: AppColors.border),
                itemBuilder: (_, index) {
                  final addon = addons[index];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      addon.displayName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '${addon.formattedSize} • ${addon.version}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.extension_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  );
                },
              ),
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

  @override
  Widget build(BuildContext context) {
    final filteredGames = _filteredGames;

    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          _buildHeader(),
          _buildToolbar(filteredGames.length),
          Expanded(child: _buildGameList(filteredGames)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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

  Widget _buildToolbar(int gameCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
      child: Row(
        children: [
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
            onPressed: widget.isLoading ? () {} : widget.onScanGames,
            tooltip: 'Rescan games',
          ),
          const SizedBox(width: 12),
          _buildUploadButton(),
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
        onTap: isDisabled ? null : widget.onUploadAll,
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

    if (widget.games.isEmpty) {
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
              onPressed: widget.onScanGames,
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
          uploadStatus: widget.uploadStatuses[game.installationGuid],
          isUploading: widget.uploadingGames.contains(game.installationGuid),
          onUpload: () => widget.onUploadManifest(game),
          onMove: () => _moveGame(game),
          isFollowing: widget.followService.isFollowing(game.catalogItemId),
          onFollowToggle: () => _toggleFollow(game),
          onTap: relatedAddons.isEmpty
              ? null
              : () => _showRelatedAddons(game, relatedAddons),
        );
      },
    );
  }
}
