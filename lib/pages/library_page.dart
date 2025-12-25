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
      await widget.followService.followGame(FollowedGame(
        offerId: offerId,
        title: game.displayName,
        namespace: game.catalogNamespace,
        thumbnailUrl: metadata?.dieselGameBoxTall ?? metadata?.firstImageUrl,
        followedAt: DateTime.now(),
      ));
      widget.addLog('Following ${game.displayName}');
    }
    setState(() {});
  }

  void _moveGame(GameInfo game) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => MoveGamePage(game: game),
      ),
    );

    if (result == true) {
      widget.addLog('Game moved: ${game.displayName}');
      widget.onScanGames();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredGames = _filteredGames;

    return Container(
      color: AppColors.background,
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Library',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manage your installed games',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${widget.games.length} games',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
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
            onPressed: widget.onToggleConsole,
            tooltip: widget.showConsole ? 'Hide console' : 'Show console',
            isActive: widget.showConsole,
          ),
          const SizedBox(width: 8),
          // Refresh button
          _buildIconButton(
            icon: Icons.refresh_rounded,
            onPressed: widget.isLoading ? () {} : widget.onScanGames,
            tooltip: 'Rescan games',
          ),
          const SizedBox(width: 12),
          // Upload button
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

  Widget _buildUploadButton() {
    final isDisabled = widget.isUploadingAll || widget.games.isEmpty;

    return Material(
      color: isDisabled ? AppColors.surfaceLight : AppColors.primary,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: isDisabled ? null : widget.onUploadAll,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isUploadingAll)
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
                widget.isUploadingAll ? 'UPLOADING...' : 'UPLOAD ALL',
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
    if (widget.isLoading) {
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

    if (widget.games.isEmpty) {
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
              widget.manifestPath,
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'JetBrainsMono',
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: widget.onScanGames,
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
      separatorBuilder: (_, __) => const SizedBox(height: 2),
      itemBuilder: (context, index) {
        final game = games[index];
        return GameTile(
          game: game,
          uploadStatus: widget.uploadStatuses[game.installationGuid],
          isUploading: widget.uploadingGames.contains(game.installationGuid),
          onUpload: () => widget.onUploadManifest(game),
          onMove: () => _moveGame(game),
          isFollowing: widget.followService.isFollowing(game.catalogItemId),
          onFollowToggle: () => _toggleFollow(game),
        );
      },
    );
  }
}
