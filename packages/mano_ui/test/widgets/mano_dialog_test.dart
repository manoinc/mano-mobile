import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

void main() {
  testWidgets('says thank you and offers one way on', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: ManoTheme.light(),
        home: Scaffold(
          body: ManoDialogCard(
            title: '¡Gracias por unirte a Mano!',
            message: 'Estamos aquí para ayudarte.',
            primaryLabel: '¡Empecemos!',
            onPrimary: () => taps++,
          ),
        ),
      ),
    );

    expect(find.text('¡Gracias por unirte a Mano!'), findsOneWidget);
    expect(find.text('Estamos aquí para ayudarte.'), findsOneWidget);

    await tester.tap(find.text('¡Empecemos!'));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('shows the art it is handed', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ManoTheme.light(),
        home: const Scaffold(
          body: ManoDialogCard(
            art: SizedBox(key: Key('art'), width: 64, height: 64),
            title: 'Listo',
            message: 'Todo en orden.',
            primaryLabel: 'Seguir',
            onPrimary: null,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('art')), findsOneWidget);
  });

  testWidgets('showManoDialog raises it over an ink scrim and returns a value', (
    tester,
  ) async {
    late BuildContext hostContext;
    await tester.pumpWidget(
      MaterialApp(
        theme: ManoTheme.light(),
        home: Builder(
          builder: (context) {
            hostContext = context;
            return const Scaffold(body: SizedBox.expand());
          },
        ),
      ),
    );

    final result = showManoDialog<String>(
      context: hostContext,
      builder: (context) => ManoDialogCard(
        title: 'Listo',
        message: 'Todo en orden.',
        primaryLabel: 'Seguir',
        onPrimary: () => Navigator.of(context).pop('went'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Listo'), findsOneWidget);

    final barrier = tester.widget<ModalBarrier>(
      find.byType(ModalBarrier).last,
    );
    expect(barrier.color, ManoColors.ink.withValues(alpha: 0.45));

    await tester.tap(find.text('Seguir'));
    await tester.pumpAndSettle();

    expect(await result, 'went');
    expect(find.text('Listo'), findsNothing);
  });

  testWidgets('skips the entrance when animations are off', (tester) async {
    late BuildContext hostContext;
    await tester.pumpWidget(
      MaterialApp(
        theme: ManoTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              hostContext = context;
              return const Scaffold(body: SizedBox.expand());
            },
          ),
        ),
      ),
    );

    unawaited(
      showManoDialog<void>(
        context: hostContext,
        builder: (context) => const ManoDialogCard(
          title: 'Listo',
          message: 'Todo en orden.',
          primaryLabel: 'Seguir',
          onPrimary: null,
        ),
      ),
    );
    await tester.pump();

    // One frame, no settling: it is simply there.
    expect(find.text('Listo'), findsOneWidget);
  });
}
