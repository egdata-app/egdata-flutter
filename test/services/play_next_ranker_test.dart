import 'package:egdata_flutter/database/database_service.dart';
import 'package:egdata_flutter/models/drive_discovery.dart';
import 'package:egdata_flutter/models/game_info.dart';
import 'package:egdata_flutter/services/play_next_ranker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const ranker = PlayNextRanker();

  test('ranks the most recently played available base game first', () {
    final ranked = ranker.rank(
      games: [_game('Older', 'older'), _game('Newer', 'newer')],
      sessions: [
        _session('older', DateTime(2026, 7, 9)),
        _session('newer', DateTime(2026, 7, 10)),
      ],
      progressByCatalogItemId: const {},
    );

    expect(ranked.map((game) => game.catalogItemId), ['newer', 'older']);
  });

  test('excludes add-ons and missing-drive games', () {
    final ranked = ranker.rank(
      games: [
        _game('Base', 'base'),
        _game('DLC', 'dlc', categories: const ['addons']),
        _game(
          'Missing',
          'missing',
          availability: InstalledGameAvailability.driveMissing,
        ),
      ],
      sessions: const [],
      progressByCatalogItemId: const {},
    );

    expect(ranked.single.catalogItemId, 'base');
  });
}

PlaytimeSessionEntry _session(String gameId, DateTime start) {
  return PlaytimeSessionEntry()
    ..gameId = gameId
    ..gameName = gameId
    ..startTime = start
    ..endTime = start.add(const Duration(hours: 1))
    ..durationSeconds = 3600;
}

GameInfo _game(
  String name,
  String id, {
  List<String> categories = const [],
  InstalledGameAvailability availability = InstalledGameAvailability.available,
}) {
  return GameInfo(
    displayName: name,
    appName: id,
    installLocation: 'D:\\Games\\$name',
    installSize: 1,
    version: '1',
    catalogNamespace: 'test',
    catalogItemId: id,
    installationGuid: 'guid-$id',
    appCategories: categories,
    availability: availability,
  );
}
