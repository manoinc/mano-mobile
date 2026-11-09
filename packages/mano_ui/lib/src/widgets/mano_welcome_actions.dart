import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'mano_primary_button.dart';

/// Two equal flame pills side by side, then [below]; the one-flame rule's exception (docs/brand/colour.md).
class ManoWelcomeActions extends StatelessWidget {
  const ManoWelcomeActions({
    required this.firstLabel,
    required this.onFirst,
    required this.secondLabel,
    required this.onSecond,
    this.below,
    this.busy = false,
    super.key,
  });

  final String firstLabel;
  final VoidCallback? onFirst;
  final String secondLabel;
  final VoidCallback? onSecond;

  /// Usually the platform sign-in button.
  final Widget? below;

  /// Holds both pills while something is in flight.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: ManoPrimaryButton(
                label: firstLabel,
                onPressed: busy ? null : onFirst,
              ),
            ),
            const SizedBox(width: ManoSpacing.sm),
            Expanded(
              child: ManoPrimaryButton(
                label: secondLabel,
                onPressed: busy ? null : onSecond,
              ),
            ),
          ],
        ),
        if (below case final below?) ...[
          const SizedBox(height: ManoSpacing.sm),
          below,
        ],
      ],
    );
  }
}
