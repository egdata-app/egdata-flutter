import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../main.dart';
import '../models/api/offer_details.dart';

// Achievements bottom sheet with filters
enum AchievementSortBy { name, xp, tier }

enum AchievementFilter { all, visible, hidden }

enum AchievementTier { platinum, gold, silver, bronze }

extension AchievementTierExtension on AchievementTier {
  String get label {
    switch (this) {
      case AchievementTier.platinum:
        return 'Platinum';
      case AchievementTier.gold:
        return 'Gold';
      case AchievementTier.silver:
        return 'Silver';
      case AchievementTier.bronze:
        return 'Bronze';
    }
  }

  Color get color {
    switch (this) {
      case AchievementTier.platinum:
        return const Color(0xFFE5E4E2); // Platinum silver
      case AchievementTier.gold:
        return const Color(0xFFFFD700); // Gold
      case AchievementTier.silver:
        return const Color(0xFFC0C0C0); // Silver
      case AchievementTier.bronze:
        return const Color(0xFFCD7F32); // Bronze
    }
  }

  int get sortOrder {
    switch (this) {
      case AchievementTier.platinum:
        return 0;
      case AchievementTier.gold:
        return 1;
      case AchievementTier.silver:
        return 2;
      case AchievementTier.bronze:
        return 3;
    }
  }

  static AchievementTier fromXp(int xp) {
    if (xp >= 250) return AchievementTier.platinum;
    if (xp >= 100) return AchievementTier.gold;
    if (xp >= 50) return AchievementTier.silver;
    return AchievementTier.bronze;
  }
}

/// Achievements bottom sheet with search, filter, and sort capabilities
class AchievementsBottomSheet extends HookWidget {
  final List<Achievement> achievements;

  const AchievementsBottomSheet({
    super.key,
    required this.achievements,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // State management with hooks
    final sortBy = useState(AchievementSortBy.tier);
    final filter = useState(AchievementFilter.all);
    final searchQuery = useState('');
    final searchController = useTextEditingController();

    // Memoized total XP
    final totalXp = useMemoized(
      () => achievements.fold<int>(0, (sum, a) => sum + a.xp),
      [achievements],
    );

    // Memoized filtered and sorted achievements
    final filteredAchievements = useMemoized(() {
      var list = achievements.toList();

      // Apply filter
      if (filter.value == AchievementFilter.visible) {
        list = list.where((a) => !a.hidden).toList();
      } else if (filter.value == AchievementFilter.hidden) {
        list = list.where((a) => a.hidden).toList();
      }

      // Apply search
      if (searchQuery.value.isNotEmpty) {
        final query = searchQuery.value.toLowerCase();
        list = list
            .where(
              (a) =>
                  a.unlockedDisplayName.toLowerCase().contains(query) ||
                  a.unlockedDescription.toLowerCase().contains(query) ||
                  a.flavorText.toLowerCase().contains(query),
            )
            .toList();
      }

      // Apply sort
      switch (sortBy.value) {
        case AchievementSortBy.name:
          list.sort(
            (a, b) => a.unlockedDisplayName.compareTo(b.unlockedDisplayName),
          );
          break;
        case AchievementSortBy.xp:
          list.sort((a, b) => b.xp.compareTo(a.xp));
          break;
        case AchievementSortBy.tier:
          // Sort by tier (Platinum first), then by XP within tier
          list.sort((a, b) {
            final tierA = AchievementTierExtension.fromXp(a.xp);
            final tierB = AchievementTierExtension.fromXp(b.xp);
            final tierCompare = tierA.sortOrder.compareTo(tierB.sortOrder);
            if (tierCompare != 0) return tierCompare;
            return b.xp.compareTo(a.xp);
          });
          break;
      }

      return list;
    }, [achievements, sortBy.value, filter.value, searchQuery.value]);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: AppColors.warning,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Achievements',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${achievements.length} total • $totalXp XP',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              onChanged: (value) => searchQuery.value = value,
              decoration: InputDecoration(
                hintText: 'Search achievements...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                suffixIcon: searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted),
                        onPressed: () {
                          searchController.clear();
                          searchQuery.value = '';
                        },
                      )
                    : null,
              ),
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),
          // Filter and sort controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Filter dropdown
                Expanded(
                  child: _buildFilterDropdown(filter),
                ),
                const SizedBox(width: 12),
                // Sort dropdown
                Expanded(
                  child: _buildSortDropdown(sortBy),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${filteredAchievements.length} achievement${filteredAchievements.length == 1 ? '' : 's'}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Achievements list
          Expanded(
            child: filteredAchievements.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: bottomPadding + 16,
                    ),
                    itemCount: filteredAchievements.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final achievement = filteredAchievements[index];
                      return _buildAchievementCard(achievement);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(ValueNotifier<AchievementFilter> filter) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<AchievementFilter>(
        value: filter.value,
        onChanged: (value) => filter.value = value!,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textMuted),
        dropdownColor: AppColors.surface,
        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
        items: const [
          DropdownMenuItem(
            value: AchievementFilter.all,
            child: Text('All Achievements'),
          ),
          DropdownMenuItem(
            value: AchievementFilter.visible,
            child: Text('Visible Only'),
          ),
          DropdownMenuItem(
            value: AchievementFilter.hidden,
            child: Text('Hidden Only'),
          ),
        ],
      ),
    );
  }

  Widget _buildSortDropdown(ValueNotifier<AchievementSortBy> sortBy) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<AchievementSortBy>(
        value: sortBy.value,
        onChanged: (value) => sortBy.value = value!,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textMuted),
        dropdownColor: AppColors.surface,
        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
        items: const [
          DropdownMenuItem(
            value: AchievementSortBy.tier,
            child: Text('Sort by Tier'),
          ),
          DropdownMenuItem(
            value: AchievementSortBy.xp,
            child: Text('Sort by XP'),
          ),
          DropdownMenuItem(
            value: AchievementSortBy.name,
            child: Text('Sort by Name'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: AppColors.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No achievements found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    final tier = AchievementTierExtension.fromXp(achievement.xp);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: achievement.hidden
              ? AppColors.border
              : tier.color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trophy icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: tier.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.emoji_events_rounded,
              color: tier.color,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          // Achievement details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and hidden badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        achievement.unlockedDisplayName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                    ),
                    if (achievement.hidden) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.textMuted.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'HIDDEN',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                // Description
                Text(
                  achievement.unlockedDescription,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                // Flavor text
                if (achievement.flavorText.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    achievement.flavorText,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textMuted.withValues(alpha: 0.8),
                      height: 1.3,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                // XP and tier
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: tier.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tier.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: tier.color,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${achievement.xp} XP',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
