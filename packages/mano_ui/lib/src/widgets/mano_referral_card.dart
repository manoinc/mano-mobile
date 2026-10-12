import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'mano_press_scale.dart';

/// An invitation to refer a colleague: a dark card, a coin and a progress bar.
///
/// The motif is shapes and icons only (overlapping circles plus a flame coin).
class ManoReferralCard extends StatelessWidget {
  const ManoReferralCard({
    required this.title,
    required this.subtitle,
    required this.coinLabel,
    required this.onTap,
    this.progressLabel,
    this.progress,
    super.key,
  });

  final String title;
  final String subtitle;

  /// The number on the coin, e.g. "10".
  final String coinLabel;
  final VoidCallback onTap;

  /// Shown with [progress] (0..1) when both are given.
  final String? progressLabel;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final label = progressLabel;
    final fraction = progress;

    return ManoPressScale(
      enabled: true,
      child: Material(
        color: ManoColors.ink,
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
                              color: ManoColors.sand,
                            ),
                          ),
                          const SizedBox(height: ManoSpacing.xs),
                          Text(
                            subtitle,
                            style: text.bodyMedium?.copyWith(
                              color: ManoColors.faint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: ManoSpacing.md),
                    _Motif(coinLabel: coinLabel),
                  ],
                ),
                if (label != null && fraction != null) ...[
                  const SizedBox(height: ManoSpacing.md),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(ManoRadius.pill),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 6,
                      color: ManoColors.flame,
                      backgroundColor: ManoColors.muted,
                    ),
                  ),
                  const SizedBox(height: ManoSpacing.xs),
                  Text(
                    label,
                    style: text.bodySmall?.copyWith(color: ManoColors.faint),
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

  final String coinLabel;

  Widget _circle(Color color, IconData icon, Color iconColor) => Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: ManoColors.ink, width: 2),
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
              child: _circle(ManoColors.stone, Icons.person, ManoColors.faint),
            ),
            Positioned(
              left: 22,
              top: 10,
              child: _circle(ManoColors.clay, Icons.person, ManoColors.sand),
            ),
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
                  coinLabel,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(color: ManoColors.sand),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
