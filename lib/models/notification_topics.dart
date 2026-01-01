import 'package:flutter/material.dart';

/// Notification topic types for offer updates
class OfferNotificationTopic {
  final String key;
  final String label;
  final String description;
  final IconData icon;

  const OfferNotificationTopic({
    required this.key,
    required this.label,
    required this.description,
    required this.icon,
  });

  /// Get FCM topic string for a specific offer
  /// FCM topics can only contain: [a-zA-Z0-9-_.~%]
  String getTopicForOffer(String offerId) {
    final sanitizedKey = key == '*' ? 'all' : key;
    return 'offers-$offerId-$sanitizedKey';
  }

  static const all = OfferNotificationTopic(
    key: '*',
    label: 'All Notifications',
    description: 'Receive all types of updates',
    icon: Icons.notifications_active_rounded,
  );

  static const price = OfferNotificationTopic(
    key: 'price',
    label: 'Price Changes',
    description: 'Get notified when the price changes',
    icon: Icons.attach_money_rounded,
  );

  static const metadata = OfferNotificationTopic(
    key: 'metadata',
    label: 'Metadata Updates',
    description: 'Game info and description changes',
    icon: Icons.info_rounded,
  );

  static const builds = OfferNotificationTopic(
    key: 'builds',
    label: 'Build Updates',
    description: 'New game builds and patches',
    icon: Icons.system_update_rounded,
  );

  static const List<OfferNotificationTopic> allTopics = [
    all,
    price,
    metadata,
    builds,
  ];

  /// Get topic object from key
  static OfferNotificationTopic fromKey(String key) {
    try {
      return allTopics.firstWhere((t) => t.key == key);
    } catch (e) {
      return all;
    }
  }

  /// Parse topic string to extract offer ID and key
  /// Example: "offers-abc123-price" -> {offerId: "abc123", key: "price"}
  static Map<String, String>? parseTopicString(String topic) {
    final regex = RegExp(r'^offers-([^-]+)-(.+)$');
    final match = regex.firstMatch(topic);
    if (match != null) {
      final key = match.group(2)!;
      final originalKey = key == 'all' ? '*' : key;
      return {'offerId': match.group(1)!, 'key': originalKey};
    }
    return null;
  }
}
