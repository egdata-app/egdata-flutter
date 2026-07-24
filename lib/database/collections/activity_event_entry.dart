import 'package:isar_community/isar.dart';

part 'activity_event_entry.g.dart';

enum ActivityEventType { driveConnected, recoverySucceeded, recoveryFailed }

@Collection()
class ActivityEventEntry {
  Id id = Isar.autoIncrement;

  @enumerated
  late ActivityEventType type;

  late String title;
  late String detail;

  @Index()
  late DateTime occurredAt;

  String? gameIdentityKey;
  String? volumeId;

  ActivityEventEntry();
}
