import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';

/// A big centred balance, Cash App style: the number, its unit, then actions.
class ManoBalanceHero extends StatelessWidget {
  const ManoBalanceHero({
    required this.amount,
    required this.unit,
    this.note,
    this.actions,
    super.key,
  });

  final String amount;
  final String unit;

  /// A quiet line under the unit, e.g. the peso equivalent.
  final String? note;

  /// Sits under the balance, e.g. the recharge and how-it-works buttons.
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final note = this.note;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ManoSpacing.lg),
      child: Column(
        children: [
          // Scales down rather than wrapping at large text sizes.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              amount,
              style: textTheme.displayLarge?.copyWith(fontSize: 96),
            ),
          ),
          const SizedBox(height: ManoSpacing.xs),
          Text(
            unit,
            style: textTheme.titleMedium?.copyWith(
              color: context.palette.muted,
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: ManoSpacing.xs),
            Text(
              note,
              style: textTheme.bodyMedium?.copyWith(
                color: context.palette.faint,
              ),
            ),
          ],
          if (actions != null) ...[
            const SizedBox(height: ManoSpacing.lg),
            actions!,
          ],
        ],
      ),
    );
  }
}
