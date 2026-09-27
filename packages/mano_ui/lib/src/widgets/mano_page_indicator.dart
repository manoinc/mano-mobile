import 'package:flutter/material.dart';

import '../theme/mano_motion.dart';
import '../theme/mano_theme.dart';

/// Where you are in a short sequence of slides.
///
/// Lines rather than dots, all the same length: only the colour says which one
/// you are on, which keeps the row from shifting as it changes.
class ManoPageIndicator extends StatelessWidget {
  const ManoPageIndicator({
    required this.count,
    required this.index,
    super.key,
  });

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Paso ${index + 1} de $count',
      container: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: ManoSpacing.xs),
            ExcludeSemantics(
              child: AnimatedContainer(
                duration: ManoMotion.normal,
                curve: ManoMotion.entrance,
                width: 28,
                height: 3,
                decoration: BoxDecoration(
                  color: i == index ? scheme.onSurface : scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(ManoRadius.pill),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
