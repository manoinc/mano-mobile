import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'mano_press_scale.dart';

/// A coin pack to pick: how many coins, what they cost, and any free bonus.
class ManoPackOption extends StatelessWidget {
  const ManoPackOption({
    required this.coinsLabel,
    required this.priceLabel,
    required this.selected,
    required this.onTap,
    this.bonusLabel,
    super.key,
  });

  final String coinsLabel;
  final String priceLabel;
  final String? bonusLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bonus = bonusLabel;

    return ManoPressScale(
      enabled: true,
      child: Material(
        color: selected ? context.palette.sand : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ManoRadius.card),
          side: BorderSide(
            color: selected ? context.palette.ink : context.palette.stone,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(ManoSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(coinsLabel, style: textTheme.titleMedium),
                      if (bonus != null)
                        Text(
                          bonus,
                          style: textTheme.bodySmall?.copyWith(
                            color: context.palette.clay,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(priceLabel, style: textTheme.titleMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
