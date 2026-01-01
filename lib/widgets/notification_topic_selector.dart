import 'package:flutter/material.dart';
import '../main.dart';
import '../models/notification_topics.dart';

/// Bottom sheet for selecting notification topics for a followed game
class NotificationTopicSelector extends StatefulWidget {
  final String offerId;
  final List<String> currentTopics;
  final Function(List<String> topics) onTopicsChanged;

  const NotificationTopicSelector({
    super.key,
    required this.offerId,
    required this.currentTopics,
    required this.onTopicsChanged,
  });

  @override
  State<NotificationTopicSelector> createState() => _NotificationTopicSelectorState();
}

class _NotificationTopicSelectorState extends State<NotificationTopicSelector> {
  late Set<String> _selectedTopics;

  @override
  void initState() {
    super.initState();
    _selectedTopics = Set.from(widget.currentTopics);
  }

  void _toggleTopic(OfferNotificationTopic topic) {
    setState(() {
      final topicString = topic.getTopicForOffer(widget.offerId);

      if (topic.key == '*') {
        // If "All" is selected, clear other specific topics and add wildcard
        _selectedTopics.clear();
        _selectedTopics.add(topicString);
      } else {
        // Remove "All" if selecting specific topic
        final allTopic = OfferNotificationTopic.all.getTopicForOffer(widget.offerId);
        _selectedTopics.remove(allTopic);

        // Toggle specific topic
        if (_selectedTopics.contains(topicString)) {
          _selectedTopics.remove(topicString);
        } else {
          _selectedTopics.add(topicString);
        }
      }
    });
  }

  void _save() {
    widget.onTopicsChanged(_selectedTopics.toList());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.notifications_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notification Topics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Choose what to be notified about',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            // Topic options
            ...OfferNotificationTopic.allTopics.map((topic) {
              final topicString = topic.getTopicForOffer(widget.offerId);
              final isSelected = _selectedTopics.contains(topicString);

              return ListTile(
                onTap: () => _toggleTopic(topic),
                leading: Icon(
                  topic.icon,
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                ),
                title: Text(
                  topic.label,
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                subtitle: Text(
                  topic.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                trailing: Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                ),
              );
            }),
            // Save button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
