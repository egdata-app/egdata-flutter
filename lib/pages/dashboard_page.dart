import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../models/calendar_event.dart';
import '../models/settings.dart';
import '../services/calendar_service.dart';
import '../services/follow_service.dart';

class DashboardPage extends StatefulWidget {
  final AppSettings settings;
  final FollowService followService;
  final CalendarService calendarService;

  const DashboardPage({
    super.key,
    required this.settings,
    required this.followService,
    required this.calendarService,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<CalendarEvent> _allFreeGames = [];
  List<CalendarEvent> _sales = [];
  List<CalendarEvent> _releases = [];
  List<CalendarEvent> _followedUpdates = [];
  bool _isLoading = true;
  String? _error;
  final ScrollController _freeGamesScrollController = ScrollController();
  int _currentFreeGamePage = 0;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    _freeGamesScrollController.dispose();
    _platformPickerOverlay?.remove();
    _platformPickerOverlay = null;
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final events = await widget.calendarService.fetchAllEvents(
        followedGames: widget.followService.followedGames,
        forceRefresh: true,
      );

      final now = DateTime.now();

      // Combine current and upcoming free games, sorted by start date
      _allFreeGames = events
          .where((e) =>
              e.type == CalendarEventType.freeGame && !e.hasEnded)
          .toList()
        ..sort((a, b) {
          // Current games first, then upcoming
          final aIsActive = a.isActive;
          final bIsActive = b.isActive;
          if (aIsActive && !bIsActive) return -1;
          if (!aIsActive && bIsActive) return 1;
          return a.startDate.compareTo(b.startDate);
        });

      _sales = events
          .where((e) => e.type == CalendarEventType.sale)
          .take(8)
          .toList();

      _releases = events
          .where((e) =>
              e.type == CalendarEventType.release &&
              e.startDate.isAfter(now))
          .take(6)
          .toList();

      _followedUpdates = events
          .where((e) => e.type == CalendarEventType.followedUpdate)
          .take(5)
          .toList();

      _currentFreeGamePage = 0;
    } catch (e) {
      _error = 'Failed to load events';
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _error != null
                    ? _buildErrorState()
                    : _buildContent(),
          ),
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
          const Text(
            'Discover',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _isLoading ? null : _loadEvents,
            icon: const Icon(Icons.refresh_rounded),
            color: AppColors.textSecondary,
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: const TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _loadEvents,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_allFreeGames.isNotEmpty) ...[
            _buildFreeGamesCarousel(),
            const SizedBox(height: 32),
          ],
          if (_sales.isNotEmpty) ...[
            _buildSection(
              title: 'HOT DEALS',
              icon: Icons.local_fire_department_rounded,
              color: Colors.orange,
              child: _buildSalesGrid(),
            ),
            const SizedBox(height: 32),
          ],
          if (_releases.isNotEmpty) ...[
            _buildSection(
              title: 'COMING SOON',
              icon: Icons.rocket_launch_rounded,
              color: AppColors.primary,
              child: _buildReleasesGrid(),
            ),
            const SizedBox(height: 32),
          ],
          if (_followedUpdates.isNotEmpty) ...[
            _buildSection(
              title: 'WATCHLIST ACTIVITY',
              icon: Icons.favorite_rounded,
              color: AppColors.accent,
              child: _buildFollowedUpdates(),
            ),
          ],
          if (_allFreeGames.isEmpty &&
              _sales.isEmpty &&
              _releases.isEmpty)
            _buildEmptyState(),
        ],
      ),
    );
  }

  Widget _buildFreeGamesCarousel() {
    final hasCarousel = _allFreeGames.length > 3;
    final totalPages = hasCarousel ? (_allFreeGames.length / 2).ceil() : 1;

    // Find the first active game for countdown
    final activeGame = _allFreeGames.where((g) => g.isActive).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.card_giftcard_rounded,
                      size: 16, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'FREE GAMES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${_allFreeGames.length} available',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
            const Spacer(),
            if (activeGame?.endDate != null)
              _buildCountdown(activeGame!.endDate!),
            if (hasCarousel) ...[
              const SizedBox(width: 16),
              _buildCarouselControls(totalPages),
            ],
          ],
        ),
        const SizedBox(height: 16),
        // Carousel or grid
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = ((constraints.maxWidth - 16) / 2).clamp(200.0, 450.0);
            // Card height = 16:9 image + footer (padding 12*2 + title ~18 + gap 6 + badges ~24 + border 2)
            final cardHeight = (cardWidth * 9 / 16) + 74;

            if (!hasCarousel) {
              // Simple grid for 3 or fewer
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: _allFreeGames
                    .map((game) => SizedBox(
                          width: _allFreeGames.length == 1
                              ? constraints.maxWidth
                              : cardWidth,
                          child: _buildFreeGameCard(game),
                        ))
                    .toList(),
              );
            }

            // Carousel for more than 3
            return SizedBox(
              height: cardHeight,
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollUpdateNotification) {
                    final page = (_freeGamesScrollController.offset /
                            (cardWidth * 2 + 16))
                        .round()
                        .clamp(0, totalPages - 1);
                    if (page != _currentFreeGamePage) {
                      setState(() => _currentFreeGamePage = page);
                    }
                  }
                  return false;
                },
                child: ListView.separated(
                  controller: _freeGamesScrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: _allFreeGames.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) => SizedBox(
                    width: cardWidth,
                    child: _buildFreeGameCard(_allFreeGames[index]),
                  ),
                ),
              ),
            );
          },
        ),
        // Page indicators for carousel
        if (hasCarousel) ...[
          const SizedBox(height: 16),
          _buildPageIndicators(totalPages),
        ],
      ],
    );
  }

  Widget _buildCarouselControls(int totalPages) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCarouselButton(
          icon: Icons.chevron_left_rounded,
          onPressed: _currentFreeGamePage > 0
              ? () => _scrollToPage(_currentFreeGamePage - 1)
              : null,
        ),
        const SizedBox(width: 4),
        _buildCarouselButton(
          icon: Icons.chevron_right_rounded,
          onPressed: _currentFreeGamePage < totalPages - 1
              ? () => _scrollToPage(_currentFreeGamePage + 1)
              : null,
        ),
      ],
    );
  }

  Widget _buildCarouselButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Material(
      color: onPressed != null ? AppColors.surface : AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(
            icon,
            size: 18,
            color: onPressed != null
                ? AppColors.textSecondary
                : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicators(int totalPages) {
    final clampedPage = _currentFreeGamePage.clamp(0, totalPages - 1);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        final isActive = index == clampedPage;
        return GestureDetector(
          onTap: () => _scrollToPage(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }

  void _scrollToPage(int page) {
    if (!_freeGamesScrollController.hasClients) return;

    // Calculate width based on current viewport (must match LayoutBuilder calculation)
    final viewportWidth = _freeGamesScrollController.position.viewportDimension;
    final cardWidth = ((viewportWidth - 16) / 2).clamp(200.0, 450.0);
    final offset = page * (cardWidth * 2 + 16);

    _freeGamesScrollController.animateTo(
      offset.clamp(0.0, _freeGamesScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    setState(() => _currentFreeGamePage = page);
  }

  Widget _buildCountdown(DateTime endDate) {
    final remaining = endDate.difference(DateTime.now());
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;

    String timeText;
    if (days > 0) {
      timeText = '${days}d ${hours}h remaining';
    } else if (hours > 0) {
      timeText = '${hours}h ${remaining.inMinutes % 60}m remaining';
    } else {
      timeText = '${remaining.inMinutes}m remaining';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 14, color: AppColors.warning),
          const SizedBox(width: 6),
          Text(
            timeText,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.warning,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreeGameCard(CalendarEvent game) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapUp: (details) => _handleGameCardTap(game, details.globalPosition),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: AppColors.surfaceLight,
                  child: game.thumbnailUrl != null
                      ? Image.network(
                          game.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (game.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'FREE NOW',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _formatDate(game.startDate),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        if (game.hasPlatforms) ...[
                          const SizedBox(width: 6),
                          ...game.platforms.map((p) => Padding(
                                padding: const EdgeInsets.only(right: 3),
                                child: _buildPlatformBadge(p),
                              )),
                        ],
                        const Spacer(),
                        const Icon(
                          Icons.open_in_new_rounded,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSalesGrid() {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _sales.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) =>
            _buildCompactGameCard(_sales[index], showDiscount: true),
      ),
    );
  }

  Widget _buildReleasesGrid() {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _releases.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) =>
            _buildCompactGameCard(_releases[index], showDate: true),
      ),
    );
  }

  Widget _buildCompactGameCard(
    CalendarEvent game, {
    bool showDiscount = false,
    bool showDate = false,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _openInStore(game.offerId),
        child: Container(
          width: 130,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: AppColors.surfaceLight,
                      child: game.thumbnailUrl != null
                          ? Image.network(
                              game.thumbnailUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildPlaceholder(),
                            )
                          : _buildPlaceholder(),
                    ),
                    if (showDiscount && game.subtitle != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            game.subtitle!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
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
                      game.title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (showDate)
                          Expanded(
                            child: Text(
                              _formatDate(game.startDate),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        if (game.hasPlatforms)
                          ...game.platforms.map((p) => Padding(
                                padding: const EdgeInsets.only(left: 2),
                                child: _buildPlatformBadge(p),
                              )),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFollowedUpdates() {
    return Column(
      children: _followedUpdates
          .map((update) => _buildUpdateItem(update))
          .toList(),
    );
  }

  Widget _buildUpdateItem(CalendarEvent update) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(4),
            ),
            clipBehavior: Clip.antiAlias,
            child: update.thumbnailUrl != null
                ? Image.network(
                    update.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.games_rounded,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                  )
                : const Icon(
                    Icons.games_rounded,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  update.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  update.subtitle ?? 'Updated',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatRelativeDate(update.startDate),
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  Widget _buildPlaceholder() {
    return const Center(
      child: Icon(
        Icons.games_rounded,
        size: 32,
        color: AppColors.textMuted,
      ),
    );
  }

  Widget _buildPlatformBadge(String platform) {
    IconData icon;
    String label;
    Color color;

    switch (platform.toLowerCase()) {
      case 'android':
        icon = Icons.android_rounded;
        label = 'Android';
        color = const Color(0xFF3DDC84);
      case 'ios':
        icon = Icons.apple_rounded;
        label = 'iOS';
        color = AppColors.textSecondary;
      case 'windows':
        icon = Icons.desktop_windows_rounded;
        label = 'Windows';
        color = const Color(0xFF00A4EF);
      case 'mac':
      case 'macos':
        icon = Icons.laptop_mac_rounded;
        label = 'Mac';
        color = AppColors.textSecondary;
      default:
        icon = Icons.devices_rounded;
        label = platform;
        color = AppColors.textMuted;
    }

    return Tooltip(
      message: label,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.explore_rounded, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            const Text(
              'Nothing to show right now',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _loadEvents,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatRelativeDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inMinutes}m ago';
    }
  }

  void _handleGameCardTap(CalendarEvent game, Offset position) {
    final platformOffers = game.metadata?['platformOffers'] as List<dynamic>?;

    if (platformOffers != null && platformOffers.length > 1) {
      _showPlatformPicker(position, platformOffers);
    } else {
      _openInStore(game.offerId);
    }
  }

  OverlayEntry? _platformPickerOverlay;

  void _dismissPlatformPicker() {
    _platformPickerOverlay?.remove();
    _platformPickerOverlay = null;
  }

  void _showPlatformPicker(Offset position, List<dynamic> platformOffers) {
    _dismissPlatformPicker();

    final overlay = Overlay.of(context);
    final screenSize = MediaQuery.of(context).size;

    // Adjust position to keep popup on screen
    const popupWidth = 180.0;
    const itemHeight = 42.0;
    final popupHeight = platformOffers.length * itemHeight + 16;

    double left = position.dx - popupWidth / 2;
    double top = position.dy + 8;

    // Keep within screen bounds
    if (left < 8) left = 8;
    if (left + popupWidth > screenSize.width - 8) {
      left = screenSize.width - popupWidth - 8;
    }
    if (top + popupHeight > screenSize.height - 8) {
      top = position.dy - popupHeight - 8;
    }

    _platformPickerOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Dismiss on tap outside
          Positioned.fill(
            child: GestureDetector(
              onTap: _dismissPlatformPicker,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          // Popup
          Positioned(
            left: left,
            top: top,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              builder: (context, value, child) => Transform.scale(
                scale: 0.95 + (0.05 * value),
                alignment: Alignment.topCenter,
                child: Opacity(opacity: value, child: child),
              ),
              child: Container(
                width: popupWidth,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                        child: Text(
                          'Open on',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      ...platformOffers.map((offer) {
                        final platform = offer['platform'] as String? ?? 'epic';
                        final offerId = offer['offerId'] as String?;
                        return _buildPlatformOption(platform, offerId);
                      }),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_platformPickerOverlay!);
  }

  Widget _buildPlatformOption(String platform, String? offerId) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _dismissPlatformPicker();
          _openInStore(offerId);
        },
        hoverColor: AppColors.surfaceLight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              _getPlatformIcon(platform),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _getPlatformLabel(platform),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_outward_rounded,
                size: 14,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getPlatformIcon(String platform) {
    IconData icon;
    Color color;

    switch (platform.toLowerCase()) {
      case 'android':
        icon = Icons.android_rounded;
        color = const Color(0xFF3DDC84);
      case 'ios':
        icon = Icons.apple_rounded;
        color = AppColors.textSecondary;
      case 'epic':
        icon = Icons.games_rounded;
        color = AppColors.textSecondary;
      default:
        icon = Icons.devices_rounded;
        color = AppColors.textMuted;
    }

    return Icon(icon, size: 18, color: color);
  }

  String _getPlatformLabel(String platform) {
    switch (platform.toLowerCase()) {
      case 'android':
        return 'Android';
      case 'ios':
        return 'iOS';
      case 'epic':
        return 'Epic Games Store';
      default:
        return platform;
    }
  }

  Future<void> _openInStore(String? offerId) async {
    if (offerId == null) return;
    final url = Uri.parse('https://egdata.app/offers/$offerId?utm_source=egdata-client');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
