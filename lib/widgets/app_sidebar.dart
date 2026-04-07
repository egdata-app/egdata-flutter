import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../services/sync_queue_service.dart';
import '../models/upload_status.dart';
import '../shell_controller.dart';

enum AppPage {
  dashboard,
  library,
  playtime,
  browse, // Mobile only: browse/search games
  chat, // Mobile only: AI chat assistant
  freeGames, // Mobile only: free games list
  settings,
}

class AppSidebar extends StatefulWidget {
  final AppPage currentPage;
  final ValueChanged<AppPage> onPageSelected;
  final String? latestVersion;
  final String currentVersion;
  final SyncQueueService? syncQueueService;
  final ShellController? shellController;

  const AppSidebar({
    super.key,
    required this.currentPage,
    required this.onPageSelected,
    this.latestVersion,
    this.currentVersion = '',
    this.syncQueueService,
    this.shellController,
  });

  bool get hasUpdate =>
      latestVersion != null &&
      currentVersion.isNotEmpty &&
      latestVersion != currentVersion;

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  AppPage? _hoveredPage;
  final GlobalKey _syncProgressKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    widget.syncQueueService?.addListener(_onQueueChanged);
  }

  @override
  void didUpdateWidget(covariant AppSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.syncQueueService != widget.syncQueueService) {
      oldWidget.syncQueueService?.removeListener(_onQueueChanged);
      widget.syncQueueService?.addListener(_onQueueChanged);
    }
  }

  @override
  void dispose() {
    widget.syncQueueService?.removeListener(_onQueueChanged);
    super.dispose();
  }

  void _onQueueChanged() {
    if (mounted) setState(() {});
  }

  void _toggleSyncPopup() {
    final controller = widget.shellController;
    if (controller == null) return;

    if (controller.syncPopupVisible) {
      controller.hideSyncPopup();
      return;
    }

    final box =
        _syncProgressKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;

    controller.showSyncPopup(
      Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: AppColors.surfaceGlass,
        border: Border(
          right: BorderSide(color: AppColors.borderGlass, width: 1),
        ),
      ),
      child: Column(
        children: [
          _buildLogo(),
          const SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  _buildNavItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    page: AppPage.dashboard,
                  ),
                  const SizedBox(height: 4),
                  _buildNavItem(
                    icon: Icons.games_rounded,
                    label: 'Library',
                    page: AppPage.library,
                  ),
                  const SizedBox(height: 4),
                  _buildNavItem(
                    icon: Icons.timer_rounded,
                    label: 'Playtime',
                    page: AppPage.playtime,
                  ),
                  const Spacer(),
                  if (widget.hasUpdate) ...[
                    _buildUpdateButton(),
                    const SizedBox(height: 12),
                  ],
                  Container(height: 1, color: AppColors.border),
                  const SizedBox(height: 12),
                  if (_isSyncRunning()) ...[
                    _buildSyncProgress(),
                    const SizedBox(height: 12),
                  ],
                  _buildNavItem(
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    page: AppPage.settings,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Row(
        children: [
          Image.asset(
            'assets/logo.png',
            width: 36,
            height: 36,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.storage_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EGDATA',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Client',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required AppPage page,
  }) {
    final isActive = widget.currentPage == page;
    final isHovered = _hoveredPage == page;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredPage = page),
      onExit: (_) => setState(() => _hoveredPage = null),
      child: GestureDetector(
        onTap: () => widget.onPageSelected(page),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppColors.radiusSmall),
            border: Border.all(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.25)
                  : isHovered
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive
                    ? AppColors.primary
                    : isHovered
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? AppColors.primary
                      : isHovered
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isSyncRunning() {
    final q = widget.syncQueueService;
    return q != null && q.isRunning;
  }

  Widget _buildSyncProgress() {
    final q = widget.syncQueueService!;
    final progress = q.total > 0 ? q.completed / q.total : 0.0;
    final pct = (progress * 100).toInt();

    return GestureDetector(
      key: _syncProgressKey,
      onTap: _toggleSyncPopup,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppColors.radiusSmall),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                  value: progress > 0 ? progress : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$pct% · ${q.completed}/${q.total}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_right,
                size: 16,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          final url = Uri.parse(
            'https://github.com/egdata-app/egdata-flutter/releases/latest',
          );
          if (await canLaunchUrl(url)) {
            await launchUrl(url);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.success.withValues(alpha: 0.15),
                AppColors.success.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppColors.radiusSmall),
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.system_update_rounded,
                  size: 16,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Update Available',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                    Text(
                      'v${widget.latestVersion}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.success.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new_rounded,
                size: 14,
                color: AppColors.success.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SyncPopup extends StatefulWidget {
  final Rect anchorRect;
  final SyncQueueService queueService;
  final VoidCallback onClose;

  const SyncPopup({
    super.key,
    required this.anchorRect,
    required this.queueService,
    required this.onClose,
  });

  @override
  State<SyncPopup> createState() => SyncPopupState();
}

class SyncPopupState extends State<SyncPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  final _popupKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
    widget.queueService.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.queueService.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.queueService;
    final progress = q.total > 0 ? q.completed / q.total : 0.0;
    final pct = (progress * 100).toInt();
    final pending = q.total - q.completed;
    final uploaded = q.queue
        .where((e) => e.status == UploadStatusType.uploaded)
        .length;
    final already = q.queue
        .where((e) => e.status == UploadStatusType.alreadyUploaded)
        .length;
    final failed = q.queue
        .where((e) => e.status == UploadStatusType.failed)
        .length;

    const popupWidth = 360.0;
    const popupMaxHeight = 440.0;
    final left = widget.anchorRect.right + 13.25;

    final screenSize = MediaQuery.sizeOf(context);
    final anchorBottom = screenSize.height - widget.anchorRect.bottom;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onClose,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
        ),
        Positioned(
          left: left,
          bottom:
              anchorBottom, // Align bottom edge with the button's bottom edge
          child: Material(
            color: Colors.transparent,
            child: FadeTransition(
              opacity: _animation,
              child: SizeTransition(
                sizeFactor: _animation,
                axis: Axis.horizontal,
                axisAlignment: -1.0,
                child: Container(
                  key: _popupKey,
                  width: popupWidth,
                  constraints: const BoxConstraints(maxHeight: popupMaxHeight),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(AppColors.radiusLarge),
                    ),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border(
                            bottom: BorderSide(color: AppColors.border),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.cloud_sync,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Cloud Sync',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: q.cancel,
                              icon: const Icon(Icons.close_rounded, size: 16),
                              label: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                minimumSize: const Size(0, 36),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                        child: Row(
                          children: [
                            Text(
                              '$pct%',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: LinearProgressIndicator(
                                      value: progress > 0 ? progress : null,
                                      backgroundColor: AppColors.surfaceLight,
                                      color: AppColors.primary,
                                      minHeight: 6,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _statBadge(
                                        '${q.completed}/${q.total}',
                                        AppColors.textSecondary,
                                      ),
                                      if (pending > 0) ...[
                                        const SizedBox(width: 6),
                                        _statBadge(
                                          '$pending pending',
                                          AppColors.textMuted,
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            if (uploaded > 0)
                              _statChip(
                                '✅ $uploaded uploaded',
                                AppColors.success,
                              ),
                            if (already > 0) ...[
                              const SizedBox(width: 6),
                              _statChip(
                                'ℹ️ $already exists',
                                AppColors.textMuted,
                              ),
                            ],
                            if (failed > 0) ...[
                              const SizedBox(width: 6),
                              _statChip('❌ $failed failed', AppColors.error),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(height: 1, color: AppColors.border),
                      Flexible(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            shrinkWrap: true,
                            itemCount: q.logs.length,
                            itemBuilder: (context, index) => Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Text(
                                q.logs[index],
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  fontFamily: 'JetBrainsMono',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statBadge(String text, Color color) {
    return Text(
      text,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color),
    );
  }

  Widget _statChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
          height: 1,
        ),
      ),
    );
  }
}
