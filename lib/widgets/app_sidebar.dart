import 'package:flutter/material.dart';
import '../main.dart';

enum AppPage {
  dashboard,
  library,
  settings,
}

class AppSidebar extends StatefulWidget {
  final AppPage currentPage;
  final ValueChanged<AppPage> onPageSelected;

  const AppSidebar({
    super.key,
    required this.currentPage,
    required this.onPageSelected,
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  AppPage? _hoveredPage;

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
                  const Spacer(),
                  Container(
                    height: 1,
                    color: AppColors.border,
                  ),
                  const SizedBox(height: 12),
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
            errorBuilder: (_, __, ___) => Container(
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
}
