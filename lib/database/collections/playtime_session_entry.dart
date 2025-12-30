import 'package:isar/isar.dart';

part 'playtime_session_entry.g.dart';

@Collection()
class PlaytimeSessionEntry {
  Id id = Isar.autoIncrement;

  @Index()
  late String gameId; // catalogItemId from GameInfo

  late String gameName; // displayName for display purposes
  String? thumbnailUrl; // cached thumbnail for stats display

  @Index()
  late DateTime startTime; // when session started
  DateTime? endTime; // when session ended (null = still running)

  late int durationSeconds; // calculated duration for queries

  // Link to the specific install (installationGuid)
  String? installationGuid;

  // For detecting the process
  String? processName; // the executable name that was detected

  PlaytimeSessionEntry();

  @ignore
  bool get isActive => endTime == null;

  @ignore
  Duration get duration => endTime != null
      ? endTime!.difference(startTime)
      : DateTime.now().difference(startTime);

  @ignore
  String get formattedDuration {
    final dur = duration;
    final hours = dur.inHours;
    final minutes = dur.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
