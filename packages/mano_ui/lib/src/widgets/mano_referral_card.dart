import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'mano_press_scale.dart';

/// An invitation to refer a colleague: a dark card, a coin when a reward runs, and how it is going.
///
/// The motif is shapes and icons only (overlapping circles plus a flame coin).
class ManoReferralCard extends StatelessWidget {
  const ManoReferralCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.coinLabel,
    this.detail,
    super.key,
  });

  final String title;
  final String subtitle;

  /// The number on the coin, e.g. "10"; no coin without a reward.
  final String? coinLabel;
  final VoidCallback onTap;

  /// A line under the copy, e.g. "3 colegas invitados · 2 verificados".
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final line = detail;

    return ManoPressScale(
      enabled: true,
      child: Material(
        color: context.palette.ink,
        borderRadius: BorderRadius.circular(ManoRadius.card),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ManoRadius.card),
          child: Padding(
            padding: const EdgeInsets.all(ManoSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: text.titleLarge?.copyWith(
                              color: context.palette.paper,
                            ),
                          ),
                          const SizedBox(height: ManoSpacing.xs),
                          Text(
                            subtitle,
                            style: text.bodyMedium?.copyWith(
                              color: context.palette.faint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: ManoSpacing.md),
                    _Motif(coinLabel: coinLabel),
                  ],
                ),
                if (line != null) ...[
                  const SizedBox(height: ManoSpacing.sm),
                  Text(
                    line,
                    style: text.bodySmall?.copyWith(
                      color: context.palette.faint,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Motif extends StatelessWidget {
  const _Motif({required this.coinLabel});

  final String? coinLabel;

  Widget _circle(
    BuildContext context,
    Color color,
    IconData icon,
    Color iconColor,
  ) => Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: context.palette.ink, width: 2),
    ),
    child: Icon(icon, size: 20, color: iconColor),
  );

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: 84,
        height: 56,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 10,
              child: _circle(
                context,
                context.palette.stone,
                Icons.person,
                context.palette.faint,
              ),
            ),
            Positioned(
              left: 22,
              top: 10,
              child: _circle(
                context,
                context.palette.clay,
                Icons.person,
                context.palette.sand,
              ),
            ),
            if (coinLabel case final coin?)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: ManoColors.flame,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    coin,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
