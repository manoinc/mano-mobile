import 'package:flutter/material.dart';

import '../theme/mano_motion.dart';
import '../theme/mano_theme.dart';
import '../brand/mano_loader.dart';

/// How a [ManoPaymentStatus] reads: still going, through, or refused.
enum ManoPaymentTone { waiting, done, failed }

/// Where a payment stands, Wise-style: a mark, a plain headline, and what happens next.
class ManoPaymentStatus extends StatelessWidget {
  const ManoPaymentStatus({
    required this.icon,
    required this.title,
    required this.message,
    this.tone = ManoPaymentTone.waiting,
    this.waitingLabel,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final ManoPaymentTone tone;

  /// A small live line under the message while [tone] is waiting, e.g. "Esperando a Nequi…".
  final String? waitingLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mark = switch (tone) {
      ManoPaymentTone.waiting => ManoColors.clay,
      ManoPaymentTone.done => ManoColors.ink,
      ManoPaymentTone.failed => theme.colorScheme.error,
    };
    final waiting = waitingLabel;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: ManoMotion.sheet,
      curve: ManoMotion.entrance,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, ManoSpacing.md * (1 - t)),
          child: child,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: ManoColors.sand,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: mark, size: 28),
          ),
          const SizedBox(height: ManoSpacing.lg),
          Text(title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: ManoSpacing.sm),
          Text(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(color: ManoColors.muted),
          ),
          if (tone == ManoPaymentTone.waiting && waiting != null) ...[
            const SizedBox(height: ManoSpacing.lg),
            Row(
              children: [
                const ManoLoader(height: 14, color: ManoColors.clay),
                const SizedBox(width: ManoSpacing.sm),
                Flexible(
                  child: Text(
                    waiting,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: ManoColors.faint,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
