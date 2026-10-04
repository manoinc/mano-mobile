import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mano_requester/main.dart';
import 'package:mano_requester/shell/app_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../test/features/booking/booking_fakes.dart';
import '../test/support/fake_session_repository.dart';
import '../test/support/pump_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a signed-in requester books the first open slot', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          manoConfigProvider.overrideWithValue(testConfig),
          sessionRepositoryProvider.overrideWithValue(
            FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
          ),
          serviceCatalogProvider.overrideWithValue(FakeServiceCatalog()),
        ],
        child: const RequesterApp(),
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp).first),
    );

    container.read(requesterRouterProvider).go('/home/book/offer-1');
    await tester.pumpAndSettle();

    // Mock availability works for any worker; find the first day it opens.
    final booking = container.read(bookingProvider('offer-1'));
    final slots = await container.read(
      availableSlotsProvider((
        workerId: 'provider-1',
        from: booking.range.from,
        to: booking.range.to,
      )).future,
    );
    final open = slots.firstWhere((s) => s.bookable);

    final day = find.descendant(
      of: find.byType(ManoDateStrip),
      matching: find.text('${open.start.day}'),
    );
    await tester.ensureVisible(day);
    await tester.tap(day);
    await tester.pumpAndSettle();
    await tester.tap(find.text(ManoFormat.time(open.start)));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ManoPrimaryButton, 'Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ManoPrimaryButton, 'Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('¡Listo! Tu cita quedó agendada'), findsOneWidget);
    final mine = await container.read(jobRepositoryProvider).mine();
    expect(
      mine.any((j) => j.offerId == 'offer-1' && j.start == open.start),
      isTrue,
    );
  });
}
