import 'package:flutter/material.dart';

import '../theme/mano_motion.dart';
import '../theme/mano_theme.dart';
import 'mano_emphasis_text.dart';
import 'mano_primary_button.dart';
import 'mano_text_action.dart';

/// One question in a sequence of them.
///
/// A way back in the top-left, an optional way out in the top-right, the
/// question, the fields, and one action pinned to the bottom. The body scrolls
/// and the action rides above the keyboard, so nothing is ever unreachable.
class ManoStepScaffold extends StatelessWidget {
  const ManoStepScaffold({
    required this.headline,
    required this.primaryLabel,
    required this.onPrimary,
    required this.children,
    this.onBack,
    this.trailingLabel,
    this.onTrailing,
    this.headlineEmphasis,
    this.subhead,
    this.busy = false,
    this.progress,
    super.key,
  });

  /// Omitted entirely when null, for the first step.
  final VoidCallback? onBack;

  /// A quiet way to leave the whole flow. Both halves or neither.
  final String? trailingLabel;
  final VoidCallback? onTrailing;

  final String headline;

  /// A fragment of [headline] painted in the accent.
  final String? headlineEmphasis;
  final String? subhead;

  /// The fields. Laid out in a stretched column, so they size themselves.
  final List<Widget> children;

  final String primaryLabel;

  /// `null` holds the action shut until the step can be answered.
  final VoidCallback? onPrimary;

  final bool busy;

  /// A thin bar under the top row, 0 to 1; none when null.
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasTrailing = trailingLabel != null && onTrailing != null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  if (onBack != null)
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      iconSize: 20,
                      tooltip: 'Atrás',
                    )
                  else
                    const SizedBox(width: ManoSpacing.lg),
                  const Spacer(),
                  if (hasTrailing)
                    Padding(
                      padding: const EdgeInsets.only(right: ManoSpacing.sm),
                      child: ManoTextAction(
                        label: trailingLabel!,
                        onPressed: onTrailing,
                      ),
                    ),
                ],
              ),
            ),
            if (progress != null) _ProgressBar(value: progress!),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  ManoSpacing.lg,
                  ManoSpacing.sm,
                  ManoSpacing.lg,
                  ManoSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ManoEmphasisText(
                      headline,
                      emphasis: headlineEmphasis,
                      style: theme.textTheme.headlineLarge,
                    ),
                    if (subhead != null) ...[
                      const SizedBox(height: ManoSpacing.sm),
                      Text(
                        subhead!,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: context.palette.muted,
                        ),
                      ),
                    ],
                    const SizedBox(height: ManoSpacing.xl),
                    ...children,
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ManoSpacing.lg,
                0,
                ManoSpacing.lg,
                ManoSpacing.md,
              ),
              child: ManoPrimaryButton(
                label: primaryLabel,
                busy: busy,
                onPressed: onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ManoSpacing.lg),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value),
        duration: still ? Duration.zero : ManoMotion.normal,
        curve: ManoMotion.entrance,
        builder: (context, v, _) => LinearProgressIndicator(
          value: v,
          minHeight: 3,
          borderRadius: BorderRadius.circular(ManoRadius.pill),
          color: ManoColors.flame,
          backgroundColor: context.palette.stone,
        ),
      ),
    );
  }
}
