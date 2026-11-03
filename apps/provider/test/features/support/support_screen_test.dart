import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/pump_app.dart';
import '../services/services_fakes.dart';

final class _Desk implements SupportDesk {
  _Desk(this.answer);

  final Result<SupportTicket, DataFailure> answer;
  final drafts = <SupportTicketDraft>[];

  @override
  Future<Result<SupportTicket, DataFailure>> submit(
    SupportTicketDraft draft,
  ) async {
    drafts.add(draft);
    return answer;
  }
}

final _ticket = SupportTicket(
  number: 'MANO-20261102-0001',
  status: SupportTicketStatus.filed,
  createdAt: DateTime(2026, 11, 2, 9, 30),
);

Future<ProviderContainer> _pump(
  WidgetTester tester,
  _Desk desk, {
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
    final c = await _pump(tester, _Desk(Ok(_ticket)), path: '/profile');
    await tester.ensureVisible(find.text('Ayuda y PQRS'));
    await tester.tap(find.text('Ayuda y PQRS'));
    await tester.pumpAndSettle();

    expect(routerPath(c), '/profile/support');
    expect(find.byType(ManoSupportForm), findsOneWidget);
  });

  testWidgets('Enviar opens once subject and description are in', (
    tester,
  ) async {
    await _pump(tester, _Desk(Ok(_ticket)));
    ManoPrimaryButton send() =>
        tester.widget(find.widgetWithText(ManoPrimaryButton, 'Enviar'));
    expect(send().onPressed, isNull);
    await _fill(tester);
    expect(send().onPressed, isNotNull);
  });

  testWidgets('filing shows the radicado and its status', (tester) async {
    final desk = _Desk(Ok(_ticket));
    final c = await _pump(tester, desk);
    await _fill(tester);
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    expect(desk.drafts.single.kind, SupportTicketKind.reclamo);
    expect(desk.drafts.single.subject, 'Cobro');
    expect(find.text('Recibimos tu reclamo'), findsOneWidget);
    expect(find.text('MANO-20261102-0001'), findsOneWidget);
    expect(find.text('Radicada'), findsOneWidget);

    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();
    expect(routerPath(c), '/profile');
  });

  testWidgets('a failure stays on the form and says so', (tester) async {
    await _pump(tester, _Desk(const Err(DataUnavailable())));
    await _fill(tester);
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    expect(find.text(const DataUnavailable().message), findsOneWidget);
    expect(find.byType(ManoSupportForm), findsOneWidget);
  });
}
