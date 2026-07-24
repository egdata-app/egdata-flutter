import 'package:egdata_flutter/widgets/app_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders desktop companion navigation labels', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppSidebar(
            currentPage: AppPage.dashboard,
            onPageSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Tools'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('keeps Library active while a game detail route is open', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppSidebar(
            currentPage: AppPage.gameDetail,
            onPageSelected: (_) {},
          ),
        ),
      ),
    );

    final libraryText = tester.widget<Text>(find.text('Library'));
    expect(libraryText.style?.color, isNotNull);
  });
}
