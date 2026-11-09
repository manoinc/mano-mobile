import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_requester/features/profile/payment_brand_mark.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

PaymentMethod _method(PaymentKind kind, String label) =>
    PaymentMethod(id: 'm', kind: kind, label: label, last4: '0000');

Future<void> _pump(WidgetTester tester, PaymentMethod method) =>
    tester.pumpWidget(
      MaterialApp(
        theme: ManoTheme.light(),
        home: Scaffold(body: Center(child: PaymentBrandMark(method))),
      ),
    );

void main() {
  testWidgets('Mastercard is two overlapping circles', (tester) async {
    await _pump(tester, _method(PaymentKind.card, 'Mastercard'));

    expect(find.byKey(const Key('mark-mastercard')), findsOneWidget);
  });

  testWidgets('Visa is its wordmark', (tester) async {
    await _pump(tester, _method(PaymentKind.card, 'Visa'));

    expect(find.text('VISA'), findsOneWidget);
  });

  testWidgets('other cards, Nequi and PSE take an icon', (tester) async {
    await _pump(tester, _method(PaymentKind.card, 'Amex'));
    expect(find.byIcon(Icons.credit_card), findsOneWidget);

    await _pump(tester, _method(PaymentKind.nequi, 'Nequi'));
    expect(find.byIcon(Icons.account_balance_wallet_outlined), findsOneWidget);

    await _pump(tester, _method(PaymentKind.pse, 'PSE'));
    expect(find.byIcon(Icons.account_balance_outlined), findsOneWidget);
  });

  testWidgets('every mark takes the same width so titles line up', (
    tester,
  ) async {
    await _pump(tester, _method(PaymentKind.card, 'Mastercard'));
    final card = tester.getSize(find.byType(PaymentBrandMark)).width;
    await _pump(tester, _method(PaymentKind.nequi, 'Nequi'));

    expect(tester.getSize(find.byType(PaymentBrandMark)).width, card);
  });
}
