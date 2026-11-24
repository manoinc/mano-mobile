import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/fake_support_desk.dart';
import '../../support/pump_app.dart';

Finder _field(String label) => find.descendant(
  of: find.widgetWithText(ManoTextField, label),
  matching: find.byType(TextField),
);

Future<ProviderContainer> _open(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(1080, 2340)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  return pumpRouterAt(tester, '/profile/support');
}

// Scrolls past the shell's centre button, which overlaps the list's last pixels.
Future<void> _tapEnviar(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Enviar'));
  await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Enviar'));
}

void main() {
  testWidgets('answers common questions in place', (tester) async {
    await _open(tester);

    expect(find.text('Atención al cliente'), findsOneWidget);
    await tester.tap(find.text('¿Cómo cancelo un trabajo?'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Actividad'), findsWidgets);
  });

  testWidgets('Enviar waits for a subject and a description', (tester) async {
    await _open(tester);

    await tester.scrollUntilVisible(
      find.text('Enviar'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final enviar = tester.widget<ManoPrimaryButton>(
      find.ancestor(
        of: find.text('Enviar'),
        matching: find.byType(ManoPrimaryButton),
      ),
    );
    expect(enviar.onPressed, isNull);
  });

  testWidgets('filing a queja opens its thread with the description', (
    tester,
  ) async {
    await _open(tester);

    await tester.ensureVisible(find.text('Queja'));
    await tester.tap(find.text('Queja'));
    await tester.enterText(_field('Asunto'), 'Cobro doble');
    await tester.enterText(
      _field('Cuéntanos qué pasó'),
      'Me cobraron dos veces la limpieza del sábado.',
    );
    await tester.pump();
    await _tapEnviar(tester);
    await tester.pumpAndSettle();

    expect(find.textContaining('MANO-'), findsOneWidget);
    expect(find.text('Radicada'), findsOneWidget);
    expect(
      find.text('Me cobraron dos veces la limpieza del sábado.'),
      findsOneWidget,
    );
    expect(find.byType(ManoSupportForm), findsNothing);
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

    Future<ProviderContainer> pump(
      WidgetTester tester,
      FakeSupportDesk desk, {
      String path = '/profile/support',
    }) {
      tester.view
        ..physicalSize = const Size(1080, 2340)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      return pumpRouterAt(
        tester,
        path,
        overrides: [supportDeskProvider.overrideWithValue(desk)],
      );
    }

    testWidgets('Mis solicitudes lists radicado, subject and status', (
      tester,
    ) async {
      final c = await pump(
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
      await pump(tester, desk, path: '/profile/support/t1');

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
      await pump(
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
      await pump(tester, desk, path: '/profile/support/t1');
      threads['t1']!.add(
        SupportMessage(
          id: 'm1',
          fromStaff: true,
          body: 'Resuelto.',
          sentAt: DateTime(2026, 11, 3),
        ),
      );

      await tester.fling(
        find.text('Ya lo revisamos.'),
        const Offset(0, 400),
        1000,
      );
      await tester.pumpAndSettle();
      expect(find.text('Resuelto.'), findsOneWidget);
    });
  });
}
