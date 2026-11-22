import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'mano_press_scale.dart';

/// Which ink an outline action takes.
enum ManoOutlineTone { ink, flame }

/// A second action of equal weight to the primary, without the flame fill.
///
/// One hot surface per screen is the rule, so a screen offering two real
/// choices draws the other one as an outline rather than a second fill.
class ManoOutlineButton extends StatelessWidget {
  const ManoOutlineButton({
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.tone = ManoOutlineTone.ink,
    this.leading,
    super.key,
  });

  final String label;

  /// `null` disables the button.
  final VoidCallback? onPressed;

  final bool busy;

  /// [ManoOutlineTone.flame] pairs with a flame primary, e.g. sign in beside sign up.
  final ManoOutlineTone tone;

  /// Leads the label, e.g. [ManoEnvelopeIcon] for "Continuar con correo".
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = switch (tone) {
      ManoOutlineTone.ink => scheme.onSurface,
      ManoOutlineTone.flame => scheme.primary,
    };

    return ManoPressScale(
      enabled: !busy && onPressed != null,
      child: OutlinedButton(
        onPressed: busy ? null : onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
          foregroundColor: foreground,
          textStyle: theme.textTheme.labelLarge,
          side: BorderSide(color: foreground, width: 1.5),
        ),
        child: busy
            ? SizedBox.square(
 dimension: 18,
 child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
 )
            : leading == null
            ? Text(label)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconTheme.merge(
                    data: const IconThemeData(size: 20),
                    child: leading!,
                  ),
                  const SizedBox(width: ManoSpacing.sm),
                  Flexible(child: Text(label)),
                ],
              ),
      ),
    );
  }
}
