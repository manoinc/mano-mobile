import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';

/// A big centred amount over a numeric keypad, with a "000" key for pesos.
///
/// Holds no number itself: the screen keeps the amount and formats [amountLabel].
class ManoAmountPad extends StatelessWidget {
  const ManoAmountPad({
    required this.amountLabel,
    required this.onDigit,
    required this.onBackspace,
    this.helperText,
    super.key,
  });

  /// Pre-formatted, e.g. "$1.800.000".
  final String amountLabel;

  /// Called with "0" to "9", or "000".
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final String? helperText;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // An amount never truncates; it shrinks to fit instead.
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            amountLabel,
            key: const Key('mano-amount-pad-amount'),
            style: textTheme.displaySmall?.copyWith(
              color: ManoColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: ManoSpacing.xs),
          Text(
            helperText!,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(color: ManoColors.faint),
          ),
        ],
        const SizedBox(height: ManoSpacing.lg),
        for (final row in _rows)
          Row(
            children: [
              for (final key in row)
                Expanded(
                  child: _Key(label: key, onTap: () => onDigit(key)),
                ),
            ],
          ),
        Row(
          children: [
            Expanded(
              child: _Key(label: '000', onTap: () => onDigit('000')),
            ),
            Expanded(
              child: _Key(label: '0', onTap: () => onDigit('0')),
            ),
            Expanded(
              child: SizedBox(
                height: 56,
                child: IconButton(
                  onPressed: onBackspace,
                  tooltip: 'Borrar',
                  icon: const Icon(
                    Icons.backspace_outlined,
                    color: ManoColors.ink,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ManoRadius.card),
      child: SizedBox(
        height: 56,
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(color: ManoColors.ink),
          ),
        ),
      ),
    );
  }
}
