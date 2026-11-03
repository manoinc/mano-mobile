import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_provider/features/wallet/wallet_labels.dart';
import 'package:mano_session/mano_session.dart';

import '../../support/fake_session_repository.dart';
import '../../support/pump_app.dart';

Future<void> _pump(WidgetTester tester) => pumpRouterAt(
  tester,
  '/wallet',
  session: FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
);

void main() {
  test('coinsLabel pluralises', () {
    expect(coinsLabel(1), '1 coin');
    expect(coinsLabel(3), '3 coins');
  });

  testWidgets('shows the balance hero and both actions', (tester) async {
    await _pump(tester);
    expect(find.text('25'), findsOneWidget);
    expect(find.text('Mano coins'), findsOneWidget);
    expect(find.text('Recargar'), findsOneWidget);
    expect(find.text('Cómo funciona'), findsOneWidget);
  });

  testWidgets('lists activity grouped by period, with the referral bonus', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('Actividad'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Bono por referir a Carlos'),
      200,
    );
    expect(find.text('Bono por referir a Carlos'), findsOneWidget);
    expect(find.text('+5'), findsOneWidget);
    expect(find.text('-3'), findsWidgets);
  });

  testWidgets('recharging a pack adds its coins and logs the purchase', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('Recargar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('25 coins'));
    await tester.pumpAndSettle();
    final pay = find.text('Pagar con Nequi · \$45.000');
    expect(
      tester
          .widget<ManoPrimaryButton>(
            find.ancestor(of: pay, matching: find.byType(ManoPrimaryButton)),
          )
          .onPressed,
      isNull,
      reason: 'it waits for the phone, email and terms',
    );

    await tester.enterText(
      find.byKey(const Key('recharge-phone')).last,
      '3001234567',
    );
    await tester.enterText(
      find.byKey(const Key('recharge-email')).last,
      'ana@example.co',
    );
    await tester.ensureVisible(find.byKey(const Key('recharge-terms')));
    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(pay);
    await tester.tap(pay);
    await tester.pumpAndSettle();

    expect(find.text('Listo: sumaste 28 coins'), findsOneWidget);
    expect(find.text('53'), findsOneWidget);
    expect(find.text('Recarga de 28 coins'), findsOneWidget);
  });

  testWidgets('Cómo funciona explains the cost per category', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Cómo funciona'));
    await tester.pumpAndSettle();
    expect(find.text('Plomería'), findsOneWidget);
    expect(find.text('3 coins'), findsWidgets);
  });
}
