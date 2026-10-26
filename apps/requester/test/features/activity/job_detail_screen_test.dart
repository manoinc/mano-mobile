import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_requester/features/activity/job_detail_screen.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/pump_app.dart';
import 'activity_fakes.dart';

void main() {
  testWidgets('shows the service, provider, schedule, price and status', (
    tester,
  ) async {
    await pumpRouterAt(tester, '/projects/job/job-2');

    expect(find.byType(JobDetailScreen), findsOneWidget);
    expect(find.text('Reparación de fugas'), findsOneWidget);
    expect(find.text('Ana Gómez'), findsOneWidget);
    expect(find.byType(ManoAvatar), findsOneWidget);
    final start = mockJobStart(4, 14);
    expect(
      find.text(
        '${ManoFormat.weekdayShort(start)} ${ManoFormat.dayMonth(start)}',
      ),
      findsOneWidget,
    );
    expect(find.text(ManoFormat.time(start)), findsOneWidget);
    final price = tester.widget<ManoPriceTag>(find.byType(ManoPriceTag));
    expect(price.amountLabel, r'$45.000');
    expect(price.rateLabel, 'por hora');
    expect(find.widgetWithText(ManoStatusChip, 'Programado'), findsOneWidget);
  });

  testWidgets('a provider without a name yet reads Tu profesional, once', (
    tester,
  ) async {
    await pumpRouterAt(
      tester,
      '/projects/job/job-9',
      overrides: [
        jobProvider.overrideWith(
          (ref, id) async => Job(
            id: id,
            offerId: 'o1',
            serviceTitle: 'Reparación de fugas',
            client: const Party(id: 'c1', displayName: '', photoUrl: ''),
            provider: const Party(id: 'p1', displayName: '', photoUrl: ''),
            rateType: RateType.fixed,
            amountCop: 120000,
            start: mockJobStart(2, 9),
            status: JobStatus.scheduled,
          ),
        ),
      ],
    );

    expect(find.text('Tu profesional'), findsOneWidget);
    expect(find.text('Profesional'), findsNothing);
  });

  testWidgets('an unknown id shows a not-found state', (tester) async {
    final c = await pumpRouterAt(tester, '/projects/job/nope');

    expect(find.text('No encontramos este trabajo.'), findsOneWidget);
    await tester.tap(find.text('Volver a Actividad'));
    await tester.pumpAndSettle();
    expect(routerPath(c), '/projects');
  });

  testWidgets('a load failure shows an error with retry', (tester) async {
    await pumpRouterAt(
      tester,
      '/projects/job/job-1',
      overrides: [
        jobProvider.overrideWith((ref, id) async => throw StateError('x')),
      ],
    );

    expect(find.text('No pudimos cargar este trabajo.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('a scheduled job can be cancelled with a reason', (tester) async {
    final c = await pumpRouterAt(tester, '/projects/job/job-1');
    expect(find.text('Volver a contratar'), findsNothing);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('¿Cancelar este trabajo?'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Cambio de planes');
    await tester.tap(find.text('Sí, cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Trabajo cancelado'), findsOneWidget);
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ManoStatusChip, 'Cancelado'), findsOneWidget);
    expect(find.text('Cancelar'), findsNothing);
    expect(find.text('Volver a contratar'), findsOneWidget);
    final job = await c.read(jobRepositoryProvider).job('job-1');
    expect(job?.status, JobStatus.cancelled);
  });

  testWidgets('dismissing the cancel sheet keeps the job', (tester) async {
    final c = await pumpRouterAt(tester, '/projects/job/job-1');

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();

    final job = await c.read(jobRepositoryProvider).job('job-1');
    expect(job?.status, JobStatus.scheduled);
    expect(find.text('Trabajo cancelado'), findsNothing);
  });

  testWidgets('a finished job can be rebooked', (tester) async {
    await pumpRouterAt(tester, '/projects/job/job-5');
    expect(find.text('Cancelar'), findsNothing);

    await tester.tap(find.text('Volver a contratar'));
    await tester.pumpAndSettle();

    expect(find.text('Solicitud enviada'), findsOneWidget);
    expect(find.textContaining('Andrés Castro'), findsWidgets);
  });
}
