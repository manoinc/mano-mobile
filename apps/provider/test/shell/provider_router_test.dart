import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_provider/features/agenda/agenda_job_screen.dart';
import 'package:mano_provider/features/agenda/agenda_screen.dart';
import 'package:mano_provider/features/availability/availability_screen.dart';
import 'package:mano_provider/features/chat/chat_screen.dart';
import 'package:mano_provider/features/chat/provider_inbox_screen.dart';
import 'package:mano_provider/features/wallet/wallet_screen.dart';
import 'package:mano_provider/features/home/provider_home_screen.dart';
import 'package:mano_provider/features/services/offer_editor_screen.dart';
import 'package:mano_provider/shell/module_placeholder.dart';
import 'package:mano_provider/shell/provider_nav_shell.dart';
import 'package:mano_ui/mano_ui.dart';

import '../support/pump_app.dart';

void main() {
  testWidgets('opens onto Inicio inside the shell', (tester) async {
    final c = await pumpRouterAt(tester, '/home');
    expect(routerPath(c), '/home');
    expect(find.byType(ProviderNavShell), findsOneWidget);
    expect(find.byType(ProviderHomeScreen), findsOneWidget);
  });

  testWidgets('the old requests link lands on Inicio', (tester) async {
    final c = await pumpRouterAt(tester, '/requests');
    expect(routerPath(c), '/home');
    expect(find.byType(ProviderHomeScreen), findsOneWidget);
  });

  testWidgets('each tab shows its module', (tester) async {
    await pumpRouterAt(tester, '/agenda');
    final tabs = {
      'Bandeja': ProviderInboxScreen,
      'Billetera': WalletScreen,
      'Perfil': ModulePlaceholder,
      'Inicio': ProviderHomeScreen,
      'Agenda': AgendaScreen,
    };
    for (final MapEntry(key: label, value: type) in tabs.entries) {
      await tester.tap(
        find.descendant(
          of: find.byType(ManoBottomNavBar),
          matching: find.text(label),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(type), findsWidgets, reason: label);
    }
  });

  testWidgets('agenda job detail by id', (tester) async {
    await pumpRouterAt(tester, '/agenda/job/j1');
    expect(
      tester.widget<AgendaJobScreen>(find.byType(AgendaJobScreen)).jobId,
      'j1',
    );
  });

  testWidgets('availability lives under agenda', (tester) async {
    await pumpRouterAt(tester, '/agenda/availability');
    expect(find.byType(AvailabilityScreen), findsOneWidget);
  });

  // One container per test: re-pumping strands the first one's autoDispose timers.
  testWidgets('offer editor: new, full screen', (tester) async {
    await pumpRouterAt(tester, '/profile/services/new');
    expect(
      tester.widget<OfferEditorScreen>(find.byType(OfferEditorScreen)).offerId,
      isNull,
    );
    expect(find.byType(ManoBottomNavBar), findsNothing);
  });

  testWidgets('offer editor: existing, by id', (tester) async {
    await pumpRouterAt(tester, '/profile/services/offer/o1');
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

  testWidgets('old services links land under Perfil', (tester) async {
    final c = await pumpRouterAt(tester, '/services/offer/o1');
    expect(routerPath(c), '/profile/services/offer/o1');
  });

  testWidgets('the bar has no centre action', (tester) async {
    await pumpRouterAt(tester, '/home');
    expect(find.byIcon(Icons.add), findsNothing);
  });
}
