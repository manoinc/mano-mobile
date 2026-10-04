import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'mano_press_scale.dart';
import 'mano_price_tag.dart';

/// One priced offer: who or what, its pricing model, its zone and its price.
class ManoOfferCard extends StatelessWidget {
  const ManoOfferCard({
    required this.title,
    required this.subtitle,
    required this.amountLabel,
    required this.rateLabel,
    required this.zone,
    this.leading,
    this.status,
    this.trailing,
    this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final String amountLabel;
  final String rateLabel;
  final String zone;
  final Widget? leading;
  final Widget? status;

  // Sits beside the price; meant for a quiet action, never a flame button.
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(ManoRadius.card);

    return ManoPressScale(
      enabled: onTap != null,
      child: Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(ManoSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (leading case final leading?) ...[
                      leading,
                      const SizedBox(width: ManoSpacing.md),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: ManoColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (status case final status?) ...[
                      const SizedBox(width: ManoSpacing.sm),
                      status,
                    ],
                  ],
                ),
                const SizedBox(height: ManoSpacing.md),
                Row(
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 15,
                      color: ManoColors.faint,
                    ),
                    const SizedBox(width: ManoSpacing.xs),
                    Expanded(
                      child: Text(
                        zone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: ManoColors.faint,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: ManoSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ManoPriceTag(
                          amountLabel: amountLabel,
                          rateLabel: rateLabel,
                        ),
                      ),
                    ),
                    ?trailing,
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
