import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/fake_support_desk.dart';
import '../../support/pump_app.dart';
import '../services/services_fakes.dart';

final class _FailingDesk extends FakeSupportDesk {
  @override
  Future<Result<SupportTicket, DataFailure>> submit(
    SupportTicketDraft draft,
  ) async => const Err(DataUnavailable());
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  FakeSupportDesk desk, {
  String path = '/profile/support',
}) async {
  tester.view.physicalSize = const Size(1080, 7200);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  return pumpRouterAt(
    tester,
    path,
    overrides: [
      serviceCatalogProvider.overrideWithValue(FakeServiceCatalog()),
      supportDeskProvider.overrideWithValue(desk),
    ],
  );
}

Future<void> _fill(WidgetTester tester) async {
  await tester.tap(find.text('Reclamo'));
  await tester.enterText(find.byKey(const Key('support-subject')), 'Cobro');
  await tester.enterText(
    find.byKey(const Key('support-description')),
    'Me cobraron dos veces el mismo lead.',
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Ayuda y PQRS on Perfil opens the form', (tester) async {
    final c = await _pump(
      tester,
      FakeSupportDesk(tickets: [fakeTicket()]),
      path: '/profile',
    );
    await tester.ensureVisible(find.text('Ayuda y PQRS'));
    await tester.tap(find.text('Ayuda y PQRS'));
    await tester.pumpAndSettle();

    expect(routerPath(c), '/profile/support');
    expect(find.byType(ManoSupportForm), findsOneWidget);
  });

  testWidgets('Enviar opens once subject and description are in', (
    tester,
  ) async {
    await _pump(tester, FakeSupportDesk(tickets: [fakeTicket()]));
    ManoPrimaryButton send() =>
        tester.widget(find.widgetWithText(ManoPrimaryButton, 'Enviar'));
    expect(send().onPressed, isNull);
    await _fill(tester);
    expect(send().onPressed, isNotNull);
  });

  testWidgets('filing opens the new ticket thread', (tester) async {
    final desk = FakeSupportDesk(tickets: [fakeTicket()]);
    final c = await _pump(tester, desk);
    await _fill(tester);
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    expect(desk.drafts.single.kind, SupportTicketKind.reclamo);
    expect(desk.drafts.single.subject, 'Cobro');
    expect(routerPath(c), '/profile/support/t1');
    expect(find.text('MANO-20261102-0001'), findsOneWidget);
    expect(find.text('Me cobraron dos veces el mismo lead.'), findsOneWidget);
  });

  group('with tickets', () {
    final threads = {
      't1': [
        SupportMessage(
          id: 'm0',
          fromStaff: true,
          body: 'Ya lo revisamos.',
          sentAt: DateTime(2026, 11, 2, 11),
        ),
      ],
    };

    testWidgets('Mis solicitudes lists radicado, subject and status', (
      tester,
    ) async {
      final c = await _pump(
        tester,
        FakeSupportDesk(
          tickets: [fakeTicket(status: SupportTicketStatus.inProgress)],
        ),
      );

      expect(find.text('Mis solicitudes'), findsOneWidget);
      expect(find.text('Cobro doble'), findsOneWidget);
      expect(find.text('En proceso'), findsOneWidget);
      await tester.tap(find.text('Cobro doble'));
      await tester.pumpAndSettle();
      expect(routerPath(c), '/profile/support/t1');
    });

    testWidgets('the thread shows staff replies and sends mine', (
      tester,
    ) async {
      final desk = FakeSupportDesk(tickets: [fakeTicket()], threads: threads);
      await _pump(tester, desk, path: '/profile/support/t1');

      expect(find.text('Me cobraron dos veces el mismo lead.'), findsOneWidget);
      expect(find.text('Soporte Mano'), findsOneWidget);
      expect(find.text('Ya lo revisamos.'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Gracias');
      await tester.tap(find.byKey(const Key('mano-composer-send')));
      await tester.pumpAndSettle();
      expect(desk.sent, ['Gracias']);
      expect(find.text('Gracias'), findsOneWidget);
    });

    testWidgets('a closed ticket has no composer, only the note', (
      tester,
    ) async {
      await _pump(
        tester,
        FakeSupportDesk(
          tickets: [fakeTicket(status: SupportTicketStatus.closed)],
          threads: threads,
        ),
        path: '/profile/support/t1',
      );

      expect(find.text('Cerrada'), findsOneWidget);
      expect(find.byType(ManoMessageComposer), findsNothing);
      expect(find.text(supportClosedNote), findsOneWidget);
    });

    testWidgets('pulling down fetches new replies', (tester) async {
      final desk = FakeSupportDesk(tickets: [fakeTicket()], threads: threads);
      await _pump(tester, desk, path: '/profile/support/t1');
      threads['t1']!.add(
        SupportMessage(
          id: 'm1',
          fromStaff: true,
          body: 'Resuelto.',
          sentAt: DateTime(2026, 11, 3),
        ),
      );

      await tester.drag(find.text('Ya lo revisamos.'), const Offset(0, 900));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Resuelto.'), findsOneWidget);
    });
  });

  testWidgets('a failure stays on the form and says so', (tester) async {
    await _pump(tester, _FailingDesk());
    await _fill(tester);
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    expect(find.text(const DataUnavailable().message), findsOneWidget);
    expect(find.byType(ManoSupportForm), findsOneWidget);
  });
}
