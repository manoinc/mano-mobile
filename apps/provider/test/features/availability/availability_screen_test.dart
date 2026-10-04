import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_provider/features/availability/availability_screen.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/fake_session_repository.dart';
import '../../support/pump_app.dart';

const _route = '/services/availability';

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
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<void> _pick(
  WidgetTester tester,
  String key,
  String label, {
  double delta = 100,
}) async {
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.text(label),
    delta,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists the weekly rules and an empty calendar', (tester) async {
    await _open(tester);

    expect(find.byType(AvailabilityScreen), findsOneWidget);
    expect(find.text('lun – vie · 8:00 a. m. – 12:00 p. m.'), findsOneWidget);
    expect(find.text('sáb · 9:00 a. m. – 1:00 p. m.'), findsOneWidget);
    expect(find.text('No tienes fechas bloqueadas.'), findsOneWidget);
    await _scrollTo(tester, find.text('Generar enlace'));
    expect(find.byType(ManoPrimaryButton), findsOneWidget);
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
    await _pick(tester, 'rule-start', '10:00 a. m.');
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
    await _pick(tester, 'rule-start', '9:00 a. m.');
    await _pick(tester, 'rule-end', '8:30 a. m.', delta: -100);
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

  testWidgets('issues, copies, reissues and revokes the calendar link', (
    tester,
  ) async {
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
    await _open(tester);

    await _scrollTo(tester, find.text('Generar enlace'));
    await tester.tap(find.text('Generar enlace'));
    await tester.pumpAndSettle();
    final url = find.textContaining('https://');
    expect(url, findsOneWidget);
    final first = tester.widget<Text>(url).data;
    expect(find.byType(ManoPrimaryButton), findsNothing);

    await _scrollTo(tester, find.text('Copiar enlace'));
    await tester.tap(find.text('Copiar enlace'));
    await tester.pump();
    expect(copied, first);
    expect(find.text('Enlace copiado'), findsOneWidget);

    await _scrollTo(tester, find.text('Generar nuevo enlace'));
    await tester.tap(find.text('Generar nuevo enlace'));
    await tester.pumpAndSettle();
    expect(find.textContaining('dejará de funcionar'), findsOneWidget);
    await tester.tap(find.widgetWithText(ManoPrimaryButton, 'Generar'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.textContaining('https://')).data,
      isNot(first),
    );

    await _scrollTo(tester, find.text('Desactivar enlace'));
    await tester.tap(find.text('Desactivar enlace'));
    await tester.pumpAndSettle();
    expect(find.textContaining('https://'), findsNothing);
    expect(find.text('Generar enlace'), findsOneWidget);
  });
}
