import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('a rated provider shows a star and the label', (tester) async {
    await tester.pumpWidget(_host(const ManoRatingBadge(label: '4,9 · 32')));
    expect(find.textContaining('4,9 · 32', findRichText: true), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
  });

  testWidgets('a new provider shows the label without a star', (tester) async {
    await tester.pumpWidget(
      _host(const ManoRatingBadge(label: 'Nuevo', rated: false)),
    );
    expect(find.text('Nuevo', findRichText: true), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNothing);
  });
}
