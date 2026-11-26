import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host({
  VoidCallback? onSkip,
  ValueChanged<int>? onPageChanged,
  String skipLabel = 'Saltar',
}) => MaterialApp(
  theme: ManoTheme.light(),
  home: ManoIntroCarousel(
    count: 3,
    skipLabel: skipLabel,
    onSkip: onSkip ?? () {},
    onPageChanged: onPageChanged,
    slideBuilder: (context, i, reveal) => Center(child: Text('slide $i')),
    bottomBarBuilder: (context, i, next) =>
        ManoPrimaryButton(label: 'bar $i', onPressed: next),
  ),
);

void main() {
  testWidgets('shows the first slide, its bar and the skip label', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    expect(find.text('slide 0'), findsOneWidget);
    expect(find.text('bar 0'), findsOneWidget);
    expect(find.text('Saltar'), findsOneWidget);
  });

  testWidgets('the bar pages forward and reports the page', (tester) async {
    final pages = <int>[];
    await tester.pumpWidget(_host(onPageChanged: pages.add));
    await tester.pumpAndSettle();

    await tester.tap(find.text('bar 0'));
    await tester.pumpAndSettle();

    expect(find.text('bar 1'), findsOneWidget);
    expect(pages, [1]);
  });

  testWidgets('skip fires its callback', (tester) async {
    var skipped = 0;
    await tester.pumpWidget(_host(onSkip: () => skipped++));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Saltar'));

    expect(skipped, 1);
  });
}
