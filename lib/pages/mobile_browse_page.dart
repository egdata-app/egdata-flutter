import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../main.dart';
import '../models/followed_game.dart';
import '../models/settings.dart';
import '../services/api_service.dart';
import '../services/follow_service.dart';
import '../widgets/game_card.dart';
import 'mobile_offer_detail_page.dart';

class MobileBrowsePage extends StatefulWidget {
  final AppSettings settings;
  final FollowService followService;

  const MobileBrowsePage({
    super.key,
    required this.settings,
    required this.followService,
  });

  @override
  State<MobileBrowsePage> createState() => _MobileBrowsePageState();
}

class _MobileBrowsePageState extends State<MobileBrowsePage>
    with AutomaticKeepAliveClientMixin {
  static const String _logTag = 'MobileBrowsePage';

  @override
  bool get wantKeepAlive => true;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  // Search state
  List<Offer> _searchResults = [];
  bool _isSearching = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  int _totalResults = 0;
  Timer? _debounce;
  String? _lastError;

  // Filter state
  SearchOfferType? _offerType;
  SearchSortBy _sortBy = SearchSortBy.lastModifiedDate;
  SearchSortDir _sortDir = SearchSortDir.desc;
  bool? _onSale;
  PriceRange? _priceRange;
  bool _excludeBlockchain = false;
  bool _pastGiveaways = false;
  bool _isLowestPrice = false;
  List<String>? _tags;

  // Filter counts from aggregations
  SearchAggregations? _aggregations;

  void _log(String message, {Object? error}) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 23);
    final logMessage = '[$timestamp] $_logTag: $message';
    developer.log(logMessage, name: 'EGData', error: error);
    debugPrint(logMessage);
    if (error != null) {
      debugPrint('  Error: $error');
    }
  }

  @override
  void initState() {
    super.initState();
    _log('initState - country: ${widget.settings.country}');
    _scrollController.addListener(_onScroll);
    // Perform initial search with default filters
    _performSearch(resetPage: true);
  }

  @override
  void didUpdateWidget(covariant MobileBrowsePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-fetch search results if country changed
    if (oldWidget.settings.country != widget.settings.country) {
      _log(
        'didUpdateWidget - country changed from ${oldWidget.settings.country} to ${widget.settings.country}',
      );
      _performSearch(resetPage: true);
    }
  }

  @override
  void dispose() {
    _log('dispose');
    _searchController.dispose();
    _searchFocus.dispose();
    _apiService.dispose();
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _log('onScroll - loading more (page ${_currentPage + 1})');
      _loadMore();
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _log('onSearchChanged - query: "$query" (debouncing)');
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _performSearch(resetPage: true);
    });
  }

  Future<void> _performSearch({bool resetPage = false}) async {
    final query = _searchController.text;

    if (resetPage) {
      _log('performSearch - starting new search for "$query"');
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _isSearching = true;
        _lastError = null;
      });
    } else {
      _log('performSearch - loading page $_currentPage for "$query"');
    }

    try {
      final request = SearchRequest(
        title: query.isNotEmpty ? query : null,
        offerType: _offerType,
        sortBy: _sortBy,
        sortDir: _sortDir,
        onSale: _onSale,
        price: _priceRange,
        excludeBlockchain: _excludeBlockchain ? true : null,
        pastGiveaways: _pastGiveaways ? true : null,
        isLowestPrice: _isLowestPrice ? true : null,
        tags: _tags,
        limit: 20,
        page: _currentPage,
      );

      _log('performSearch - request: ${_formatRequest(request)}');

      final stopwatch = Stopwatch()..start();
      final response = await _apiService.search(
        request,
        country: widget.settings.country,
      );
      stopwatch.stop();

      _log(
        'performSearch - response: ${response.total} total, '
        'page ${response.page}, ${response.offers.length} offers, '
        '${stopwatch.elapsedMilliseconds}ms'
        '${response.meta?.cached == true ? ' (cached)' : ''}',
      );

      if (mounted) {
        setState(() {
          if (resetPage) {
            _searchResults = response.offers;
          } else {
            _searchResults.addAll(response.offers);
          }
          _totalResults = response.total;
          _hasMore = _searchResults.length < response.total;
          _isSearching = false;
          _isLoadingMore = false;
          _aggregations = response.aggregations;
        });
      }
    } catch (e) {
      _log('performSearch - error', error: e);
      if (mounted) {
        setState(() {
          _isSearching = false;
          _isLoadingMore = false;
          _lastError = e.toString();
        });
      }
    }
  }

  String _formatRequest(SearchRequest request) {
    final parts = <String>[];
    if (request.title != null) parts.add('title="${request.title}"');
    if (request.offerType != null)
      parts.add('type=${request.offerType!.value}');
    if (request.sortBy != null) parts.add('sort=${request.sortBy!.value}');
    if (request.sortDir != null) parts.add('dir=${request.sortDir!.value}');
    if (request.onSale == true) parts.add('onSale');
    if (request.excludeBlockchain == true) parts.add('noBlockchain');
    if (request.pastGiveaways == true) parts.add('pastGiveaways');
    if (request.isLowestPrice == true) parts.add('lowestPrice');
    if (request.price != null) {
      parts.add(
        'price=${request.price!.min ?? 0}-${request.price!.max ?? '∞'}',
      );
    }
    parts.add('page=${request.page}');
    parts.add('limit=${request.limit}');
    return parts.join(', ');
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    await _performSearch(resetPage: false);
  }

  void _clearSearch() {
    _log('clearSearch');
    _searchController.clear();
    _searchFocus.unfocus();
    _performSearch(resetPage: true);
  }

  void _showFiltersBottomSheet() {
    _log(
      'showFiltersBottomSheet - current filters: '
      'type=$_offerType, sort=$_sortBy/$_sortDir, '
      'onSale=$_onSale, excludeBlockchain=$_excludeBlockchain',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FiltersBottomSheet(
        offerType: _offerType,
        sortBy: _sortBy,
        sortDir: _sortDir,
        onSale: _onSale,
        priceRange: _priceRange,
        excludeBlockchain: _excludeBlockchain,
        pastGiveaways: _pastGiveaways,
        isLowestPrice: _isLowestPrice,
        aggregations: _aggregations,
        onApply:
            (
              offerType,
              sortBy,
              sortDir,
              onSale,
              priceRange,
              excludeBlockchain,
              pastGiveaways,
              isLowestPrice,
            ) {
              _log(
                'filtersApplied - type=$offerType, sort=$sortBy/$sortDir, '
                'onSale=$onSale, price=$priceRange, '
                'noBlockchain=$excludeBlockchain, pastGiveaways=$pastGiveaways, '
                'lowestPrice=$isLowestPrice',
              );

              setState(() {
                _offerType = offerType;
                _sortBy = sortBy;
                _sortDir = sortDir;
                _onSale = onSale;
                _priceRange = priceRange;
                _excludeBlockchain = excludeBlockchain;
                _pastGiveaways = pastGiveaways;
                _isLowestPrice = isLowestPrice;
              });
              // Always trigger new search with updated filters
              _performSearch(resetPage: true);
            },
      ),
    );
  }

  int get _activeFilterCount {
    int count = 0;
    if (_offerType != null) count++;
    if (_onSale == true) count++;
    if (_priceRange != null) count++;
    if (_pastGiveaways) count++;
    if (_isLowestPrice) count++;
    if (_excludeBlockchain) count++;
    if (_sortBy != SearchSortBy.lastModifiedDate ||
        _sortDir != SearchSortDir.desc)
      count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Column(
      children: [
        // Header with search
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
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
                          'Search and discover games',
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
                      : const Icon(
                          Icons.search_rounded,
                          color: AppColors.textMuted,
                        ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.textMuted,
                          ),
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
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Filters button row
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _showFiltersBottomSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _activeFilterCount > 0
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _activeFilterCount > 0
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              size: 18,
                              color: _activeFilterCount > 0
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Filters & Sorting',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _activeFilterCount > 0
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                            if (_activeFilterCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$_activeFilterCount',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.background,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Results count
        if (_totalResults > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                Text(
                  '${_totalResults == 10000 ? '+' : ''}$_totalResults results',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

        // Error message
        if (_lastError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _lastError!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Content
        Expanded(child: _buildSearchResults()),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching && _searchResults.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_searchResults.isEmpty) {
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
              'Try a different search term or adjust filters',
              style: TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: _searchResults.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _searchResults.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            ),
          );
        }

        final offer = _searchResults[index];
        final isFollowing = widget.followService.isFollowing(offer.id);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _SwipeableGameCard(
            offer: offer,
            isFollowing: isFollowing,
            thumbnailUrl: _getThumbnailUrl(offer),
            onSwipeComplete: () => _toggleFollow(offer, isFollowing),
            onTap: () => _navigateToOffer(offer),
          ),
        );
      },
    );
  }

  void _navigateToOffer(Offer offer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MobileOfferDetailPage(
          offerId: offer.id,
          followService: widget.followService,
          initialTitle: offer.title,
          initialImageUrl: _getThumbnailUrl(offer),
        ),
      ),
    );
  }

  Future<void> _toggleFollow(Offer offer, bool wasFollowing) async {
    final followedGame = FollowedGame(
      offerId: offer.id,
      title: offer.title,
      namespace: offer.namespace,
      thumbnailUrl: _getThumbnailUrl(offer),
      followedAt: DateTime.now(),
    );

    if (wasFollowing) {
      await widget.followService.unfollowGame(offer.id);
      _log('unfollowed: ${offer.title}');
    } else {
      await widget.followService.followGame(followedGame);
      _log('followed: ${offer.title}');
    }

    if (mounted) {
      setState(() {}); // Refresh to update follow status

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                wasFollowing
                    ? Icons.favorite_border_rounded
                    : Icons.favorite_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  wasFollowing
                      ? 'Removed from followed games'
                      : 'Added to followed games',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          action: SnackBarAction(
            label: 'Undo',
            textColor: AppColors.primary,
            onPressed: () async {
              // Reverse the action
              if (wasFollowing) {
                await widget.followService.followGame(followedGame);
              } else {
                await widget.followService.unfollowGame(offer.id);
              }
              if (mounted) setState(() {});
            },
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String? _getThumbnailUrl(Offer offer) {
    if (offer.keyImages.isEmpty) return null;

    // Prefer Thumbnail, then DieselGameBoxTall, then any image
    final thumbnail = offer.keyImages
        .where((img) => img.type == 'Thumbnail')
        .firstOrNull;
    if (thumbnail != null) return thumbnail.url;

    final boxTall = offer.keyImages
        .where((img) => img.type == 'DieselGameBoxTall')
        .firstOrNull;
    if (boxTall != null) return boxTall.url;

    return offer.keyImages.first.url;
  }
}

// Filters bottom sheet widget
class _FiltersBottomSheet extends StatefulWidget {
  final SearchOfferType? offerType;
  final SearchSortBy sortBy;
  final SearchSortDir sortDir;
  final bool? onSale;
  final PriceRange? priceRange;
  final bool excludeBlockchain;
  final bool pastGiveaways;
  final bool isLowestPrice;
  final SearchAggregations? aggregations;
  final void Function(
    SearchOfferType? offerType,
    SearchSortBy sortBy,
    SearchSortDir sortDir,
    bool? onSale,
    PriceRange? priceRange,
    bool excludeBlockchain,
    bool pastGiveaways,
    bool isLowestPrice,
  )
  onApply;

  const _FiltersBottomSheet({
    required this.offerType,
    required this.sortBy,
    required this.sortDir,
    required this.onSale,
    required this.priceRange,
    required this.excludeBlockchain,
    required this.pastGiveaways,
    required this.isLowestPrice,
    required this.aggregations,
    required this.onApply,
  });

  @override
  State<_FiltersBottomSheet> createState() => _FiltersBottomSheetState();
}

class _FiltersBottomSheetState extends State<_FiltersBottomSheet> {
  late SearchOfferType? _offerType;
  late SearchSortBy _sortBy;
  late SearchSortDir _sortDir;
  late bool? _onSale;
  late PriceRange? _priceRange;
  late bool _excludeBlockchain;
  late bool _pastGiveaways;
  late bool _isLowestPrice;

  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  // Common offer types shown first
  static const _commonOfferTypes = [
    SearchOfferType.baseGame,
    SearchOfferType.dlc,
    SearchOfferType.addon,
    SearchOfferType.bundle,
    SearchOfferType.edition,
    SearchOfferType.demo,
  ];

  // Additional offer types in expandable section
  static const _additionalOfferTypes = [
    SearchOfferType.subscription,
    SearchOfferType.season,
    SearchOfferType.pass,
    SearchOfferType.inGameItem,
    SearchOfferType.inGameCurrency,
    SearchOfferType.lootbox,
    SearchOfferType.subscriptionBundle,
    SearchOfferType.experience,
    SearchOfferType.digitalExtra,
    SearchOfferType.consumable,
  ];

  // Common sort options shown first
  static const _commonSortOptions = [
    SearchSortBy.releaseDate,
    SearchSortBy.title,
    SearchSortBy.price,
    SearchSortBy.lastModifiedDate,
    SearchSortBy.upcoming,
  ];

  // Additional sort options
  static const _additionalSortOptions = [
    SearchSortBy.discount,
    SearchSortBy.discountPercent,
    SearchSortBy.giveawayDate,
    SearchSortBy.pcReleaseDate,
    SearchSortBy.effectiveDate,
    SearchSortBy.creationDate,
    SearchSortBy.viewableDate,
  ];

  bool _showMoreTypes = false;
  bool _showMoreSorts = false;

  @override
  void initState() {
    super.initState();
    _offerType = widget.offerType;
    _sortBy = widget.sortBy;
    _sortDir = widget.sortDir;
    _onSale = widget.onSale;
    _priceRange = widget.priceRange;
    _excludeBlockchain = widget.excludeBlockchain;
    _pastGiveaways = widget.pastGiveaways;
    _isLowestPrice = widget.isLowestPrice;

    if (_priceRange?.min != null) {
      _minPriceController.text = (_priceRange!.min! / 100).toString();
    }
    if (_priceRange?.max != null) {
      _maxPriceController.text = (_priceRange!.max! / 100).toString();
    }
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _offerType = null;
      _sortBy = SearchSortBy.lastModifiedDate;
      _sortDir = SearchSortDir.desc;
      _onSale = null;
      _priceRange = null;
      _excludeBlockchain = false;
      _pastGiveaways = false;
      _isLowestPrice = false;
      _minPriceController.clear();
      _maxPriceController.clear();
    });
  }

  void _applyFilters() {
    // Parse price range
    PriceRange? priceRange;
    final minPrice = double.tryParse(_minPriceController.text);
    final maxPrice = double.tryParse(_maxPriceController.text);
    if (minPrice != null || maxPrice != null) {
      priceRange = PriceRange(
        min: minPrice != null ? (minPrice * 100).round() : null,
        max: maxPrice != null ? (maxPrice * 100).round() : null,
      );
    }

    widget.onApply(
      _offerType,
      _sortBy,
      _sortDir,
      _onSale,
      priceRange,
      _excludeBlockchain,
      _pastGiveaways,
      _isLowestPrice,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Filters & Sorting',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _resetFilters,
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.border, height: 1),
          // Filters content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sort section
                  _buildSectionHeader('Sort By'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final sort in _commonSortOptions)
                        _buildSortChip(sort.displayName, sort),
                    ],
                  ),
                  if (_showMoreSorts) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final sort in _additionalSortOptions)
                          _buildSortChip(sort.displayName, sort),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _showMoreSorts = !_showMoreSorts),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _showMoreSorts ? 'Show less' : 'More options',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                        Icon(
                          _showMoreSorts
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Sort direction toggle
                  Row(
                    children: [
                      const Text(
                        'Order:',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildDirectionChip('Descending', SearchSortDir.desc),
                      const SizedBox(width: 8),
                      _buildDirectionChip('Ascending', SearchSortDir.asc),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Offer type section
                  _buildSectionHeader('Type'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildOfferTypeChip('All', null),
                      for (final type in _commonOfferTypes)
                        _buildOfferTypeChip(type.displayName, type),
                    ],
                  ),
                  if (_showMoreTypes) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final type in _additionalOfferTypes)
                          _buildOfferTypeChip(type.displayName, type),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _showMoreTypes = !_showMoreTypes),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _showMoreTypes ? 'Show less' : 'More types',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.accent,
                          ),
                        ),
                        Icon(
                          _showMoreTypes
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 16,
                          color: AppColors.accent,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Price filters
                  _buildSectionHeader('Price'),
                  const SizedBox(height: 12),
                  // On sale toggle
                  _buildToggleOption(
                    'On Sale Only',
                    Icons.local_offer_rounded,
                    _onSale == true,
                    (value) => setState(() => _onSale = value ? true : null),
                    AppColors.success,
                  ),
                  const SizedBox(height: 8),
                  _buildToggleOption(
                    'Lowest Price Ever',
                    Icons.trending_down_rounded,
                    _isLowestPrice,
                    (value) => setState(() => _isLowestPrice = value),
                    AppColors.warning,
                  ),
                  const SizedBox(height: 12),
                  // Price range inputs
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minPriceController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Min Price',
                            labelStyle: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                            prefixText: '\$',
                            prefixStyle: TextStyle(color: AppColors.textMuted),
                            filled: true,
                            fillColor: AppColors.surfaceLight,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _maxPriceController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Max Price',
                            labelStyle: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                            prefixText: '\$',
                            prefixStyle: TextStyle(color: AppColors.textMuted),
                            filled: true,
                            fillColor: AppColors.surfaceLight,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Other options
                  _buildSectionHeader('Other'),
                  const SizedBox(height: 12),
                  _buildToggleOption(
                    'Exclude Blockchain Games',
                    Icons.block_rounded,
                    _excludeBlockchain,
                    (value) => setState(() => _excludeBlockchain = value),
                    AppColors.textSecondary,
                  ),
                  const SizedBox(height: 8),
                  _buildToggleOption(
                    'Past Giveaways Only',
                    Icons.card_giftcard_rounded,
                    _pastGiveaways,
                    (value) => setState(() => _pastGiveaways = value),
                    AppColors.accent,
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          // Apply button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _applyFilters,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildSortChip(String label, SearchSortBy sortBy) {
    final isSelected = _sortBy == sortBy;
    return GestureDetector(
      onTap: () => setState(() => _sortBy = sortBy),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildDirectionChip(String label, SearchSortDir dir) {
    final isSelected = _sortDir == dir;
    return GestureDetector(
      onTap: () => setState(() => _sortDir = dir),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildOfferTypeChip(String label, SearchOfferType? type) {
    final isSelected = _offerType == type;
    return GestureDetector(
      onTap: () => setState(() => _offerType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.15)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? AppColors.accent : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildToggleOption(
    String label,
    IconData icon,
    bool value,
    Function(bool) onChanged,
    Color activeColor,
  ) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: value
              ? activeColor.withValues(alpha: 0.1)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: value ? activeColor : AppColors.border),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: value ? activeColor : AppColors.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: value ? activeColor : AppColors.textSecondary,
                ),
              ),
            ),
            Icon(
              value ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 22,
              color: value ? activeColor : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

// Custom swipeable card with limited drag distance
class _SwipeableGameCard extends StatefulWidget {
  final Offer offer;
  final bool isFollowing;
  final String? thumbnailUrl;
  final VoidCallback onSwipeComplete;
  final VoidCallback onTap;

  const _SwipeableGameCard({
    required this.offer,
    required this.isFollowing,
    required this.thumbnailUrl,
    required this.onSwipeComplete,
    required this.onTap,
  });

  @override
  State<_SwipeableGameCard> createState() => _SwipeableGameCardState();
}

class _SwipeableGameCardState extends State<_SwipeableGameCard>
    with SingleTickerProviderStateMixin {
  static const double _maxDragExtent = 300.0;
  static const double _triggerThreshold = 120.0;
  static const double _frictionFactor = 1.2; // Lower = more friction

  double _rawDragExtent = 0.0; // Actual finger movement
  double _animStartValue = 0.0; // Starting value for snap-back animation
  late AnimationController _animationController;

  // Apply friction curve - diminishing returns as you drag further
  double get _dragExtent {
    // During animation, interpolate from start value to 0
    final raw = _animationController.isAnimating
        ? _animStartValue * (1 - _animationController.value)
        : _rawDragExtent;
    if (raw <= 0) return 0;
    // Rubber band effect: movement decreases as drag increases
    return _maxDragExtent *
        (1 - 1 / (1 + raw * _frictionFactor / _maxDragExtent));
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animationController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    // Stop animation if user starts dragging again
    if (_animationController.isAnimating) {
      _animationController.stop();
      _rawDragExtent = _animStartValue * (1 - _animationController.value);
      _animStartValue = 0;
    }
    setState(() {
      // Only allow left swipe (negative delta)
      _rawDragExtent = (_rawDragExtent - details.delta.dx).clamp(0.0, 400.0);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragExtent >= _triggerThreshold) {
      widget.onSwipeComplete();
    }
    _animateBack();
  }

  void _animateBack() {
    _animStartValue = _rawDragExtent;
    _rawDragExtent = 0;
    _animationController.forward(from: 0).then((_) {
      if (mounted) {
        setState(() => _animStartValue = 0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_dragExtent / _maxDragExtent).clamp(0.0, 1.0);
    final accentColor = widget.isFollowing
        ? AppColors.error
        : AppColors.primary;

    return Stack(
      children: [
        // Background revealed on swipe
        Positioned.fill(
          child: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15 + (progress * 0.15)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Opacity(
              opacity: progress,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.isFollowing
                        ? Icons.favorite_border_rounded
                        : Icons.favorite_rounded,
                    color: accentColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.isFollowing ? 'Unfollow' : 'Follow',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Foreground card
        Transform.translate(
          offset: Offset(-_dragExtent, 0),
          child: GestureDetector(
            onHorizontalDragUpdate: _onHorizontalDragUpdate,
            onHorizontalDragEnd: _onHorizontalDragEnd,
            child: GameCard(
              offerId: widget.offer.id,
              title: widget.offer.title,
              namespace: widget.offer.namespace,
              thumbnailUrl: widget.thumbnailUrl,
              originalPrice: widget.offer.price?.totalPrice?.originalPrice,
              discountPrice: widget.offer.price?.totalPrice?.discountPrice,
              offerType: widget.offer.offerType,
              seller: widget.offer.seller?.name,
              currencyCode:
                  widget.offer.price?.totalPrice?.currencyCode ?? 'USD',
              onTap: widget.onTap,
            ),
          ),
        ),
      ],
    );
  }
}
