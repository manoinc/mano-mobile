import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_provider/features/agenda/agenda_job_screen.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/fake_session_repository.dart';
import '../../support/pump_app.dart';
import 'agenda_fakes.dart';

Finder _chip(String label) => find.widgetWithText(ManoStatusChip, label);

void main() {
  testWidgets('shows the service, client, schedule, price and status', (
    tester,
  ) async {
    await pumpRouterAt(tester, '/agenda/job/job-1');

    expect(find.byType(AgendaJobScreen), findsOneWidget);
    expect(_chip('Programado'), findsOneWidget);
    expect(find.text('Limpieza profunda del hogar'), findsOneWidget);
    expect(find.text('Laura Pérez'), findsOneWidget);
    expect(find.byType(ManoAvatar), findsOneWidget);
    final start = mockJobStart(2, 9);
    expect(
      find.text(
        '${ManoFormat.weekdayShort(start)} ${ManoFormat.dayMonth(start)}',
      ),
      findsOneWidget,
    );
    expect(find.text(ManoFormat.time(start)), findsOneWidget);
    final price = tester.widget<ManoPriceTag>(find.byType(ManoPriceTag));
    expect(price.amountLabel, r'$120.000');
    expect(price.rateLabel, 'precio fijo');
    expect(find.text('Iniciar trabajo'), findsOneWidget);
    expect(find.text('Cancelar trabajo'), findsOneWidget);
    expect(find.text('Finalizar trabajo'), findsNothing);
  });

  testWidgets('starting a job moves it in progress', (tester) async {
    final c = await pumpRouterAt(tester, '/agenda/job/job-1');

    await tester.tap(find.text('Iniciar trabajo'));
    await tester.pumpAndSettle();

    expect(_chip('En curso'), findsOneWidget);
    expect(find.text('Finalizar trabajo'), findsOneWidget);
    expect(find.text('Iniciar trabajo'), findsNothing);
    final job = await c.read(jobRepositoryProvider).job('job-1');
    expect(job?.status, JobStatus.inProgress);
  });

  testWidgets('a fixed-price job finishes after a confirm', (tester) async {
    final c = await pumpRouterAt(tester, '/agenda/job/job-4');

    await tester.tap(find.text('Finalizar trabajo'));
    await tester.pumpAndSettle();
    expect(find.text('¿Finalizar este trabajo?'), findsOneWidget);
    await tester.tap(find.text('Sí, finalizar'));
    await tester.pumpAndSettle();

    expect(_chip('Finalizado'), findsOneWidget);
    expect(find.text('Finalizar trabajo'), findsNothing);
    expect(find.text('Cancelar trabajo'), findsNothing);
    final job = await c.read(jobRepositoryProvider).job('job-4');
    expect(job?.status, JobStatus.finished);
  });

  testWidgets('an hourly job logs hours with a live total', (tester) async {
    final c = await pumpRouterAt(
      tester,
      '/agenda/job/job-3',
      overrides: [
        clockAt(mockJobStart(0, 8).add(const Duration(hours: 3, minutes: 10))),
      ],
    );

    await tester.tap(find.text('Finalizar trabajo'));
    await tester.pumpAndSettle();
    expect(find.text('3 h'), findsOneWidget);
    expect(find.text(r'Total $135.000'), findsOneWidget);

    await tester.tap(find.byKey(const Key('hour-logger-minus')));
    await tester.pumpAndSettle();
    expect(find.text('2,5 h'), findsOneWidget);
    expect(find.text(r'Total $112.500'), findsOneWidget);
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(_chip('Finalizado'), findsOneWidget);
    expect(find.text('2,5 h'), findsOneWidget);
    expect(find.text(r'$112.500'), findsOneWidget);
    final job = await c.read(jobRepositoryProvider).job('job-3');
    expect(job?.actualHours, 2.5);
  });

  testWidgets('the hour logger stops at half an hour', (tester) async {
    await pumpRouterAt(
      tester,
      '/agenda/job/job-3',
      overrides: [clockAt(mockJobStart(0, 8))],
    );

    await tester.tap(find.text('Finalizar trabajo'));
    await tester.pumpAndSettle();
    expect(find.text('0,5 h'), findsOneWidget);
    final minus = tester.widget<IconButton>(
      find.byKey(const Key('hour-logger-minus')),
    );
    expect(minus.onPressed, isNull);

    await tester.tap(find.byKey(const Key('hour-logger-plus')));
    await tester.pumpAndSettle();
    expect(find.text('1 h'), findsOneWidget);
  });

  testWidgets('a job can be cancelled with a reason', (tester) async {
    final c = await pumpRouterAt(tester, '/agenda/job/job-1');

    await tester.tap(find.text('Cancelar trabajo'));
    await tester.pumpAndSettle();
    expect(find.text('¿Cancelar este trabajo?'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Imprevisto');
    await tester.tap(find.text('Sí, cancelar'));
    await tester.pumpAndSettle();

    expect(_chip('Cancelado'), findsOneWidget);
    expect(find.text('Iniciar trabajo'), findsNothing);
    final job = await c.read(jobRepositoryProvider).job('job-1');
    expect(job?.status, JobStatus.cancelled);
  });

  testWidgets('an unknown id shows a not-found state', (tester) async {
    final c = await pumpRouterAt(tester, '/agenda/job/nope');

    expect(find.text('No encontramos este trabajo.'), findsOneWidget);
    await tester.tap(find.text('Volver a la agenda'));
    await tester.pumpAndSettle();
    expect(routerPath(c), '/agenda');
  });

  testWidgets('a load failure shows an error with retry', (tester) async {
    await pumpRouterAt(
      tester,
      '/agenda/job/job-1',
      overrides: [
        jobProvider.overrideWith((ref, id) async => throw StateError('x')),
      ],
    );

    expect(find.text('No pudimos cargar este trabajo.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets("Escribir opens the job's chat", (tester) async {
    final c = await pumpRouterAt(
      tester,
      '/agenda/job/job-1',
      session: FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
    );

    await tester.tap(find.byTooltip('Escribir'));
    await tester.pumpAndSettle();

    expect(routerPath(c), '/inbox/conv-job-job-1');
    expect(find.byType(ManoMessageComposer), findsOneWidget);
  });

  testWidgets('a guest is asked to sign in before writing', (tester) async {
    await pumpRouterAt(tester, '/agenda/job/job-1');

    await tester.tap(find.byTooltip('Escribir'));
    await tester.pumpAndSettle();

    expect(find.text('Necesitas una cuenta'), findsOneWidget);
  });
}
