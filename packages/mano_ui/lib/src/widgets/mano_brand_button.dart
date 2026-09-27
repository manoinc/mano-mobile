import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'mano_press_scale.dart';

/// Continue with somebody else's identity provider.
///
/// The mark arrives as a [Widget] rather than an asset path, because this
/// package ships no images and has no business knowing whose logo it is.
class ManoBrandButton extends StatelessWidget {
  const ManoBrandButton({
    required this.label,
    required this.onPressed,
    required this.leading,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  /// The provider's mark, sized by the caller. 18-20px reads best.
  final Widget leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final enabled = onPressed != null;
    final ink = enabled ? scheme.onSurface : ManoColors.faint;

    return ManoPressScale(
      enabled: enabled,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
          backgroundColor: scheme.surface,
          // Not `ManoColors.stone`: that is the light theme's divider, and on a
          // dark ground it comes out near-white.
          side: BorderSide(color: scheme.outlineVariant),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            leading,
            const SizedBox(width: ManoSpacing.sm + ManoSpacing.xs),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(color: ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
