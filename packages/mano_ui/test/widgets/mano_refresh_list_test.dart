import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    theme: ManoTheme.light(),
    home: Scaffold(body: child),
  ),
);

void main() {
  testWidgets('renders its children separated by dividers', (tester) async {
    await _pump(
      tester,
      ManoRefreshList(
        onRefresh: () async {},
        emptyMessage: 'Nada',
        children: const [Text('uno'), Text('dos')],
      ),
    );

    expect(find.text('uno'), findsOneWidget);
    expect(find.text('dos'), findsOneWidget);
    expect(find.byType(Divider), findsOneWidget);
    expect(find.text('Nada'), findsNothing);
  });

  testWidgets('pulling down calls onRefresh', (tester) async {
    var refreshes = 0;
    await _pump(
      tester,
      ManoRefreshList(
        onRefresh: () async => refreshes++,
        emptyMessage: 'Nada',
        children: const [Text('uno')],
      ),
    );

    await tester.fling(find.text('uno'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(refreshes, 1);
  });

  testWidgets('an empty list shows the message and can still be pulled', (
    tester,
  ) async {
    var refreshes = 0;
    await _pump(
      tester,
      ManoRefreshList(
        onRefresh: () async => refreshes++,
        emptyMessage: 'Aún no tienes conversaciones.',
        children: const [],
      ),
    );

    expect(find.text('Aún no tienes conversaciones.'), findsOneWidget);
    await tester.fling(
      find.text('Aún no tienes conversaciones.'),
      const Offset(0, 400),
      1000,
    );
    await tester.pumpAndSettle();
    expect(refreshes, 1);
  });
}
