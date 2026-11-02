import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('shows the average, its stars and the count', (tester) async {
    await tester.pumpWidget(
      _host(
        const ManoRatingSummary(
          average: 4.5,
          averageLabel: '4,5',
          countLabel: '32 reseñas',
        ),
      ),
    );

    expect(find.text('4,5'), findsOneWidget);
    expect(find.text('32 reseñas'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(4));
    expect(find.byIcon(Icons.star_half_rounded), findsOneWidget);
    expect(
      find.bySemanticsLabel('4,5 de 5 estrellas, 32 reseñas'),
      findsOneWidget,
    );
  });

  testWidgets('with no average shows the empty label instead', (tester) async {
    await tester.pumpWidget(
      _host(
        const ManoRatingSummary(
          average: null,
          averageLabel: '',
          countLabel: '',
          emptyLabel: 'Aún sin reseñas',
        ),
      ),
    );

    expect(find.text('Aún sin reseñas'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNothing);
  });
}
