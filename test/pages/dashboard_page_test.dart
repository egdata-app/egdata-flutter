import 'package:egdata_flutter/models/game_info.dart';
import 'package:egdata_flutter/pages/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders grounded utility home sections', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    GameInfo? openedGame;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardPage(
            installedGames: [
              _gameInfo(
                displayName: 'Alan Wake 2',
                catalogItemId: 'alan-wake-2',
              ),
            ],
            ownedGamesCount: 3,
            onOpenGameDetails: (game) => openedGame = game,
          ),
        ),
      ),
    );

    expect(find.text('CONTINUE PLAYING'), findsOneWidget);
    expect(find.text('Library Status'), findsOneWidget);
    expect(find.text('Recent Games'), findsOneWidget);
    expect(find.text('Epic Progress'), findsOneWidget);
    expect(find.text('Sync Center'), findsWidgets);
    expect(find.text('Alan Wake 2'), findsWidgets);
    expect(find.text('Owned'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Sync'), findsNothing);

    await tester.tap(find.text('Details'));
    expect(openedGame?.catalogItemId, 'alan-wake-2');
  });
}

GameInfo _gameInfo({
  required String displayName,
  required String catalogItemId,
}) {
  return GameInfo(
    displayName: displayName,
    appName: displayName.replaceAll(' ', ''),
    installLocation: 'D:\\Games\\Epic\\$displayName',
    installSize: 80 * 1024 * 1024 * 1024,
    version: '1.0',
    catalogNamespace: 'test',
    catalogItemId: catalogItemId,
    installationGuid: 'guid-$catalogItemId',
    manifestLocation: 'C:\\ProgramData\\Epic\\$catalogItemId.item',
  );
}
