import 'package:flutter/material.dart';

import '../brand/mano_arch_motif.dart';
import '../brand/mano_opening.dart';
import '../brand/mano_wordmark.dart';
import '../theme/mano_theme.dart';

/// The first screen: brand at the top, a claim, and the way in.
///
/// The wordmark sits at [ManoLockup.inset] inside the safe area at
/// [ManoLockup.restingHeight] -- the same numbers [ManoOpening] flies its own
/// copy to, which is what makes the handover invisible. Change one and change
/// both, or the logo will jump at the end of the animation.
class ManoHeroScaffold extends StatelessWidget {
  const ManoHeroScaffold({
    required this.headline,
    required this.actions,
    this.notice,
    this.footnote,
    super.key,
  });

  /// Two or three short lines. The type is large enough that more will not fit
  /// on a small phone, which is the point.
  final String headline;

  /// The way in, e.g. [ManoWelcomeActions].
  final Widget actions;

  /// Built by the screen, because a notice's wording and tone come from a
  /// failure this package cannot see.
  final Widget? notice;

  /// Fine print under the actions.
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ManoArchMotif(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(ManoLockup.inset),
              child: LayoutBuilder(
                // Large text settings plus a small phone can outgrow the
                // screen. Scrolling is the honest answer; shrinking the brand
                // is not.
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: ManoWordmark(
                              height: ManoLockup.restingHeight,
                              color: ManoColors.flame,
                            ),
                          ),
                          const SizedBox(height: 22),
                          // The landing header's signature: a 2px ink rule,
                          // not a shadow.
                          Container(
                            height: 2,
                            color: theme.colorScheme.onSurface,
                          ),

                          const Spacer(),

                          if (notice != null) ...[
                            notice!,
                            const SizedBox(height: ManoSpacing.lg),
                          ],

                          Text(headline, style: theme.textTheme.displaySmall),
                          const SizedBox(height: ManoSpacing.xl),

                          actions,
                          if (footnote != null) ...[
                            const SizedBox(height: ManoSpacing.md),
                            Text(
                              footnote!,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: ManoColors.faint,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
