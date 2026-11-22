import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'mano_press_scale.dart';

/// Which fill the main action takes.
enum ManoPrimaryTone { flame, ink }

/// The main action on a screen.
///
/// Takes a label, a callback and a flag — nothing else. It has no idea what
/// signing in means, cannot reach application state, and could not render a
/// `Session` if it wanted to, because `mano_ui` does not depend on the domain.
///
/// That is what makes it reusable in both apps and testable by handing it
/// three values.
class ManoPrimaryButton extends StatelessWidget {
  const ManoPrimaryButton({
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.tone = ManoPrimaryTone.flame,
    this.compact = false,
    super.key,
  });

  final String label;

  /// `null` disables the button.
  final VoidCallback? onPressed;

  /// Shows a spinner and ignores taps. Separate from a null [onPressed] so a
  /// screen can distinguish "working" from "not available".
  final bool busy;

  /// [ManoPrimaryTone.ink] for a main action that is not the screen's hot one, e.g. adding a method.
  final ManoPrimaryTone tone;

  /// Hugs its label at the start instead of filling the width.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ink = tone == ManoPrimaryTone.ink;
    final foreground = ink ? scheme.surface : scheme.onPrimary;

    final button = ManoPressScale(
      enabled: !busy && onPressed != null,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: ink ? scheme.onSurface : null,
          foregroundColor: ink ? foreground : null,
          minimumSize: compact ? const Size(0, 52) : null,
          padding: compact
              ? const EdgeInsets.symmetric(horizontal: ManoSpacing.lg)
              : null,
        ),
        child: busy ? SizedBox.square(
 dimension: 18,
 child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
 ) : Text(label),
      ),
    );
    if (!compact) return button;
    return Align(alignment: AlignmentDirectional.centerStart, child: button);
  }
}
