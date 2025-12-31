import 'package:isar/isar.dart';

part 'push_subscription_entry.g.dart';

@Collection()
class PushSubscriptionEntry {
  Id id = Isar.autoIncrement;

  /// The subscription ID returned by the API after subscribing
  @Index(unique: true)
  late String subscriptionId;

  /// The FCM token (mobile) or endpoint URL (web push)
  late String endpoint;

  /// The p256dh key for web push (null for FCM)
  String? p256dhKey;

  /// The auth key for web push (null for FCM)
  String? authKey;

  /// Topics this subscription is subscribed to
  List<String> topics = [];

  /// When the subscription was created
  late DateTime createdAt;

  /// When the subscription was last updated
  DateTime? updatedAt;

  PushSubscriptionEntry();
}
