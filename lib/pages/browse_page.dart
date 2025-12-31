import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';
import '../database/database_service.dart';
import '../models/followed_game.dart';
import '../services/follow_service.dart';
import '../services/search_service.dart';
import '../widgets/game_card.dart';

class BrowsePage extends StatefulWidget {
  final FollowService followService;
  final DatabaseService db;

  const BrowsePage({
    super.key,
    required this.followService,
    required this.db,
  });

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  final TextEditingController _searchController = TextEditingController();
  final SearchService _searchService = SearchService();
  final FocusNode _searchFocus = FocusNode();

  List<SearchResult> _searchResults = [];
  List<FollowedGame> _followedGames = [];
  bool _isSearching = false;
  bool _isLoading = true;
  Timer? _debounce;
  StreamSubscription? _followedSub;

  @override
  void initState() {
    super.initState();
    _loadFollowedGames();
    _followedSub = widget.followService.followedGamesStream.listen((games) {
      setState(() => _followedGames = games);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _searchService.dispose();
    _debounce?.cancel();
    _followedSub?.cancel();
    super.dispose();
  }

  Future<void> _loadFollowedGames() async {
    setState(() => _isLoading = true);
    await widget.followService.loadFollowedGames();
    setState(() {
      _followedGames = widget.followService.followedGames;
      _isLoading = false;
    });
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _isSearching = true);
      final results = await _searchService.searchOffers(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _isSearching = false;
    });
    _searchFocus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final showSearchResults = _searchController.text.isNotEmpty;

    return Column(
      children: [
        // Header with search
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.explore_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Browse',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Search and follow games',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Search bar
              TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                onChanged: _onSearchChanged,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: 'Search for games...',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  prefixIcon: _isSearching
                      ? Container(
                          width: 20,
                          height: 20,
                          padding: const EdgeInsets.all(12),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(Icons.search_rounded,
                          color: AppColors.textMuted),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: AppColors.textMuted),
                          onPressed: _clearSearch,
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : showSearchResults
                  ? _buildSearchResults()
                  : _buildFollowedGames(),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty && !_isSearching) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: AppColors.textMuted.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'No games found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return GameCard(
          offerId: result.id,
          title: result.title,
          namespace: result.namespace,
          thumbnailUrl: result.thumbnailUrl,
          originalPrice: result.originalPrice,
          discountPrice: result.discountPrice,
          followService: widget.followService,
        );
      },
    );
  }

  Widget _buildFollowedGames() {
    if (_followedGames.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_outline_rounded,
              size: 64,
              color: AppColors.textMuted.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'No followed games',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Search for games to follow',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.accentPink,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Following',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accentPink.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_followedGames.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentPink,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _followedGames.length,
            itemBuilder: (context, index) {
              final game = _followedGames[index];
              return GameCard(
                offerId: game.offerId,
                title: game.title,
                namespace: game.namespace,
                thumbnailUrl: game.thumbnailUrl,
                // FollowedGame UI model doesn't have price info
                // Price info is stored in FollowedGameEntry in the database
                followService: widget.followService,
              );
            },
          ),
        ),
      ],
    );
  }
}
