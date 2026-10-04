import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_provider/features/agenda/agenda_job_screen.dart';
import 'package:mano_provider/features/agenda/agenda_screen.dart';
import 'package:mano_provider/features/availability/availability_screen.dart';
import 'package:mano_provider/features/chat/chat_screen.dart';
import 'package:mano_provider/features/chat/provider_inbox_screen.dart';
import 'package:mano_provider/features/requests/requests_screen.dart';
import 'package:mano_provider/features/services/my_services_screen.dart';
import 'package:mano_provider/features/services/offer_editor_screen.dart';
import 'package:mano_provider/shell/provider_nav_shell.dart';
import 'package:mano_ui/mano_ui.dart';

import '../support/pump_app.dart';

void main() {
  testWidgets('opens onto incoming requests inside the shell', (tester) async {
    final c = await pumpRouterAt(tester, '/requests');
    expect(routerPath(c), '/requests');
    expect(find.byType(ProviderNavShell), findsOneWidget);
    expect(find.byType(RequestsScreen), findsOneWidget);
  });

  testWidgets('each tab shows its module', (tester) async {
    await pumpRouterAt(tester, '/requests');
    final tabs = {
      'Agenda': AgendaScreen,
      'Bandeja': ProviderInboxScreen,
      'Servicios': MyServicesScreen,
      'Solicitudes': RequestsScreen,
    };
    for (final MapEntry(key: label, value: type) in tabs.entries) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(find.byType(type), findsOneWidget, reason: label);
    }
  });

  testWidgets('agenda job detail by id', (tester) async {
    await pumpRouterAt(tester, '/agenda/job/j1');
    expect(
      tester.widget<AgendaJobScreen>(find.byType(AgendaJobScreen)).jobId,
      'j1',
    );
  });

  testWidgets('availability lives under services', (tester) async {
    await pumpRouterAt(tester, '/services/availability');
    expect(find.byType(AvailabilityScreen), findsOneWidget);
  });

  // One container per test: re-pumping strands the first one's autoDispose timers.
  testWidgets('offer editor: new, full screen', (tester) async {
    await pumpRouterAt(tester, '/services/new');
    expect(
      tester.widget<OfferEditorScreen>(find.byType(OfferEditorScreen)).offerId,
      isNull,
    );
    expect(find.byType(ManoBottomNavBar), findsNothing);
  });

  testWidgets('offer editor: existing, by id', (tester) async {
    await pumpRouterAt(tester, '/services/offer/o1');
    expect(
      tester.widget<OfferEditorScreen>(find.byType(OfferEditorScreen)).offerId,
      'o1',
    );
  });

  testWidgets('chat is full screen', (tester) async {
    await pumpRouterAt(tester, '/inbox/conv-1');
    expect(
      tester.widget<ChatScreen>(find.byType(ChatScreen)).conversationId,
      'conv-1',
    );
    expect(find.byType(ManoBottomNavBar), findsNothing);
  });

  testWidgets('the centre action starts a new offer', (tester) async {
    final c = await pumpRouterAt(tester, '/requests');
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(routerPath(c), '/services/new');
  });
}
