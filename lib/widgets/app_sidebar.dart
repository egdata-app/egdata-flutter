import 'package:flutter/material.dart';
import '../main.dart';

enum AppPage {
  dashboard,
  discover,
  library,
  calendar,
  settings,
}

class AppSidebar extends StatelessWidget {
  final AppPage currentPage;
  final ValueChanged<AppPage> onPageSelected;

  const AppSidebar({
    super.key,
    required this.currentPage,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        children: [
          _buildLogo(),
          const SizedBox(height: 8),
          Expanded(
            child: Column(
              children: [
                _buildNavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  page: AppPage.dashboard,
                ),
                _buildNavItem(
                  icon: Icons.explore_rounded,
                  label: 'Discover',
                  page: AppPage.discover,
                ),
                _buildNavItem(
                  icon: Icons.games_rounded,
                  label: 'Library',
                  page: AppPage.library,
                ),
                _buildNavItem(
                  icon: Icons.calendar_month_rounded,
                  label: 'Calendar',
                  page: AppPage.calendar,
                ),
                const Spacer(),
                const Divider(color: AppColors.border, height: 1),
                _buildNavItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  page: AppPage.settings,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.all(20),
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
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.storage_rounded,
                color: Colors.white,
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
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Client',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
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
    final isActive = currentPage == page;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isActive
            ? AppColors.primary.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => onPageSelected(page),
          borderRadius: BorderRadius.circular(8),
          hoverColor: AppColors.surfaceLight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: isActive
                  ? Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color:
                        isActive ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
