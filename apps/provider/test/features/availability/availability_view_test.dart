import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_provider/features/availability/availability_view.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/fake_session_repository.dart';
import '../../support/pump_app.dart';

const _route = '/agenda/availability';

Future<ProviderContainer> _open(
  WidgetTester tester, {
  List<Override> overrides = const [],
}) {
  // A phone-sized surface, so sheets and menus lay out as they do on the A36.
  tester.view
    ..physicalSize = const Size(1080, 2340)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  return pumpRouterAt(
    tester,
    _route,
    overrides: overrides,
    session: FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
  );
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.descendant(
      of: find.byType(AvailabilityView),
      matching: find.byType(Scrollable),
    ),
  );
  await tester.pumpAndSettle();
}

// One wheel step is one half hour; positive moves later.
Future<void> _spin(WidgetTester tester, String key, int steps) async {
  await tester.drag(
    find.byKey(Key(key)),
    Offset(0, -steps * ManoTimeRangePicker.itemExtent),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists the weekly rules and an empty calendar', (tester) async {
    await _open(tester);

    expect(find.byType(AvailabilityView), findsOneWidget);
    expect(find.text('lun – vie · 8:00 a. m. – 12:00 p. m.'), findsOneWidget);
    expect(find.text('sáb · 9:00 a. m. – 1:00 p. m.'), findsOneWidget);
    expect(find.text('No tienes fechas bloqueadas.'), findsOneWidget);
    await _scrollTo(tester, find.text('Google Calendar'));
    expect(find.text('Generar enlace'), findsOneWidget);
  });

  testWidgets('a failed read shows an error with retry', (tester) async {
    await _open(
      tester,
      overrides: [
        myAvailabilityRulesProvider.overrideWith(
          (ref) async => throw StateError('x'),
        ),
      ],
    );

    expect(find.text('No pudimos cargar tus horarios.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('adds a Sunday rule from the editor', (tester) async {
    await _open(tester);

    await tester.tap(find.text('Agregar horario'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('D'));
    await _spin(tester, 'mano-time-wheel-start', 4);
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Agregar horario'), findsOneWidget);
    expect(find.text('dom · 10:00 a. m. – 12:00 p. m.'), findsOneWidget);
  });

  testWidgets('the editor explains what is wrong before saving', (
    tester,
  ) async {
    await _open(tester);

    await tester.tap(find.text('Agregar horario'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Elige al menos un día.'), findsOneWidget);

    await tester.tap(find.text('L'));
    await _spin(tester, 'mano-time-wheel-start', 2);
    await _spin(tester, 'mano-time-wheel-end', -7);
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(
      find.text('La hora de fin debe ser después del inicio.'),
      findsOneWidget,
    );
  });

  testWidgets('edits and deletes an existing rule', (tester) async {
    await _open(tester);

    await tester.tap(find.text('sáb · 9:00 a. m. – 1:00 p. m.'));
    await tester.pumpAndSettle();
    expect(find.text('Editar horario'), findsOneWidget);
    await tester.tap(find.text('D'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('sáb, dom · 9:00 a. m. – 1:00 p. m.'), findsOneWidget);

    await tester.tap(find.text('sáb, dom · 9:00 a. m. – 1:00 p. m.'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar horario'));
    await tester.pumpAndSettle();
    expect(find.textContaining('sáb'), findsNothing);
  });

  testWidgets('removes a blocked date', (tester) async {
    final c = await _open(tester);
    await c
        .read(availabilityActionsProvider.notifier)
        .block(
          DateTime(2026, 10, 12),
          DateTime(2026, 10, 15),
          reason: 'Vacaciones',
        );
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.byTooltip('Quitar bloqueo'));
    expect(find.text('12 oct – 14 oct · Vacaciones'), findsOneWidget);
    await tester.tap(find.byTooltip('Quitar bloqueo'));
    await tester.pumpAndSettle();

    expect(find.text('12 oct – 14 oct · Vacaciones'), findsNothing);
    expect(await c.read(availabilityRepositoryProvider).myBlocks(), isEmpty);
  });

  testWidgets('generates a link, shows it once and copies it', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    final c = await _open(tester);

    await _scrollTo(tester, find.text('Google Calendar'));
    expect(find.text('No conectado'), findsOneWidget);
    expect(find.textContaining('enlace privado'), findsOneWidget);
    expect(find.byTooltip('Más opciones'), findsNothing);
    await tester.tap(find.text('Generar enlace'));
    await tester.pumpAndSettle();

    final url = c.read(issuedCalendarFeedProvider)!.url;
    expect(url, startsWith('https://'));
    await _scrollTo(tester, find.text(url));
    expect(
      find.text('Guárdalo ahora: por seguridad no lo volveremos a mostrar.'),
      findsOneWidget,
    );
    expect(find.textContaining('Enlace activo desde'), findsOneWidget);

    await tester.tap(find.text('Copiar enlace'));
    await tester.pump();
    expect(copied, url);
    expect(find.text('Enlace copiado'), findsOneWidget);
  });

  testWidgets('a live link hides its URL, reissues on confirm and revokes', (
    tester,
  ) async {
    final c = await _open(tester);
    // Issued on an earlier visit: the status is live, the URL is not in memory.
    final old =
        (await c.read(availabilityRepositoryProvider).issueFeed()).valueOrNull!;
    c.invalidate(myCalendarFeedProvider);
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.text('Google Calendar'));
    expect(find.textContaining('Enlace activo desde'), findsOneWidget);
    expect(find.text(old.url), findsNothing);
    expect(find.text('Copiar enlace'), findsNothing);

    await tester.tap(find.text('Nuevo enlace'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'El enlace anterior dejará de funcionar en los calendarios donde '
        'lo agregaste.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(ManoPrimaryButton, 'Generar'));
    await tester.pumpAndSettle();
    final fresh = c.read(issuedCalendarFeedProvider)!.url;
    expect(fresh, isNot(old.url));
    expect(find.text(fresh), findsOneWidget);

    await _scrollTo(tester, find.byTooltip('Más opciones'));
    await tester.tap(find.byTooltip('Más opciones'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Desactivar enlace'));
    await tester.pumpAndSettle();
    expect(c.read(issuedCalendarFeedProvider), isNull);
    expect(await c.read(myCalendarFeedProvider.future), isNull);
    expect(find.text('No conectado'), findsOneWidget);
  });
}
