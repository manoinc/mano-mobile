import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';

/// How prominently a [ManoNotice] should read.
///
/// Note this is a *presentational* distinction, not a domain one. The screen
/// decides that an expired session reads as a warning; the widget only knows
/// how a warning looks.
enum ManoNoticeTone { info, warning, error }

/// A short message about what just happened.
///
/// Takes a string. Deliberately not an `AuthFailure` — `mano_ui` cannot see
/// the domain, so mapping a failure to words happens in the screen, where the
/// wording can differ between the two apps if it should.
class ManoNotice extends StatelessWidget {
  const ManoNotice({
    required this.message,
    this.tone = ManoNoticeTone.info,
    this.onDismiss,
    super.key,
  });

  final String message;
  final ManoNoticeTone tone;

  /// Shows a dismiss affordance when provided.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (tone) {
      ManoNoticeTone.info => (scheme.surfaceContainerHighest, scheme.onSurface),
      ManoNoticeTone.warning => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      ManoNoticeTone.error => (scheme.errorContainer, scheme.onErrorContainer),
    };

    return Container(
      padding: const EdgeInsets.all(ManoSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(ManoRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(message, style: TextStyle(color: foreground)),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: Icon(Icons.close, size: 18, color: foreground),
              visualDensity: VisualDensity.compact,
              tooltip: 'Dismiss',
            ),
        ],
      ),
    );
  }
}
