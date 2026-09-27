import 'package:flutter/material.dart';

import 'mano_press_scale.dart';

/// A second action of equal weight to the primary, without the flame.
///
/// One hot surface per screen is the rule, so a screen offering two real
/// choices draws the other one as an outline rather than a second fill.
class ManoOutlineButton extends StatelessWidget {
  const ManoOutlineButton({
    required this.label,
    required this.onPressed,
    this.busy = false,
    super.key,
  });

  final String label;

  /// `null` disables the button.
  final VoidCallback? onPressed;

  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ManoPressScale(
      enabled: !busy && onPressed != null,
      child: OutlinedButton(
        onPressed: busy ? null : onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
          foregroundColor: scheme.onSurface,
          textStyle: theme.textTheme.labelLarge,
          side: BorderSide(color: scheme.onSurface, width: 1.5),
        ),
        child: busy
            ? SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.onSurface,
                ),
              )
            : Text(label),
      ),
    );
  }
}
