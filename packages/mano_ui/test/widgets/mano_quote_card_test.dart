import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('shows who, how much, when and the message', (tester) async {
    await tester.pumpWidget(
      _host(
        const ManoQuoteCard(
          avatar: ManoInitialsAvatar(initials: 'AC', size: 40),
          name: 'Andrés Castro',
          amountLabel: r'$1.650.000',
          ageLabel: 'hace 4h',
          message: 'Incluye resanar grietas.',
        ),
      ),
    );

    expect(find.text('AC'), findsOneWidget);
    expect(find.text('Andrés Castro'), findsOneWidget);
    expect(find.text(r'$1.650.000'), findsOneWidget);
    expect(find.text('hace 4h'), findsOneWidget);
    expect(find.text('Incluye resanar grietas.'), findsOneWidget);
  });

  testWidgets('null callbacks hide Elegir and Descartar', (tester) async {
    await tester.pumpWidget(
      _host(
        const ManoQuoteCard(
          avatar: SizedBox.shrink(),
          name: 'Profesional',
          amountLabel: r'$580.000',
        ),
      ),
    );

    expect(find.text('Elegir'), findsNothing);
    expect(find.text('Descartar'), findsNothing);
  });

  testWidgets('Elegir and Descartar fire their callbacks', (tester) async {
    final calls = <String>[];
    await tester.pumpWidget(
      _host(
        ManoQuoteCard(
          avatar: const SizedBox.shrink(),
          name: 'Profesional',
          amountLabel: r'$580.000',
          onSelect: () => calls.add('select'),
          onDiscard: () => calls.add('discard'),
        ),
      ),
    );

    await tester.tap(find.text('Elegir'));
    await tester.tap(find.text('Descartar'));

    expect(calls, ['select', 'discard']);
  });

  testWidgets('a status chip shows when given', (tester) async {
    await tester.pumpWidget(
      _host(
        const ManoQuoteCard(
          avatar: SizedBox.shrink(),
          name: 'Profesional',
          amountLabel: r'$580.000',
          statusLabel: 'Elegida',
          statusTone: ManoStatusTone.success,
          selected: true,
        ),
      ),
    );

    expect(find.text('Elegida'), findsOneWidget);
  });

  testWidgets('fits 360 dp at 2x text', (tester) async {
    tester.view
      ..physicalSize = const Size(360, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: _host(
          ManoQuoteCard(
            avatar: const ManoInitialsAvatar(initials: 'CR', size: 40),
            name: 'Camila Rodríguez Restrepo',
            amountLabel: r'$12.650.000',
            ageLabel: 'hace 3d',
            statusLabel: 'Elegida',
            statusTone: ManoStatusTone.success,
            onSelect: () {},
            onDiscard: () {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the rating and opens the provider from its area', (
    tester,
  ) async {
    var provider = 0;
    await tester.pumpWidget(
      _host(
        ManoQuoteCard(
          avatar: const ManoInitialsAvatar(initials: 'AC'),
          name: 'Andrés Castro',
          amountLabel: '\$1.650.000',
          ratingLabel: 'Nuevo',
          rated: false,
          onProviderTap: () => provider++,
        ),
      ),
    );

    expect(find.byType(ManoRatingBadge), findsOneWidget);
    expect(find.text('Nuevo', findRichText: true), findsOneWidget);
    await tester.tap(find.text('Andrés Castro'));
    await tester.pumpAndSettle();
    expect(provider, 1);
  });

  testWidgets('no rating label shows no badge', (tester) async {
    await tester.pumpWidget(
      _host(
        const ManoQuoteCard(
          avatar: ManoInitialsAvatar(initials: 'AC'),
          name: 'Andrés Castro',
          amountLabel: '\$1.650.000',
        ),
      ),
    );
    expect(find.byType(ManoRatingBadge), findsNothing);
  });
}
