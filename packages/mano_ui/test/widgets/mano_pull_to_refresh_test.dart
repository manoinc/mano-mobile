import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    theme: ManoTheme.light(),
    home: Scaffold(body: child),
  ),
);

Future<void> _pull(WidgetTester tester, Finder from) async {
  await tester.fling(from, const Offset(0, 400), 1000);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a still child, like an empty state, can be pulled', (
    tester,
  ) async {
    var refreshes = 0;
    await _pump(
      tester,
      ManoPullToRefresh(
        onRefresh: () async => refreshes++,
        child: const Center(child: Text('Nada por aquí')),
      ),
    );

    await _pull(tester, find.text('Nada por aquí'));

    expect(refreshes, 1);
  });

  testWidgets('a long list inside pulls from its top', (tester) async {
    var refreshes = 0;
    await _pump(
      tester,
      ManoPullToRefresh(
        onRefresh: () async => refreshes++,
        child: ListView(
          children: [for (var i = 0; i < 40; i++) Text('fila $i')],
        ),
      ),
    );

    await _pull(tester, find.text('fila 0'));

    expect(refreshes, 1);
  });

  testWidgets('a short list inside pulls too', (tester) async {
    var refreshes = 0;
    await _pump(
      tester,
      ManoPullToRefresh(
        onRefresh: () async => refreshes++,
        child: ListView(children: const [Text('una fila')]),
      ),
    );

    await _pull(tester, find.text('una fila'));

    expect(refreshes, 1);
  });
}
