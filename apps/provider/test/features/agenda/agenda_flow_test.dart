import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_provider/main.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/agenda_calendar.dart';
import '../../support/fake_session_repository.dart';
import '../../support/pump_app.dart';

// Host-side twin of integration_test/agenda_flow_test.dart.
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _openFilter(WidgetTester tester, String label) => _tap(
  tester,
  find.descendant(
    of: find.byType(ManoProjectFilterTabs),
    matching: find.text(label),
  ),
);

// The logger prefills from the wall clock, so step down to the minimum first.
Future<void> _setHours(WidgetTester tester, int halfHoursAboveMin) async {
  final minus = find.byKey(const Key('hour-logger-minus'));
  while (tester.widget<IconButton>(minus).onPressed != null) {
    await _tap(tester, minus);
  }
  for (var i = 0; i < halfHoursAboveMin; i++) {
    await _tap(tester, find.byKey(const Key('hour-logger-plus')));
  }
}

void main() {
  testWidgets('a provider works a fixed job and logs hours on an hourly one', (
    tester,
  ) async {
    useTallPhone(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          offlineMarketplaceProvider.overrideWithValue(true),
          manoConfigProvider.overrideWithValue(testConfig),
          sessionRepositoryProvider.overrideWithValue(
            FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
          ),
        ],
        child: const ProviderApp(),
      ),
    );
    await tester.pumpAndSettle();

    await _tap(tester, find.text('Agenda'));
    await selectAgendaDay(tester, DateTime.now().add(const Duration(days: 2)));
    await _tap(tester, find.byKey(const Key('agenda-job-job-1')));
    await _tap(tester, find.text('Iniciar trabajo'));
    await _tap(tester, find.text('Finalizar trabajo'));
    await _tap(tester, find.text('Sí, finalizar'));
    expect(find.widgetWithText(ManoStatusChip, 'Finalizado'), findsOneWidget);

    await tester.tap(
      find.byType(BackButton),
    ); // locale-proof, unlike pageBack()
    await tester.pumpAndSettle();
    await _openFilter(tester, 'En curso');
    await _tap(tester, find.byKey(const Key('agenda-job-job-3')));
    await _tap(tester, find.text('Finalizar trabajo'));
    await _setHours(tester, 4);
    expect(find.text('2,5 h'), findsOneWidget);
    await _tap(tester, find.text('Confirmar'));

    expect(find.widgetWithText(ManoStatusChip, 'Finalizado'), findsOneWidget);
    expect(find.text('2,5 h'), findsOneWidget);
    expect(find.text(r'$112.500'), findsOneWidget);
  });
}
