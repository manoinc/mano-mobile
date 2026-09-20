import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('asks once, and says what it is for', (tester) async {
    await tester.pumpWidget(
      _host(
        ManoPromptSheet(
          title: 'Activa las notificaciones',
          message: 'No te pierdas mensajes importantes.',
          primaryLabel: 'Sí, notifícame',
          onPrimary: () {},
        ),
      ),
    );

    expect(find.text('Activa las notificaciones'), findsOneWidget);
    expect(find.text('No te pierdas mensajes importantes.'), findsOneWidget);
    expect(find.text('Sí, notifícame'), findsOneWidget);
  });

  testWidgets('carries whatever the caller puts in the middle', (tester) async {
    await tester.pumpWidget(
      _host(
        ManoPromptSheet(
          title: 'Activa las notificaciones',
          message: 'No te pierdas nada.',
          primaryLabel: 'Sí, notifícame',
          onPrimary: () {},
          child: ManoToggleRow(
            label: 'Recibir ofertas',
            value: true,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(ManoToggleRow), findsOneWidget);
  });

  testWidgets('can be closed, or not', (tester) async {
    var closed = 0;
    await tester.pumpWidget(
      _host(
        ManoPromptSheet(
          title: 'Activa las notificaciones',
          message: 'No te pierdas nada.',
          primaryLabel: 'Sí, notifícame',
          onPrimary: () {},
          onClose: () => closed++,
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(closed, 1);

    await tester.pumpWidget(
      _host(
        ManoPromptSheet(
          title: 'Activa las notificaciones',
          message: 'No te pierdas nada.',
          primaryLabel: 'Sí, notifícame',
          onPrimary: () {},
        ),
      ),
    );

    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('the primary action calls back', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        ManoPromptSheet(
          title: 'Activa las notificaciones',
          message: 'No te pierdas nada.',
          primaryLabel: 'Sí, notifícame',
          onPrimary: () => taps++,
        ),
      ),
    );

    await tester.tap(find.text('Sí, notifícame'));
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('keeps the action reachable when the message outgrows the sheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: ManoTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 480),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: ManoPromptSheet(
                title: 'Activa las notificaciones',
                message:
                    'No te pierdas mensajes importantes sobre detalles de tus '
                    'servicios y la actividad de tu cuenta.',
                primaryLabel: 'Sí, notifícame',
                onPrimary: () => taps++,
                child: ManoToggleRow(
                  label: 'Recibir ofertas de mantenimiento, recomendados y más.',
                  value: true,
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Sí, notifícame'));
    await tester.pump();

    expect(taps, 1, reason: 'the action scrolled out of reach');
  });
}
