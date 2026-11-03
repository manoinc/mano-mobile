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

  testWidgets('Cómo funciona explains the cost per category', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Cómo funciona'));
    await tester.pumpAndSettle();
    expect(find.text('Plomería'), findsOneWidget);
    expect(find.text('3 coins'), findsWidgets);
  });
}
