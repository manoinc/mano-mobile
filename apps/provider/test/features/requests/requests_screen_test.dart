import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/fake_session_repository.dart';
import '../../support/pump_app.dart';

final _pending = ServiceRequest(
  id: 'request-1',
  offer: const ServiceOffer(
    id: 'offer-1',
    jobServiceId: 'service-1',
    offerantId: 'provider-1',
    rateType: RateType.fixed,
    amountCop: 120000,
    zone: 'Chapinero',
    status: OfferStatus.active,
  ),
  serviceTitle: 'Limpieza profunda',
  client: const Party(id: 'client-1', displayName: 'Laura Pérez', photoUrl: ''),
  provider: const Party(id: 'provider-1', displayName: 'Andrés', photoUrl: ''),
  message: 'Hola',
  status: ServiceRequestStatus.pending,
  createdAt: DateTime(2026, 10, 4),
);

// Fails every answer, to prove the screen surfaces a port's Err.
final class _RefusingRequests implements ServiceRequestRepository {
  @override
  Future<List<ServiceRequest>> mine({ServiceRequestStatus? status}) async => [
    _pending,
  ];

  @override
  Future<Result<ServiceRequest, DataFailure>> accept(String id) async =>
      const Err(DataUnavailable());

  @override
  Future<Result<ServiceRequest, DataFailure>> reject(
    String id, {
    String? reason,
  }) async => const Err(DataUnavailable());

  @override
  Future<Result<ServiceRequest, DataFailure>> cancel(String id) =>
      throw UnimplementedError();

  @override
  Future<Result<ServiceRequest, DataFailure>> request(
    String offerId, {
    required String message,
    DateTime? proposedStart,
  }) => throw UnimplementedError();
}

Future<void> _pump(
  WidgetTester tester, {
  List<Override> overrides = const [],
}) => pumpRouterAt(
  tester,
  '/requests',
  session: FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
  overrides: overrides,
);

Finder _card(String id) => find.byKey(Key('request-card-$id'));

Finder _inCard(String id, String text) =>
    find.descendant(of: _card(id), matching: find.text(text));

Future<void> _tapInCard(WidgetTester tester, String id, String text) async {
  await tester.ensureVisible(_inCard(id, text));
  await tester.pumpAndSettle();
  await tester.tap(_inCard(id, text));
  await tester.pumpAndSettle();
}

Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(
      of: find.byType(ManoProjectFilterTabs),
      matching: find.text(label),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists pending requests with accept and reject', (tester) async {
    await _pump(tester);

    expect(find.text('Solicitudes'), findsWidgets);
    expect(_card('request-1'), findsOneWidget);
    expect(_card('request-2'), findsOneWidget);
    expect(_card('request-3'), findsNothing);
    expect(_inCard('request-1', 'Laura Pérez'), findsOneWidget);
    expect(_inCard('request-1', 'Aceptar'), findsOneWidget);
    expect(_inCard('request-1', 'Rechazar'), findsOneWidget);
  });

  testWidgets('Respondidas lists answered requests with their status', (
    tester,
  ) async {
    await _pump(tester);
    await _openTab(tester, 'Respondidas');

    expect(_inCard('request-3', 'Aceptada'), findsOneWidget);
    expect(_inCard('request-4', 'Rechazada'), findsOneWidget);
    expect(_inCard('request-5', 'Cancelada'), findsOneWidget);
    expect(_inCard('request-3', 'Aceptar'), findsNothing);
  });

  testWidgets(
    'accepting moves the request to Respondidas and links the agenda',
    (tester) async {
      final c = await pumpRouterAt(
        tester,
        '/requests',
        session: FakeSessionRepository(
          onRestore: () async => Ok(fakeSession()),
        ),
      );

      await _tapInCard(tester, 'request-1', 'Aceptar');

      expect(
        find.text('Solicitud aceptada · quedó en tu agenda'),
        findsOneWidget,
      );
      expect(_card('request-1'), findsNothing);
      await tester.tap(find.text('Ver agenda'));
      await tester.pumpAndSettle();
      expect(routerPath(c), '/agenda');
    },
  );

  testWidgets('accepted request shows as Aceptada under Respondidas', (
    tester,
  ) async {
    await _pump(tester);
    await _tapInCard(tester, 'request-1', 'Aceptar');
    await _openTab(tester, 'Respondidas');
    expect(_inCard('request-1', 'Aceptada'), findsOneWidget);
  });

  testWidgets('rejecting with a reason moves the request to Respondidas', (
    tester,
  ) async {
    await _pump(tester);

    await _tapInCard(tester, 'request-2', 'Rechazar');
    await tester.enterText(find.byType(TextField), 'Sin cupo');
    await tester.tap(find.text('Rechazar solicitud'));
    await tester.pumpAndSettle();

    expect(find.text('Solicitud rechazada'), findsOneWidget);
    expect(_card('request-2'), findsNothing);
    await _openTab(tester, 'Respondidas');
    expect(_inCard('request-2', 'Rechazada'), findsOneWidget);
    await _tapInCard(tester, 'request-2', 'Laura Pérez');
    expect(find.text('Sin cupo'), findsOneWidget);
  });

  testWidgets('tapping a card opens its details with the same actions', (
    tester,
  ) async {
    await _pump(tester);

    await _tapInCard(tester, 'request-2', 'Laura Pérez');

    final sheet = find.byKey(const Key('request-detail-sheet'));
    expect(sheet, findsOneWidget);
    expect(
      find.descendant(
        of: sheet,
        matching: find.text('Tengo una fuga debajo del lavaplatos.'),
      ),
      findsOneWidget,
    );
    await tester.tap(
      find.descendant(of: sheet, matching: find.text('Aceptar')),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Solicitud aceptada · quedó en tu agenda'),
      findsOneWidget,
    );
    expect(_card('request-2'), findsNothing);
  });

  testWidgets('the detail sheet leads to the inbox to chat first', (
    tester,
  ) async {
    final c = await pumpRouterAt(
      tester,
      '/requests',
      session: FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
    );
    await _tapInCard(tester, 'request-1', 'Laura Pérez');
    await tester.tap(find.text('Escribir a Laura Pérez'));
    await tester.pumpAndSettle();
    expect(routerPath(c), '/inbox');
  });

  testWidgets('a failed answer shows the failure message', (tester) async {
    await _pump(
      tester,
      overrides: [
        serviceRequestRepositoryProvider.overrideWithValue(_RefusingRequests()),
      ],
    );

    await _tapInCard(tester, 'request-1', 'Aceptar');

    expect(find.text(const DataUnavailable().message), findsOneWidget);
    expect(_card('request-1'), findsOneWidget);
  });

  testWidgets('shows the empty state when nothing is pending', (tester) async {
    await _pump(
      tester,
      overrides: [
        myServiceRequestsProvider.overrideWith(
          (ref) async => const <ServiceRequest>[],
        ),
      ],
    );
    expect(find.text('No tienes solicitudes pendientes'), findsOneWidget);
  });

  testWidgets('shows an error with retry when the read fails', (tester) async {
    var fail = true;
    await _pump(
      tester,
      overrides: [
        myServiceRequestsProvider.overrideWith((ref) async {
          if (fail) throw StateError('offline');
          return const <ServiceRequest>[];
        }),
      ],
    );
    expect(find.text('No pudimos cargar tus solicitudes.'), findsOneWidget);

    fail = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('No tienes solicitudes pendientes'), findsOneWidget);
  });
}
