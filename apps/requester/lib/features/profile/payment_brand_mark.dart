import 'package:flutter/material.dart';
import 'package:mano_session/mano_session.dart';

/// The logo asset for a method, or null when it has none.
String? paymentLogoAsset(PaymentKind kind, String label) =>
    switch ((kind, label)) {
      (PaymentKind.card, 'Mastercard') => 'assets/payments/mastercard.png',
      (PaymentKind.card, 'Visa') => 'assets/payments/visa.png',
      (PaymentKind.card, _) => null,
      (PaymentKind.nequi, _) => 'assets/payments/nequi.png',
      (PaymentKind.pse, _) => 'assets/payments/pse.png',
    };

/// A method's logo in one fixed box, so the row titles line up.
class PaymentBrandMark extends StatelessWidget {
  const PaymentBrandMark(this.method, {super.key});

  final PaymentMethod method;

  @override
  Widget build(BuildContext context) =>
      PaymentLogo(asset: paymentLogoAsset(method.kind, method.label));
}

/// [asset] fitted into the shared logo box; the card icon when null.
class PaymentLogo extends StatelessWidget {
  const PaymentLogo({required this.asset, super.key});

  final String? asset;

  static const double _width = 48;
  static const double _height = 24;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: _width,
    height: _height,
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: asset == null
          ? const Icon(Icons.credit_card)
          : Image.asset(asset!, fit: BoxFit.contain),
    ),
  );
}
