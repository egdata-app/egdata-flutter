import 'package:egdata_flutter/models/drive_discovery.dart';
import 'package:egdata_flutter/models/game_info.dart';
import 'package:egdata_flutter/pages/desktop_home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in const [Size(1440, 1024), Size(1280, 720)]) {
    testWidgets('renders focused desktop home at ${size.width.toInt()}px', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DesktopHomePage(
              installedGames: [
                _game('Delta Force', 'delta'),
                _game('Cyberpunk 2077', 'cyberpunk'),
                _game('Dead Island 2', 'dead-island'),
                _game('Remnant II', 'remnant'),
              ],
              ownedGamesCount: 651,
              progressByCatalogItemId: const {},
              playtimeService: null,
              driveDiscoveryService: null,
              epicConnected: true,
              onOpenLibrary: () {},
              onOpenActivity: () {},
              onOpenDiskDiscovery: () {},
              onOpenGameDetails: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('PLAY NEXT'), findsOneWidget);
      expect(find.text('Delta Force'), findsWidgets);
      expect(find.text('UP NEXT'), findsOneWidget);
      expect(find.text('RECENT ACTIVITY'), findsOneWidget);
      expect(find.text('Disk discovery'), findsOneWidget);
      expect(find.text('Play'), findsOneWidget);
    });
  }
}

GameInfo _game(String name, String id) {
  return GameInfo(
    displayName: name,
    appName: id,
    installLocation: 'D:\\Games\\$name',
    installSize: 1,
    version: '1',
    catalogNamespace: 'test',
    catalogItemId: id,
    installationGuid: 'guid-$id',
    availability: InstalledGameAvailability.available,
  );
}
