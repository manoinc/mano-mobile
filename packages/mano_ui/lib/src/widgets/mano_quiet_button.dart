import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';

/// The second thing you could do on a screen.
///
/// Deliberately not a second filled button. Flame works because a screen only
/// spends it once; a pair of them leaves nothing to draw the eye. This is type
/// in clay, with a touch target the size of the primary's.
class ManoQuietButton extends StatelessWidget {
  const ManoQuietButton({
    required this.label,
    required this.onPressed,
    this.busy = false,
    super.key,
  });

  final String label;

  /// `null` disables the button.
  final VoidCallback? onPressed;

  /// Ignores taps and dims, without taking the primary's spinner: two spinners
  /// on one screen say less than one.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = !busy && onPressed != null;

    return TextButton(
      onPressed: busy ? null : onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: const StadiumBorder(),
        foregroundColor: ManoColors.clay,
        disabledForegroundColor: ManoColors.faint,
        textStyle: theme.textTheme.labelLarge,
      ),
      child: Opacity(opacity: enabled ? 1 : 0.6, child: Text(label)),
    );
  }
}
