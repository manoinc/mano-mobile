import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_requester/screens/projects_tab_screen.dart';
import 'package:mano_ui/mano_ui.dart';

import '../features/activity/activity_fakes.dart';
import '../support/pump_app.dart';

Future<void> _openFilter(WidgetTester tester, String label) async {
  final tab = find.descendant(
    of: find.byType(ManoProjectFilterTabs).last,
    matching: find.text(label),
  );
  await tester.dragUntilVisible(
    tab,
    find.byType(ManoProjectFilterTabs).last,
    const Offset(-120, 0),
  );
  await tester.pumpAndSettle();
  await tester.tap(tab);
  await tester.pumpAndSettle();
}

Finder _card(String key) => find.byKey(Key(key));

void main() {
  testWidgets('the router builds the tab at /projects', (tester) async {
    await pumpRouterAt(tester, '/projects');
    expect(find.byType(ProjectsTabScreen), findsOneWidget);
  });

  testWidgets('opens on pending requests', (tester) async {
    await pumpRouterAt(tester, '/projects');

    expect(_card('activity-request-request-1'), findsOneWidget);
    expect(_card('activity-request-request-2'), findsOneWidget);
    expect(find.byType(ManoProjectCard), findsWidgets);
    expect(find.text('Pendiente'), findsWidgets);
    expect(_card('activity-request-request-3'), findsNothing);
  });

  testWidgets('a job card shows title, provider, date, price and status', (
    tester,
  ) async {
    await pumpRouterAt(tester, '/projects');
    await _openFilter(tester, 'Programados');

    final card = tester.widget<ManoProjectCard>(_card('activity-job-job-1'));
    expect(card.title, 'Limpieza profunda del hogar');
    expect(card.professionalName, 'Andrés Castro');
    expect(card.scheduledLabel, ManoFormat.dateTime(mockJobStart(2, 9)));
    expect(card.priceLabel, r'$120.000');
    expect(card.statusLabel, 'Programado');

    final hourly = tester.widget<ManoProjectCard>(_card('activity-job-job-2'));
    expect(hourly.priceLabel, r'$45.000/hora');
  });

  testWidgets('each filter shows its own jobs and requests', (tester) async {
    await pumpRouterAt(tester, '/projects');

    await _openFilter(tester, 'Programados');
    expect(find.byType(ManoProjectCard), findsNWidgets(2));

    await _openFilter(tester, 'En curso');
    expect(_card('activity-job-job-3'), findsOneWidget);
    expect(_card('activity-job-job-4'), findsOneWidget);
    expect(find.byType(ManoProjectCard), findsNWidgets(2));

    await _openFilter(tester, 'Finalizados');
    expect(_card('activity-job-job-5'), findsOneWidget);
    expect(find.byType(ManoProjectCard), findsOneWidget);

    await _openFilter(tester, 'Cancelados');
    expect(_card('activity-job-job-6'), findsOneWidget);
    expect(_card('activity-request-request-4'), findsOneWidget);
    expect(_card('activity-request-request-5'), findsOneWidget);
    expect(find.byType(ManoProjectCard), findsNWidgets(3));
  });

  testWidgets('every filter has an empty state', (tester) async {
    await pumpRouterAt(tester, '/projects', overrides: emptyActivity());

    const messages = {
      'Solicitudes': 'No tienes solicitudes pendientes.',
      'Programados': 'No tienes trabajos programados.',
      'En curso': 'Ningún trabajo está en curso ahora.',
      'Finalizados': 'Aún no has terminado ningún trabajo.',
      'Cancelados': 'No tienes nada cancelado.',
    };
    for (final MapEntry(key: filter, value: message) in messages.entries) {
      await _openFilter(tester, filter);
      expect(find.byType(ManoEmptyState), findsOneWidget, reason: filter);
      expect(find.text(message), findsOneWidget, reason: filter);
    }
  });

  testWidgets('the empty state CTA goes to explore', (tester) async {
    final c = await pumpRouterAt(
      tester,
      '/projects',
      overrides: emptyActivity(),
    );

    await tester.tap(find.text('Explorar servicios'));
    await tester.pumpAndSettle();

    expect(routerPath(c), '/home');
  });

  testWidgets('a failed load shows an error with retry', (tester) async {
    await pumpRouterAt(tester, '/projects', overrides: failingActivity());

    expect(find.text('No pudimos cargar tu actividad.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('tapping a job card opens its detail', (tester) async {
    final c = await pumpRouterAt(tester, '/projects');
    await _openFilter(tester, 'Programados');

    await tester.tap(_card('activity-job-job-2'));
    await tester.pumpAndSettle();

    expect(routerPath(c), '/projects/job/job-2');
  });

  testWidgets('a pending request can be cancelled from its sheet', (
    tester,
  ) async {
    await pumpRouterAt(tester, '/projects');

    await tester.tap(_card('activity-request-request-1'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Acabamos de mudarnos'), findsOneWidget);

    await tester.tap(find.text('Cancelar solicitud'));
    await tester.pumpAndSettle();

    expect(find.text('Cancelamos tu solicitud.'), findsOneWidget);
    expect(_card('activity-request-request-1'), findsNothing);
    await _openFilter(tester, 'Cancelados');
    expect(_card('activity-request-request-1'), findsOneWidget);
  });

  testWidgets('a cancelled job card says only Cancelado', (tester) async {
    await pumpRouterAt(tester, '/projects');
    await _openFilter(tester, 'Cancelados');

    final card = tester.widget<ManoProjectCard>(_card('activity-job-job-6'));
    expect(card.statusLabel, 'Cancelado');
  });

  testWidgets('a closed request sheet offers no cancel', (tester) async {
    await pumpRouterAt(tester, '/projects');
    await _openFilter(tester, 'Cancelados');

    await tester.tap(_card('activity-request-request-4'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('No tengo disponibilidad esa semana.'),
      findsOneWidget,
    );
    expect(find.text('Cancelar solicitud'), findsNothing);
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
    expect(find.byType(ManoPromptSheet), findsNothing);
  });
}
