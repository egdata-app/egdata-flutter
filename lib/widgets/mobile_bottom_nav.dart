import 'package:flutter/material.dart';
import '../main.dart';
import 'app_sidebar.dart';

class MobileBottomNav extends StatelessWidget {
  final AppPage currentPage;
  final ValueChanged<AppPage> onPageSelected;

  const MobileBottomNav({
    super.key,
    required this.currentPage,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.borderGlass, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                page: AppPage.dashboard,
              ),
              _buildNavItem(
                icon: Icons.explore_rounded,
                label: 'Browse',
                page: AppPage.browse,
              ),
              _buildNavItem(
                icon: Icons.card_giftcard_rounded,
                label: 'Free Games',
                page: AppPage.freeGames,
              ),
              _buildNavItem(
                icon: Icons.settings_rounded,
                label: 'Settings',
                page: AppPage.settings,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required AppPage page,
  }) {
    final isActive = currentPage == page;

    return GestureDetector(
      onTap: () => onPageSelected(page),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
