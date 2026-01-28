import 'package:isar_community/isar.dart';

part 'changelog_entry.g.dart';

@Collection()
class ChangelogEntry {
  Id id = Isar.autoIncrement;

  @Index()
  late String offerId;

  @Index(unique: true, composite: [CompositeIndex('offerId')])
  late String changeId;

  String? changeType;
  String? field;
  late DateTime timestamp;
  late bool notified;

  ChangelogEntry();

  factory ChangelogEntry.fromApiJson(String offerId, Map<String, dynamic> json) {
    return ChangelogEntry()
      ..offerId = offerId
      ..changeId = json['_id'] as String? ?? json['id'] as String? ?? DateTime.now().toIso8601String()
      ..changeType = json['changeType'] as String?
      ..field = json['field'] as String?
      ..timestamp = json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now()
      ..notified = false;
  }
}
