import 'package:flutter/material.dart';

import '../theme/mano_motion.dart';
import '../theme/mano_theme.dart';
import 'mano_primary_button.dart';

/// A short, centred message with one way on.
///
/// For the moment after something finished, not for asking a question -- a
/// question belongs in a sheet, within reach of a thumb.
class ManoDialogCard extends StatelessWidget {
  const ManoDialogCard({
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.art,
    super.key,
  });

  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback? onPrimary;

  /// An illustration above the title. Sized by the caller.
  final Widget? art;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ManoSpacing.lg),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 360,
            maxHeight: MediaQuery.sizeOf(context).height * 0.8,
          ),
          child: Material(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(ManoRadius.lg),
            child: Padding(
              padding: const EdgeInsets.all(ManoSpacing.lg),
              // The action sits outside the scroll view, so it survives a
              // message that has outgrown the card.
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (art != null) ...[
                            art!,
                            const SizedBox(height: ManoSpacing.md),
                          ],
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: ManoSpacing.sm),
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: context.palette.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: ManoSpacing.lg),
                  ManoPrimaryButton(label: primaryLabel, onPressed: onPrimary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Raises a dialog with Mano's scrim and timing.
///
/// The same ink barrier as [showManoSheet], so the two read as one system.
Future<T?> showManoDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  // Someone who asked for less motion still gets the dialog, just not the
  // performance.
  final still = MediaQuery.disableAnimationsOf(context);

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Cerrar',
    barrierColor: ManoColors.scrim.withValues(alpha: 0.45),
    transitionDuration: still ? Duration.zero : ManoMotion.normal,
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: ManoMotion.entrance,
        reverseCurve: ManoMotion.exit,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}
