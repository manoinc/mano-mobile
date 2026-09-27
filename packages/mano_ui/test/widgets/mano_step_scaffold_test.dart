import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child, {MediaQueryData? media}) => MaterialApp(
  theme: ManoTheme.light(),
  home: media == null ? child : MediaQuery(data: media, child: child),
);

void main() {
  testWidgets('asks its question and offers one way on', (tester) async {
    var next = 0;
    await tester.pumpWidget(
      _host(
        ManoStepScaffold(
          headline: '¿Cómo te llamas?',
          subhead: 'Así te van a reconocer.',
          primaryLabel: 'Siguiente',
          onPrimary: () => next++,
          children: const [Text('campo')],
        ),
      ),
    );

    expect(find.text('¿Cómo te llamas?'), findsOneWidget);
    expect(find.text('Así te van a reconocer.'), findsOneWidget);
    expect(find.text('campo'), findsOneWidget);

    await tester.tap(find.text('Siguiente'));
    await tester.pump();
    expect(next, 1);
  });

  testWidgets('offers a way back only when there is one', (tester) async {
    var back = 0;
    await tester.pumpWidget(
      _host(
        ManoStepScaffold(
          onBack: () => back++,
          headline: '¿Dónde vives?',
          primaryLabel: 'Siguiente',
          onPrimary: () {},
          children: const [Text('campo')],
        ),
      ),
    );

    await tester.tap(find.byTooltip('Atrás'));
    await tester.pump();
    expect(back, 1);

    await tester.pumpWidget(
      _host(
        ManoStepScaffold(
          headline: '¿Dónde vives?',
          primaryLabel: 'Siguiente',
          onPrimary: () {},
          children: const [Text('campo')],
        ),
      ),
    );

    expect(find.byTooltip('Atrás'), findsNothing);
  });

  testWidgets('carries an escape hatch in the top corner', (tester) async {
    var skipped = 0;
    await tester.pumpWidget(
      _host(
        ManoStepScaffold(
          headline: '¿Cómo te llamas?',
          trailingLabel: 'Ahora no',
          onTrailing: () => skipped++,
          primaryLabel: 'Siguiente',
          onPrimary: () {},
          children: const [Text('campo')],
        ),
      ),
    );

    await tester.tap(find.text('Ahora no'));
    await tester.pump();
    expect(skipped, 1);
  });

  testWidgets('holds the primary shut until the step is answerable', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const ManoStepScaffold(
          headline: '¿Cómo te llamas?',
          primaryLabel: 'Siguiente',
          onPrimary: null,
          children: [Text('campo')],
        ),
      ),
    );

    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).enabled,
      isFalse,
    );
  });

  testWidgets('keeps the action reachable above the keyboard', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _host(
        ManoStepScaffold(
          headline: '¿Cómo te llamas?',
          primaryLabel: 'Siguiente',
          onPrimary: () {},
          children: const [Text('campo')],
        ),
        media: const MediaQueryData(
          size: Size(360, 640),
          viewInsets: EdgeInsets.only(bottom: 320),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getBottomLeft(find.byType(ManoPrimaryButton)).dy,
      lessThanOrEqualTo(640 - 320),
      reason: 'the button is behind the keyboard',
    );
  });

  testWidgets('scrolls rather than overflows on a small phone at large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _host(
        ManoStepScaffold(
          onBack: () {},
          trailingLabel: 'Ahora no',
          onTrailing: () {},
          headline: '¡Un gusto conocerte, Alejandra! ¿Dónde vives?',
          subhead: 'Usamos tu dirección para mostrarte profesionales cerca.',
          primaryLabel: 'Siguiente',
          onPrimary: () {},
          children: const [
            SizedBox(height: 200, child: Text('campo')),
            SizedBox(height: 200, child: Text('otro campo')),
          ],
        ),
        media: const MediaQueryData(
          size: Size(320, 640),
          textScaler: TextScaler.linear(1.5),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(Scrollable), findsWidgets);
  });
}
