import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(List<Widget> children) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(
    body: Column(
      children: [ManoListingCarousel(height: 120, children: children)],
    ),
  ),
);

List<Widget> _items(int n) => [
  for (var i = 0; i < n; i++) Card(child: Center(child: Text('item $i'))),
];

void main() {
  testWidgets('shows the first item and peeks at the next', (tester) async {
    await tester.pumpWidget(_host(_items(4)));

    expect(find.text('item 0'), findsOneWidget);
    expect(find.text('item 1'), findsOneWidget);
  });

  testWidgets('swiping horizontally reveals later items', (tester) async {
    await tester.pumpWidget(_host(_items(4)));
    expect(find.text('item 3'), findsNothing);

    for (var i = 0; i < 3; i++) {
      await tester.fling(find.byType(ManoListingCarousel), const Offset(-600, 0), 2000);
      await tester.pumpAndSettle();
    }

    expect(find.text('item 3'), findsOneWidget);
  });

  testWidgets('is bounded to the given height', (tester) async {
    await tester.pumpWidget(_host(_items(2)));

    expect(tester.getSize(find.byType(ManoListingCarousel)).height, 120);
  });

  testWidgets('an empty list renders without throwing', (tester) async {
    await tester.pumpWidget(_host(const []));

    expect(tester.takeException(), isNull);
  });
}
