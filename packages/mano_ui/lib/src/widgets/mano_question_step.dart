import 'package:flutter/material.dart';

import 'mano_step_scaffold.dart';

/// One question per screen: progress, a big title, a single input, one action.
///
/// Knows nothing about what is asked; the screen supplies the [child] and
/// decides when [onPrimary] opens.
class ManoQuestionStep extends StatelessWidget {
  const ManoQuestionStep({
    required this.title,
    required this.progress,
    required this.child,
    required this.primaryLabel,
    required this.onPrimary,
    this.subtitle,
    this.onBack,
    this.onSkip,
    this.skipLabel = 'Omitir',
    this.busy = false,
    super.key,
  });

  final String title;
  final String? subtitle;

  /// How far through the questions, 0 to 1.
  final double progress;

  /// The one input, or one tightly related choice.
  final Widget child;

  final String primaryLabel;

  /// `null` holds the action shut until the answer is valid.
  final VoidCallback? onPrimary;

  final VoidCallback? onBack;

  /// Shown only for optional questions.
  final VoidCallback? onSkip;
  final String skipLabel;
  final bool busy;

  @override
  Widget build(BuildContext context) => ManoStepScaffold(
    headline: title,
    subhead: subtitle,
    progress: progress,
    primaryLabel: primaryLabel,
    onPrimary: onPrimary,
    onBack: onBack,
    trailingLabel: onSkip == null ? null : skipLabel,
    onTrailing: onSkip,
    busy: busy,
    children: [child],
  );
}
