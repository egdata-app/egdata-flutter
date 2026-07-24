import 'package:isar_community/isar.dart';

import '../../models/epic_progress.dart';

part 'library_progress_entry.g.dart';

@Collection()
class LibraryProgressEntry {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String catalogItemId;

  String? artifactId;
  String? productId;
  int? officialPlaytimeSeconds;
  int? unlockedAchievements;
  int? totalAchievements;
  double? achievementPercent;
  DateTime? syncedAt;
  late String source;

  LibraryProgressEntry();

  factory LibraryProgressEntry.fromProgress(EpicGameProgress progress) {
    return LibraryProgressEntry()
      ..catalogItemId = progress.catalogItemId
      ..artifactId = progress.artifactId
      ..productId = progress.productId
      ..officialPlaytimeSeconds = progress.officialPlaytime?.inSeconds
      ..unlockedAchievements = progress.unlockedAchievements
      ..totalAchievements = progress.totalAchievements
      ..achievementPercent = progress.achievementPercent
      ..syncedAt = progress.syncedAt
      ..source = progress.source;
  }

  @ignore
  EpicGameProgress get progress {
    final seconds = officialPlaytimeSeconds;
    return EpicGameProgress(
      catalogItemId: catalogItemId,
      artifactId: artifactId,
      productId: productId,
      officialPlaytime: seconds == null ? null : Duration(seconds: seconds),
      unlockedAchievements: unlockedAchievements,
      totalAchievements: totalAchievements,
      achievementPercent: achievementPercent,
      syncedAt: syncedAt,
      source: source,
    );
  }
}
