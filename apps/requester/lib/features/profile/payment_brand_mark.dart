import 'package:flutter/material.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

// Brand stand-ins drawn from tokens until licensed marks ship as assets.

/// A saved method's mark, one fixed width so the row titles line up.
class PaymentBrandMark extends StatelessWidget {
  const PaymentBrandMark(this.method, {super.key});

  final PaymentMethod method;

  static const double _width = 40;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: _width,
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: switch ((method.kind, method.label)) {
        (PaymentKind.card, 'Mastercard') => const _TwoCircles(
          key: Key('mark-mastercard'),
        ),
        (PaymentKind.card, 'Visa') => Text(
          'VISA',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w800,
            color: ManoColors.ink,
          ),
        ),
        (PaymentKind.card, _) => const Icon(Icons.credit_card),
        (PaymentKind.nequi, _) => const Icon(
          Icons.account_balance_wallet_outlined,
        ),
        (PaymentKind.pse, _) => const Icon(Icons.account_balance_outlined),
      },
    ),
  );
}

class _TwoCircles extends StatelessWidget {
  const _TwoCircles({super.key});

  static const double _size = 20;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: _size * 1.6,
    height: _size,
    child: Stack(
      children: [
        _circle(ManoColors.flame),
        Positioned(
          left: _size * 0.6,
          child: _circle(ManoColors.clay.withValues(alpha: 0.85)),
        ),
      ],
    ),
  );

  Widget _circle(Color color) => Container(
    width: _size,
    height: _size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
