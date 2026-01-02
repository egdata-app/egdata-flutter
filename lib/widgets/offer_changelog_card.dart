import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluquery/fluquery.dart';
import '../main.dart';
import '../services/api_service.dart';

class OfferChangelogCard extends StatelessWidget {
  final String offerId;
  final List<ChangelogItem> preview;
  final int totalCount;

  const OfferChangelogCard({
    super.key,
    required this.offerId,
    required this.preview,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    if (preview.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => _showFullChangelog(context),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Changelog',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Preview changes
            ...preview.take(3).map((item) => _buildChangePreview(item)),

            // View all button
            if (totalCount > 3) ...[
              const SizedBox(height: 8),
              Text(
                'View all ($totalCount changes)',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primary.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChangePreview(ChangelogItem item) {
    // Show only the most significant change from this item
    final change = item.metadata.changes.isNotEmpty
        ? item.metadata.changes.first
        : null;

    if (change == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Change type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Color(change.changeTypeBgColor),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              change.changeTypeLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(change.changeTypeColor),
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Change details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${change.fieldLabel}: ',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextSpan(
                        text: change.changeText,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.formattedDate,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullChangelog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ChangelogBottomSheet(offerId: offerId),
    );
  }
}

class _ChangelogBottomSheet extends HookWidget {
  final String offerId;

  const _ChangelogBottomSheet({required this.offerId});

  @override
  Widget build(BuildContext context) {
    final apiService = useMemoized(() => ApiService());
    final scrollController = useScrollController();
    final searchController = useTextEditingController();

    final currentPage = useState<int>(1);
    final selectedField = useState<String?>(null);
    final selectedType = useState<String?>(null);
    final searchQuery = useState<String>('');

    // Debounced search query
    final debouncedSearch = useDebounced(searchQuery.value, const Duration(milliseconds: 500));

    // Build query key from all filter parameters
    final queryKey = useMemoized(
      () => [
        'changelog',
        offerId,
        currentPage.value,
        debouncedSearch,
        selectedField.value,
        selectedType.value,
      ],
      [offerId, currentPage.value, debouncedSearch, selectedField.value, selectedType.value],
    );

    // Changelog query
    final changelogQuery = useQuery<ChangelogResponse, Object>(
      queryKey: queryKey,
      queryFn: (_) => apiService.getOfferChangelog(
        offerId,
        page: currentPage.value,
        limit: 20,
        field: selectedField.value,
        type: selectedType.value,
        query: (debouncedSearch?.isEmpty ?? true) ? null : debouncedSearch,
      ),
      staleTime: StaleTime(const Duration(minutes: 5)),
    );

    // Filter and pagination helpers
    void applyFieldFilter(String? filter) {
      if (selectedField.value == filter) return;
      selectedField.value = filter;
      currentPage.value = 1;
    }

    void applyTypeFilter(String? type) {
      if (selectedType.value == type) return;
      selectedType.value = type;
      currentPage.value = 1;
    }

    void goToPage(int page) {
      final totalPages = changelogQuery.data?.totalPages ?? 1;
      if (page < 1 || page > totalPages || page == currentPage.value) return;

      currentPage.value = page;

      // Scroll to top
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    final items = changelogQuery.data?.elements ?? [];
    final totalPages = changelogQuery.data?.totalPages ?? 1;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Full Changelog',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                searchQuery.value = value;
              },
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: 12),

          // Filter dropdowns
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildTypeDropdown(selectedType, applyTypeFilter),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFieldDropdown(selectedField, applyFieldFilter),
                ),
              ],
            ),
          ),

          const Divider(height: 24, color: AppColors.border),

          // Changelog list
          Flexible(
            child: items.isEmpty && changelogQuery.isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : items.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Text(
                            'No changes found',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          return _buildChangelogItem(items[index]);
                        },
                      ),
          ),

          // Pagination controls
          if (!changelogQuery.isLoading && items.isNotEmpty && totalPages > 1) ...[
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Previous button
                  IconButton(
                    onPressed: currentPage.value > 1 ? () => goToPage(currentPage.value - 1) : null,
                    icon: const Icon(Icons.chevron_left),
                    color: currentPage.value > 1 ? AppColors.textPrimary : AppColors.textMuted,
                  ),

                  // Page indicator
                  Text(
                    'Page ${currentPage.value} of $totalPages',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  // Next button
                  IconButton(
                    onPressed: currentPage.value < totalPages ? () => goToPage(currentPage.value + 1) : null,
                    icon: const Icon(Icons.chevron_right),
                    color: currentPage.value < totalPages ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeDropdown(ValueNotifier<String?> selectedType, Function(String?) applyTypeFilter) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButton<String>(
        value: selectedType.value,
        hint: const Text(
          'All types',
          style: TextStyle(color: AppColors.textMuted, fontSize: 14),
        ),
        isExpanded: true,
        underline: const SizedBox.shrink(),
        dropdownColor: AppColors.surface,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        items: const [
          DropdownMenuItem(value: null, child: Text('All types')),
          DropdownMenuItem(value: 'insert', child: Text('Insert')),
          DropdownMenuItem(value: 'update', child: Text('Update')),
          DropdownMenuItem(value: 'delete', child: Text('Delete')),
        ],
        onChanged: applyTypeFilter,
      ),
    );
  }

  Widget _buildFieldDropdown(ValueNotifier<String?> selectedField, Function(String?) applyFieldFilter) {
    // Common fields based on the web version
    final fields = [
      null, // All fields
      'price',
      'title',
      'description',
      'lastModifiedDate',
      'effectiveDate',
      'keyImages',
      'tags',
      'categories',
      'status',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButton<String>(
        value: selectedField.value,
        hint: const Text(
          'All fields',
          style: TextStyle(color: AppColors.textMuted, fontSize: 14),
        ),
        isExpanded: true,
        underline: const SizedBox.shrink(),
        dropdownColor: AppColors.surface,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        items: fields.map((field) {
          final label = field == null
              ? 'All fields'
              : field.replaceAllMapped(
                  RegExp(r'([A-Z])'),
                  (match) => ' ${match.group(1)}',
                ).trim();
          final displayLabel = label.isEmpty
              ? field
              : label[0].toUpperCase() + label.substring(1);

          return DropdownMenuItem(
            value: field,
            child: Text(displayLabel ?? 'All fields'),
          );
        }).toList(),
        onChanged: applyFieldFilter,
      ),
    );
  }

  Widget _buildChangelogItem(ChangelogItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                item.formattedDate,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${item.relativeTime})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Changes
          ...item.metadata.changes.asMap().entries.map((entry) {
            final change = entry.value;
            final isLast = entry.key == item.metadata.changes.length - 1;

            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Change type badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(change.changeTypeBgColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      change.changeTypeLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(change.changeTypeColor),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${change.fieldLabel}: ',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          TextSpan(
                            text: change.changeText,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
