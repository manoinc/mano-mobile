import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'mano_primary_button.dart';
import 'mano_quiet_button.dart';

/// A sheet that asks for one thing and explains why.
///
/// Distinct from `ManoActionSheet`, which offers a list of places to go. This
/// one has a single answer and an optional control in the middle.
class ManoPromptSheet extends StatelessWidget {
  const ManoPromptSheet({
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.child,
    this.onClose,
    this.secondaryLabel,
    this.onSecondary,
    super.key,
  });

  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback? onPrimary;

  /// Sits between the message and the action -- a toggle, usually.
  final Widget? child;

  /// `null` hides the close control, for a sheet that must be answered.
  final VoidCallback? onClose;

  /// A quiet way to decline, under the action. Both halves or neither.
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          ManoSpacing.lg,
          ManoSpacing.sm,
          ManoSpacing.lg,
          ManoSpacing.lg,
        ),
        // The action is outside the scroll view on purpose: on a small
        // phone at large text the message can outgrow the sheet, and the one
        // thing that must never scroll away is the way out of it.
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 44,
              child: onClose == null
                  ? null
                  : Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: onClose,
                        icon: const Icon(Icons.close),
                        iconSize: 22,
                        tooltip: 'Cerrar',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 44,
                          height: 44,
                        ),
                      ),
                    ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: ManoSpacing.sm),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: context.palette.muted,
                      ),
                    ),
                    if (child != null) ...[
                      const SizedBox(height: ManoSpacing.lg),
                      child!,
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: ManoSpacing.lg),
            ManoPrimaryButton(label: primaryLabel, onPressed: onPrimary),
            if (secondaryLabel != null && onSecondary != null) ...[
              const SizedBox(height: ManoSpacing.sm),
              ManoQuietButton(label: secondaryLabel!, onPressed: onSecondary),
            ],
          ],
        ),
      ),
    );
  }
}
