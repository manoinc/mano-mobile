import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

final Finder _ground = find.descendant(
  of: find.byType(ManoAvatar),
  matching: find.byType(DecoratedBox),
);

Color _groundOf(WidgetTester tester) =>
    (tester.widget<DecoratedBox>(_ground.first).decoration as BoxDecoration)
        .color!;

void main() {
  testWidgets('shows the initials it was given', (tester) async {
    await tester.pumpWidget(_host(const ManoAvatar(initials: 'AR')));

    expect(find.text('AR'), findsOneWidget);
  });

  testWidgets('is round and honours its size', (tester) async {
    await tester.pumpWidget(_host(const ManoAvatar(initials: 'AR', size: 56)));

    expect(tester.getSize(find.byType(ManoAvatar)), const Size(56, 56));
    expect(
      (tester.widget<DecoratedBox>(_ground.first).decoration as BoxDecoration)
          .shape,
      BoxShape.circle,
    );
  });

  testWidgets('picks a stable tint from the initials', (tester) async {
    // Same person, same colour, every rebuild -- otherwise a list of taskers
    // reshuffles its palette on every frame.
    await tester.pumpWidget(_host(const ManoAvatar(initials: 'AR')));
    final first = _groundOf(tester);

    await tester.pumpWidget(_host(const ManoAvatar(initials: 'XX')));
    await tester.pumpWidget(_host(const ManoAvatar(initials: 'AR')));

    expect(_groundOf(tester), first);
  });

  testWidgets('different people are not all the same colour', (tester) async {
    final seen = <Color>{};
    for (final initials in ['AR', 'JM', 'LC', 'SP']) {
      await tester.pumpWidget(_host(ManoAvatar(initials: initials)));
      seen.add(_groundOf(tester));
    }

    expect(seen.length, greaterThan(1));
  });

  testWidgets('an explicit tint wins', (tester) async {
    await tester.pumpWidget(
      _host(const ManoAvatar(initials: 'AR', tint: ManoColors.clay)),
    );

    expect(_groundOf(tester), ManoColors.clay);
  });
}
