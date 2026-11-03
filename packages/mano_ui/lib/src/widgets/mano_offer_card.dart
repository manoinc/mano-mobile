import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'mano_press_scale.dart';
import 'mano_price_tag.dart';
import 'mano_rating_badge.dart';

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
    this.ratingLabel,
    this.rated = true,
    this.onProviderTap,
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

  /// Shown under the title, e.g. "4,9 · 32"; null hides it.
  final String? ratingLabel;
  final bool rated;

  /// Tapping the leading and title area, e.g. to open the provider's profile.
  final VoidCallback? onProviderTap;

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
                    Expanded(
                      child: _ProviderArea(
                        onTap: onProviderTap,
                        child: Row(
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
                                  _Byline(
                                    ratingLabel: ratingLabel,
                                    rated: rated,
                                    subtitle: subtitle,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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

// Rating and subtitle on one line, so a rating never makes the card taller.
class _Byline extends StatelessWidget {
  const _Byline({
    required this.ratingLabel,
    required this.rated,
    required this.subtitle,
  });

  final String? ratingLabel;
  final bool rated;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: ManoColors.muted);
    return Row(
      children: [
        if (ratingLabel case final rating?) ...[
          Flexible(
            child: ManoRatingBadge(label: rating, rated: rated),
          ),
          Text('  ·  ', style: style),
        ],
        Flexible(
          child: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}

class _ProviderArea extends StatelessWidget {
  const _ProviderArea({required this.onTap, required this.child});

  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => onTap == null
      ? child
      : InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ManoRadius.card),
          child: child,
        );
}
