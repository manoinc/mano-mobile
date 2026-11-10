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
  // The asset each method shows, by its path.
  String? assetOf(WidgetTester tester) {
    final images = tester.widgetList<Image>(find.byType(Image));
    if (images.isEmpty) return null;
    return (images.single.image as AssetImage).assetName;
  }

  testWidgets('Mastercard, Visa, Nequi and PSE show their real logos', (
    tester,
  ) async {
    for (final (kind, label, asset) in [
      (PaymentKind.card, 'Mastercard', 'assets/payments/mastercard.png'),
      (PaymentKind.card, 'Visa', 'assets/payments/visa.png'),
      (PaymentKind.nequi, 'Nequi', 'assets/payments/nequi.png'),
      (PaymentKind.pse, 'PSE', 'assets/payments/pse.png'),
    ]) {
      await _pump(tester, _method(kind, label));
      expect(assetOf(tester), asset, reason: label);
    }
  });

  testWidgets('a card without a logo takes the card icon', (tester) async {
    await _pump(tester, _method(PaymentKind.card, 'Amex'));

    expect(find.byIcon(Icons.credit_card), findsOneWidget);
    expect(assetOf(tester), isNull);
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
