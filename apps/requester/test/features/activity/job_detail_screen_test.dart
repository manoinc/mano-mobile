import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_requester/features/activity/job_detail_screen.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/fake_reviews.dart';
import '../../support/fake_session_repository.dart';
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

  testWidgets('a finished, unpaid job offers Pagar first, then Calificar', (
    tester,
  ) async {
    await pumpRouterAt(tester, '/projects/job/job-5');

    expect(find.widgetWithText(ManoPrimaryButton, r'Pagar $120.000'), findsOne);
    expect(find.widgetWithText(ManoOutlineButton, 'Calificar'), findsOne);
    expect(find.text('Volver a contratar'), findsNothing);
    expect(find.widgetWithText(ManoStatusChip, 'Pagado'), findsNothing);
  });

  testWidgets('a paid job shows Pagado and no Pagar', (tester) async {
    await pumpRouterAt(tester, '/projects/job/job-5', overrides: paidJobs());

    expect(find.widgetWithText(ManoStatusChip, 'Pagado'), findsOneWidget);
    expect(find.textContaining('Pagar'), findsNothing);
  });

  testWidgets('a finished job can be rebooked', (tester) async {
    await pumpRouterAt(tester, '/projects/job/job-5', overrides: paidJobs());
    expect(find.text('Cancelar'), findsNothing);

    await tester.tap(find.text('Volver a contratar'));
    await tester.pumpAndSettle();

    expect(find.text('Solicitud enviada'), findsOneWidget);
    expect(find.textContaining('Andrés Castro'), findsWidgets);
  });

  group('rating (HU-C6)', () {
    Future<FakeReviews> openSheet(
      WidgetTester tester, {
      Result<Review, DataFailure>? written,
    }) async {
      final reviews = FakeReviews(written: written);
      await pumpRouterAt(
        tester,
        '/projects/job/job-5',
        overrides: [
          reviewRepositoryProvider.overrideWithValue(reviews),
          ...paidJobs(),
        ],
      );
      await tester.tap(find.text('Calificar'));
      await tester.pumpAndSettle();
      return reviews;
    }

    Future<void> rate(WidgetTester tester, int stars) async {
      await tester.tap(find.bySemanticsLabel('$stars estrellas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enviar'));
      await tester.pumpAndSettle();
    }

    testWidgets('a paid job offers Calificar first, rebooking second', (
      tester,
    ) async {
      await pumpRouterAt(tester, '/projects/job/job-5', overrides: paidJobs());

      expect(find.widgetWithText(ManoPrimaryButton, 'Calificar'), findsOne);
      expect(
        find.widgetWithText(ManoOutlineButton, 'Volver a contratar'),
        findsOne,
      );
    });

    testWidgets('a cancelled job can only be rebooked', (tester) async {
      await pumpRouterAt(tester, '/projects/job/job-6');

      expect(find.text('Calificar'), findsNothing);
      expect(
        find.widgetWithText(ManoPrimaryButton, 'Volver a contratar'),
        findsOne,
      );
    });

    testWidgets(
      'rating sends stars and comment, thanks, then shows Calificado',
      (tester) async {
        final reviews = await openSheet(tester);
        expect(find.text('¿Cómo te fue con Andrés Castro?'), findsOneWidget);
        expect(
          tester
              .widget<ManoPrimaryButton>(
                find.widgetWithText(ManoPrimaryButton, 'Enviar'),
              )
              .onPressed,
          isNull,
        );

        await tester.tap(find.bySemanticsLabel('5 estrellas'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Excelente trabajo');
        await tester.tap(find.text('Enviar'));
        await tester.pumpAndSettle();

        expect(reviews.writes, [('provider', 'job-5', 5, 'Excelente trabajo')]);
        expect(find.text('¡Gracias por calificar!'), findsOneWidget);
        await tester.tap(find.text('Listo'));
        await tester.pumpAndSettle();

        expect(find.byType(ManoRatingSheet), findsNothing);
        expect(find.text('Calificar'), findsNothing);
        expect(find.widgetWithText(ManoQuietButton, 'Calificado ★5'), findsOne);
        expect(
          find.widgetWithText(ManoPrimaryButton, 'Volver a contratar'),
          findsOne,
        );
      },
    );

    testWidgets('closing after the thanks still shows Calificado', (
      tester,
    ) async {
      await openSheet(tester);
      await rate(tester, 4);

      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(find.text('Calificado ★4'), findsOneWidget);
    });

    testWidgets('a job not yet reviewable says to try in a few minutes', (
      tester,
    ) async {
      await openSheet(
        tester,
        written: const Err(DataRejected(reason: 'FailedPrecondition: no')),
      );
      await rate(tester, 3);

      expect(
        find.text(
          'Aún no puedes calificar este trabajo. Intenta en unos minutos.',
        ),
        findsOneWidget,
      );
      expect(find.byType(ManoRatingSheet), findsOneWidget);
      await tester.tap(find.byTooltip('Cerrar'));
      await tester.pumpAndSettle();
      expect(find.text('Calificar'), findsOneWidget);
    });

    testWidgets('any other failure says to try again', (tester) async {
      await openSheet(tester, written: const Err(DataUnavailable()));
      await rate(tester, 3);

      expect(
        find.text('No pudimos enviar tu calificación. Intenta de nuevo.'),
        findsOneWidget,
      );
    });
  });

  testWidgets("Escribir opens the job's chat", (tester) async {
    final c = await pumpRouterAt(
      tester,
      '/projects/job/job-2',
      session: FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
    );

    await tester.tap(find.byTooltip('Escribir'));
    await tester.pumpAndSettle();

    expect(routerPath(c), '/inbox/conv-job-job-2');
    expect(find.byType(ManoMessageComposer), findsOneWidget);
  });

  testWidgets('a guest is asked to sign in before writing', (tester) async {
    await pumpRouterAt(tester, '/projects/job/job-2');

    await tester.tap(find.byTooltip('Escribir'));
    await tester.pumpAndSettle();

    expect(find.text('Necesitas una cuenta'), findsOneWidget);
  });
}
