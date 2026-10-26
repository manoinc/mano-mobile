import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_provider/features/agenda/agenda_labels.dart';
import 'package:mano_provider/features/availability/availability_view.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/agenda_calendar.dart';
import '../../support/fake_session_repository.dart';
import '../../support/pump_app.dart';
import 'agenda_fakes.dart';

Future<void> _openFilter(WidgetTester tester, String label) async {
  final tab = find.descendant(
    of: find.byType(ManoProjectFilterTabs),
    matching: find.text(label),
  );
  // Four pills can outrun a narrow phone, so the row scrolls.
  await tester.scrollUntilVisible(
    tab,
    100,
    scrollable: find.descendant(
      of: find.byType(ManoProjectFilterTabs),
      matching: find.byType(Scrollable),
    ),
  );
  await tester.ensureVisible(tab);
  await tester.pumpAndSettle();
  await tester.tap(tab);
  await tester.pumpAndSettle();
}

Finder _card(String id) => find.byKey(Key('agenda-job-$id'));

void main() {
  testWidgets("opens on the calendar at today, listing today's jobs", (
    tester,
  ) async {
    useTallPhone(tester);
    await pumpRouterAt(tester, '/agenda');

    expect(find.text('Agenda'), findsWidgets);
    expect(find.byType(ManoMonthCalendar), findsOneWidget);
    expect(find.text('Hoy'), findsOneWidget);
    expect(_card('job-3'), findsOneWidget);
    expect(_card('job-4'), findsOneWidget);
    expect(_card('job-1'), findsNothing);
  });

  testWidgets('marks the days that have jobs', (tester) async {
    useTallPhone(tester);
    await pumpRouterAt(tester, '/agenda');

    final marked = tester
        .widget<ManoMonthCalendar>(find.byType(ManoMonthCalendar))
        .markedDays;
    expect(marked, contains(mockJobStart(0, 0)));
    expect(marked, contains(mockJobStart(2, 0)));
  });

  testWidgets('a day without jobs says so', (tester) async {
    useTallPhone(tester);
    await pumpRouterAt(tester, '/agenda');
    await selectAgendaDay(tester, mockJobStart(1, 0));

    expect(find.byKey(const Key('agenda-empty-day')), findsOneWidget);
    expect(find.text('No tienes trabajos este día.'), findsOneWidget);
  });

  testWidgets('picking a day lists its jobs under that day', (tester) async {
    useTallPhone(tester);
    await pumpRouterAt(tester, '/agenda');
    final first = mockJobStart(2, 9);
    await selectAgendaDay(tester, first);

    expect(find.text(dayLabel(first, DateTime.now())), findsOneWidget);
    expect(_card('job-1'), findsOneWidget);
    expect(_card('job-3'), findsNothing);

    final card = tester.widget<ManoProjectCard>(_card('job-1'));
    expect(card.title, 'Limpieza profunda del hogar');
    expect(card.professionalName, 'Laura Pérez');
    expect(card.scheduledLabel, ManoFormat.time(first));
    expect(card.priceLabel, r'$120.000');
    expect(card.statusLabel, 'Programado');
  });

  testWidgets('En curso lists jobs in progress', (tester) async {
    useTallPhone(tester);
    await pumpRouterAt(tester, '/agenda');
    await _openFilter(tester, 'En curso');

    expect(_card('job-3'), findsOneWidget);
    expect(_card('job-4'), findsOneWidget);
    expect(_card('job-1'), findsNothing);
    final card = tester.widget<ManoProjectCard>(_card('job-3'));
    expect(card.priceLabel, r'$45.000/hora');
    expect(card.statusLabel, 'En curso');
  });

  testWidgets('Historial lists finished and cancelled jobs, newest first', (
    tester,
  ) async {
    useTallPhone(tester);
    await pumpRouterAt(tester, '/agenda');
    await _openFilter(tester, 'Historial');

    expect(
      tester.getTopLeft(_card('job-6')).dy,
      lessThan(tester.getTopLeft(_card('job-5')).dy),
    );
  });

  testWidgets('tapping a job opens its detail', (tester) async {
    useTallPhone(tester);
    final c = await pumpRouterAt(tester, '/agenda');
    await selectAgendaDay(tester, mockJobStart(2, 9));

    await tester.tap(_card('job-1'));
    await tester.pumpAndSettle();

    expect(routerPath(c), '/agenda/job/job-1');
  });

  testWidgets('every view has an empty state', (tester) async {
    final c = await pumpRouterAt(tester, '/agenda', overrides: emptyAgenda());

    expect(find.text('No tienes trabajos este día.'), findsOneWidget);
    await _openFilter(tester, 'En curso');
    expect(find.text('Ningún trabajo está en curso.'), findsOneWidget);
    await _openFilter(tester, 'Historial');
    expect(find.text('Aún no tienes historial.'), findsOneWidget);

    await tester.tap(find.text('Ver solicitudes'));
    await tester.pumpAndSettle();
    expect(routerPath(c), '/home');
  });

  testWidgets('a load failure shows an error with retry', (tester) async {
    await pumpRouterAt(tester, '/agenda', overrides: failingAgenda());

    expect(find.text('No pudimos cargar tu agenda.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('a free day can be blocked and unblocked from the calendar', (
    tester,
  ) async {
    useTallPhone(tester);
    final c = await pumpRouterAt(
      tester,
      '/agenda',
      // Blocking a day needs an account.
      session: FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
    );
    Set<DateTime> blocked() => tester
        .widget<ManoMonthCalendar>(find.byType(ManoMonthCalendar))
        .blockedDays;
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);

    expect(blocked(), isEmpty);
    await tester.tap(find.text('Bloquear día'));
    await tester.pumpAndSettle();
    expect(blocked(), {day});
    expect(find.text('Bloquear día'), findsNothing);
    expect(
      await c.read(availabilityRepositoryProvider).myBlocks(),
      hasLength(1),
    );

    await tester.tap(find.text('Desbloquear día'));
    await tester.pumpAndSettle();
    expect(blocked(), isEmpty);
    expect(find.text('Bloquear día'), findsOneWidget);
  });

  testWidgets('a past day offers no block action', (tester) async {
    final today = DateTime.now();
    if (today.day == 1) return;
    useTallPhone(tester);
    await pumpRouterAt(tester, '/agenda');
    await selectAgendaDay(
      tester,
      DateTime(today.year, today.month, today.day - 1),
    );

    expect(find.text('Bloquear día'), findsNothing);
  });

  testWidgets('Disponibilidad holds the weekly hours and blocked dates', (
    tester,
  ) async {
    useTallPhone(tester);
    await pumpRouterAt(tester, '/agenda');
    await _openFilter(tester, 'Disponibilidad');

    expect(find.byType(ManoMonthCalendar), findsNothing);
    expect(find.text('Horario semanal'), findsOneWidget);
    expect(find.text('Fechas bloqueadas'), findsOneWidget);
    expect(find.text('Google Calendar'), findsOneWidget);
  });

  testWidgets('/agenda/availability opens the Disponibilidad tab', (
    tester,
  ) async {
    useTallPhone(tester);
    await pumpRouterAt(tester, '/agenda/availability');

    expect(find.byType(AvailabilityView), findsOneWidget);
    expect(find.text('Horario semanal'), findsOneWidget);
  });
}
