import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';

import '../mock_previews.dart';

/// Slide 1: there are people, and they are rated.
class SlideDiscovery extends StatelessWidget {
  const SlideDiscovery({required this.reveal, super.key});

  /// 0 to 1. Drives the staggered arrival of the rows.
  final double reveal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: ManoSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: ManoSpacing.xl),
          Text(
            'Encuentra a la persona ideal para lo que necesitas hacer.',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: ManoSpacing.xl),
          for (final (index, tasker) in mockTaskers.indexed) ...[
            if (index > 0) const SizedBox(height: ManoSpacing.sm),
            _Arriving(
              progress: ManoMotion.stagger(index, reveal),
              child: ManoPersonRow(
                avatar: ManoInitialsAvatar(initials: tasker.initials),
                name: tasker.name,
                detail: tasker.detail,
                rating: tasker.rating,
                ratingLabel: tasker.ratingLabel,
              ),
            ),
          ],
          const SizedBox(height: ManoSpacing.lg),
        ],
      ),
    );
  }
}

/// Rises and fades a row into place.
class _Arriving extends StatelessWidget {
  const _Arriving({required this.progress, required this.child});

  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: progress.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, (1 - progress) * 12),
        child: child,
      ),
    );
  }
}
