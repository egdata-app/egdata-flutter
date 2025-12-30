import 'package:isar/isar.dart';

part 'game_process_cache_entry.g.dart';

@Collection()
class GameProcessCacheEntry {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String catalogItemId; // from GameInfo

  late List<String> processNames; // executable names from API

  late DateTime fetchedAt; // when we fetched this

  GameProcessCacheEntry();

  // Cache validity (24 hours default)
  @ignore
  bool get isExpired => DateTime.now().difference(fetchedAt).inHours > 24;
}
