import 'package:flutter/material.dart';

/// A payment brand's [logo] in one fixed box, so method rows line up; the app supplies the image.
class ManoPaymentLogo extends StatelessWidget {
  const ManoPaymentLogo({
    this.logo,
    this.fallback = const Icon(Icons.credit_card),
    super.key,
  });

  /// Usually an `Image.asset` from the app's `assets/payments/`.
  final Widget? logo;

  /// Shown when the method has no logo, e.g. an unknown card brand.
  final Widget fallback;

  static const Size box = Size(48, 24);

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(
    size: box,
    child: logo == null
        ? Align(alignment: AlignmentDirectional.centerStart, child: fallback)
        : FittedBox(alignment: AlignmentDirectional.centerStart, child: logo),
  );
}
