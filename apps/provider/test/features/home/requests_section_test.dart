import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/fake_session_repository.dart';
import '../../support/pump_app.dart';

final _pending = _requestFrom(
  const Party(id: 'client-1', displayName: 'Laura Pérez', photoUrl: ''),
);

ServiceRequest _requestFrom(Party client) => ServiceRequest(
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
  client: client,
  provider: const Party(id: 'provider-1', displayName: 'Andrés', photoUrl: ''),
  message: 'Hola',
  status: ServiceRequestStatus.pending,
  createdAt: DateTime(2026, 10, 4),
);

// Fails every answer, to prove the screen surfaces a port's Err.
final class _RefusingRequests implements ServiceRequestRepository {
  _RefusingRequests({ServiceRequest? shown}) : _shown = shown ?? _pending;

  final ServiceRequest _shown;

  @override
  Future<List<ServiceRequest>> mine({ServiceRequestStatus? status}) async => [
    _shown,
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

// A wallet with no coins, to reach the recharge prompt.
final class _BrokeWallet implements WalletRepository {
  @override
  Future<Wallet> wallet() async => const Wallet(balance: 0);

  @override
  Future<List<CoinTransaction>> history() async => const [];

  @override
  Future<List<CoinPack>> packs() async => const [
    CoinPack(id: 'p', coins: 10, priceCop: 20000),
  ];

  @override
  Future<Result<Wallet, DataFailure>> buyPack(String packId) async =>
      const Ok(Wallet(balance: 10));

  @override
  Future<Result<CoinTransaction, DataFailure>> spendForLead(
    String requestId,
    int cost, {
    required String label,
  }) async => Err(InsufficientCoins(needed: cost, available: 0));

  @override
  Future<Result<Wallet, DataFailure>> refundLead(String requestId) async =>
      const Err(DataNotFound());
}

Future<void> _pump(
  WidgetTester tester, {
  List<Override> overrides = const [],
}) => pumpRouterAt(
  tester,
  '/home',
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

Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  for (final dy in [-300.0, 300.0]) {
    for (var i = 0; i < 10 && target.evaluate().isEmpty; i++) {
      await tester.drag(find.byType(Scrollable).first, Offset(0, dy));
      await tester.pumpAndSettle();
    }
  }
}

Future<void> _openTab(WidgetTester tester, String label) async {
  final tab = find.descendant(
    of: find.byType(ManoProjectFilterTabs),
    matching: find.text(label),
  );
  await tester.ensureVisible(tab);
  await tester.pumpAndSettle();
  await tester.tap(tab);
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
    expect(_inCard('request-1', 'Aceptar · 2 coins'), findsOneWidget);
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
    expect(_inCard('request-3', 'Aceptar · 3 coins'), findsNothing);
  });

  testWidgets(
    'accepting moves the request to Respondidas and links the agenda',
    (tester) async {
      final c = await pumpRouterAt(
        tester,
        '/home',
        session: FakeSessionRepository(
          onRestore: () async => Ok(fakeSession()),
        ),
      );

      await _tapInCard(tester, 'request-1', 'Aceptar · 2 coins');

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
    await _tapInCard(tester, 'request-1', 'Aceptar · 2 coins');
    await _openTab(tester, 'Respondidas');
    await _scrollTo(tester, _inCard('request-1', 'Aceptada'));
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
    await _scrollTo(tester, _inCard('request-2', 'Rechazada'));
    expect(_inCard('request-2', 'Rechazada'), findsOneWidget);
    await _tapInCard(tester, 'request-2', 'Camilo Restrepo');
    expect(find.text('Sin cupo'), findsOneWidget);
  });

  testWidgets('tapping a card opens its details with the same actions', (
    tester,
  ) async {
    await _pump(tester);

    await _tapInCard(tester, 'request-2', 'Camilo Restrepo');

    final sheet = find.byKey(const Key('request-detail-sheet'));
    expect(sheet, findsOneWidget);
    expect(
      find.descendant(
        of: sheet,
        matching: find.textContaining('Se me está filtrando el lavaplatos'),
      ),
      findsOneWidget,
    );
    await tester.tap(
      find.descendant(of: sheet, matching: find.text('Aceptar · 3 coins')),
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
      '/home',
      session: FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
    );
    await _tapInCard(tester, 'request-1', 'Laura Pérez');
    await tester.ensureVisible(find.text('Escribir a Laura Pérez'));
    await tester.pumpAndSettle();
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

    await _tapInCard(tester, 'request-1', 'Aceptar · 2 coins');

    expect(find.text(const DataUnavailable().message), findsOneWidget);
    expect(_card('request-1'), findsOneWidget);
  });

  testWidgets('a client without a name yet is shown as Cliente', (
    tester,
  ) async {
    final anonymous = _requestFrom(
      const Party(id: 'client-9', displayName: '', photoUrl: ''),
    );
    await _pump(
      tester,
      overrides: [
        serviceRequestRepositoryProvider.overrideWithValue(
          _RefusingRequests(shown: anonymous),
        ),
      ],
    );

    expect(_inCard('request-1', 'Cliente'), findsOneWidget);
    await tester.tap(_card('request-1'));
    await tester.pumpAndSettle();
    expect(find.text('Escribir a Cliente'), findsOneWidget);
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

  testWidgets('cards show the category, zone, photo and lead cost', (
    tester,
  ) async {
    await _pump(tester);
    expect(_inCard('request-1', 'Limpieza · Chapinero'), findsOneWidget);
    expect(_inCard('request-2', 'Plomería · Laureles'), findsOneWidget);
    expect(
      find.descendant(
        of: _card('request-2'),
        matching: find.byKey(const Key('request-card-photo')),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the detail sheet shows the photo gallery and the cost', (
    tester,
  ) async {
    await _pump(tester);
    await _tapInCard(tester, 'request-2', 'Camilo Restrepo');
    final sheet = find.byKey(const Key('request-detail-sheet'));
    expect(
      find.descendant(of: sheet, matching: find.byType(ManoPhotoGallery)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Plomería · Laureles')),
      findsOneWidget,
    );
  });

  testWidgets('accepting spends the lead cost from the wallet', (tester) async {
    final c = await pumpRouterAt(
      tester,
      '/home',
      session: FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
    );
    await _tapInCard(tester, 'request-2', 'Aceptar · 3 coins');
    expect((await c.read(walletProvider.future)).balance, 22);
    final history = await c.read(walletHistoryProvider.future);
    expect(history.first.requestId, 'request-2');
  });

  testWidgets('without enough coins a sheet leads to recharging', (
    tester,
  ) async {
    await _pump(
      tester,
      overrides: [walletRepositoryProvider.overrideWithValue(_BrokeWallet())],
    );

    await _tapInCard(tester, 'request-2', 'Aceptar · 3 coins');

    expect(find.byKey(const Key('insufficient-coins-sheet')), findsOneWidget);
    expect(find.text('Te faltan 3 coins'), findsOneWidget);
    expect(_card('request-2'), findsOneWidget);
    await tester.tap(find.text('Recargar'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recharge-sheet')), findsOneWidget);
  });
}
