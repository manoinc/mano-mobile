import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_requester/shell/app_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/fake_session_repository.dart';
import '../../support/pump_app.dart';
import 'booking_fakes.dart';

List<Override> _overrides({
  bool signedIn = true,
  ServiceCatalog? catalog,
  JobRepository? jobs,
}) => [
  manoConfigProvider.overrideWithValue(testConfig),
  serviceCatalogProvider.overrideWithValue(catalog ?? FakeServiceCatalog()),
  availabilityRepositoryProvider.overrideWithValue(FakeAvailability()),
  // Jobs and requests keep their in-memory mock defaults unless replaced.
  if (jobs != null) jobRepositoryProvider.overrideWithValue(jobs),
  sessionRepositoryProvider.overrideWithValue(
    FakeSessionRepository(
      onRestore: () async => Ok(signedIn ? fakeSession() : null),
    ),
  ),
];

// Like pumpRouterAt, which fixes a signed-out session, but lets the session vary.
Future<ProviderContainer> _pumpAt(
  WidgetTester tester,
  String location, {
  required List<Override> overrides,
}) async {
  final container = ProviderContainer.test(overrides: overrides);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (context, ref, _) => MaterialApp.router(
          theme: ManoTheme.light(),
          routerConfig: ref.watch(requesterRouterProvider),
        ),
      ),
    ),
  );
  await container.read(sessionProvider.future);
  container.read(requesterRouterProvider).go(location);
  await tester.pumpAndSettle();
  return container;
}

Future<void> _pickOpenSlot(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(ManoDateStrip),
      matching: find.text('${FakeAvailability.tomorrow.day}'),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(ManoFormat.time(FakeAvailability.openSlot)));
  await tester.pumpAndSettle();
}

Finder _primary(String label) => find.widgetWithText(ManoPrimaryButton, label);

void main() {
  testWidgets('summarises the service and its fixed price', (tester) async {
    await _pumpAt(tester, '/home/book/offer-1', overrides: _overrides());

    expect(find.text('Limpieza profunda'), findsOneWidget);
    expect(find.text(ManoFormat.cop(120000)), findsOneWidget);
    expect(find.text('precio fijo'), findsOneWidget);
    expect(find.textContaining('horas trabajadas'), findsNothing);
  });

  testWidgets('an hourly offer says the final price depends on hours', (
    tester,
  ) async {
    final hourly = fakeOffer.copyWith(rateType: RateType.hourly);
    await _pumpAt(
      tester,
      '/home/book/offer-1',
      overrides: _overrides(catalog: FakeServiceCatalog(offers: [hourly])),
    );

    expect(find.text('/hora'), findsOneWidget);
    expect(find.textContaining('horas trabajadas'), findsOneWidget);
  });

  testWidgets('days without bookable slots are disabled', (tester) async {
    await _pumpAt(tester, '/home/book/offer-1', overrides: _overrides());

    final strip = tester.widget<ManoDateStrip>(find.byType(ManoDateStrip));
    expect(strip.days, hasLength(14));
    expect(strip.isEnabled!(FakeAvailability.tomorrow), isTrue);
    expect(
      strip.isEnabled!(FakeAvailability.tomorrow.add(const Duration(days: 1))),
      isFalse,
    );
  });

  testWidgets('the selected day shows its slots, taken ones disabled', (
    tester,
  ) async {
    await _pumpAt(tester, '/home/book/offer-1', overrides: _overrides());
    await _pickOpenSlot(tester);

    final grid = tester.widget<ManoSlotGrid>(find.byType(ManoSlotGrid));
    expect(grid.slots.map((s) => s.enabled), [true, false]);
    expect(grid.slots.last.label, ManoFormat.time(FakeAvailability.takenSlot));
    expect(grid.selectedIndex, 0);
  });

  testWidgets('Continuar waits for a slot', (tester) async {
    await _pumpAt(tester, '/home/book/offer-1', overrides: _overrides());

    final button = tester.widget<ManoPrimaryButton>(_primary('Continuar'));
    expect(button.onPressed, isNull);
  });

  testWidgets('confirming books the slot and shows success', (tester) async {
    final container = await _pumpAt(
      tester,
      '/home/book/offer-1',
      overrides: _overrides(),
    );
    await _pickOpenSlot(tester);

    await tester.tap(_primary('Continuar'));
    await tester.pumpAndSettle();
    expect(
      find.text(ManoFormat.dateTime(FakeAvailability.openSlot)),
      findsOneWidget,
    );
    await tester.tap(_primary('Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('¡Listo! Tu cita quedó agendada'), findsOneWidget);
    final jobs = await container.read(myJobsProvider.future);
    expect(jobs.first.start, FakeAvailability.openSlot);

    await tester.tap(find.text('Ver en Actividad'));
    await tester.pumpAndSettle();
    expect(routerPath(container), '/projects');
  });

  testWidgets('a failed booking shows why and keeps the selection', (
    tester,
  ) async {
    await _pumpAt(
      tester,
      '/home/book/offer-1',
      overrides: _overrides(jobs: FailingJobs()),
    );
    await _pickOpenSlot(tester);
    await tester.tap(_primary('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(_primary('Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text(const DataUnavailable().message), findsOneWidget);
    expect(
      tester.widget<ManoSlotGrid>(find.byType(ManoSlotGrid)).selectedIndex,
      0,
    );
  });

  testWidgets('a guest is asked to sign in instead', (tester) async {
    final container = await _pumpAt(
      tester,
      '/home/book/offer-1',
      overrides: _overrides(signedIn: false),
    );
    await _pickOpenSlot(tester);
    await tester.tap(_primary('Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Confirmar'), findsNothing);
    await tester.tap(_primary('Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(container.read(onboardingFlowProvider), isA<OnboardingSignIn>());
  });

  testWidgets('proposing another time sends a request', (tester) async {
    final container = await _pumpAt(
      tester,
      '/home/book/offer-1',
      overrides: _overrides(),
    );
    final before = await container.read(myServiceRequestsProvider.future);

    await tester.tap(find.text('Proponer otro horario'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '¿Puede ser el sábado?');
    await tester.tap(
      find.descendant(
        of: find.byType(ManoDateStrip),
        matching: find.text('${FakeAvailability.tomorrow.day}'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(ManoFormat.time(FakeAvailability.openSlot)));
    await tester.pumpAndSettle();
    await tester.tap(_primary('Enviar solicitud'));
    await tester.pumpAndSettle();

    expect(find.text('Solicitud enviada'), findsOneWidget);
    final after = await container.read(myServiceRequestsProvider.future);
    expect(after.length, before.length + 1);
    expect(after.first.proposedStart, FakeAvailability.openSlot);
    expect(after.first.message, '¿Puede ser el sábado?');
  });

  testWidgets('a missing offer says so', (tester) async {
    await _pumpAt(tester, '/home/book/nope', overrides: _overrides());

    expect(find.text('Esta oferta ya no está disponible.'), findsOneWidget);
  });
}
