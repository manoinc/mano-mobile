import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'mano_primary_button.dart';

/// The way in: a title, one field, the flame Continuar, then "o" and the other ways.
class ManoSignInLayout extends StatelessWidget {
  const ManoSignInLayout({
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    this.message,
    this.busy = false,
    this.alternatives = const [],
    this.dividerLabel = 'o',
    this.onClose,
    this.notice,
    super.key,
  });

  final String title;
  final String? message;

  /// The field: a phone number or a code.
  final Widget body;
  final String primaryLabel;

  /// `null` disables Continuar.
  final VoidCallback? onPrimary;
  final bool busy;

  /// Outlined pills under the "o"; none hides the divider.
  final List<Widget> alternatives;
  final String dividerLabel;

  /// Shows a close button top-left.
  final VoidCallback? onClose;

  /// A failure the field cannot carry, e.g. the server being down.
  final Widget? notice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            ManoSpacing.lg,
            ManoSpacing.sm,
            ManoSpacing.lg,
            ManoSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: onClose == null
                    ? const SizedBox(height: 48)
                    : IconButton.filledTonal(
                        onPressed: onClose,
                        tooltip: 'Cerrar',
                        style: IconButton.styleFrom(
                          backgroundColor: scheme.surfaceContainerHighest,
                          foregroundColor: scheme.onSurface,
                        ),
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
              const SizedBox(height: ManoSpacing.md),
              Text(title, style: theme.textTheme.headlineSmall),
              if (message case final message?) ...[
                const SizedBox(height: ManoSpacing.sm),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: ManoColors.muted,
                  ),
                ),
              ],
              const SizedBox(height: ManoSpacing.lg),
              body,
              if (notice case final notice?) ...[
                const SizedBox(height: ManoSpacing.md),
                notice,
              ],
              const SizedBox(height: ManoSpacing.lg),
              ManoPrimaryButton(
                label: primaryLabel,
                onPressed: onPrimary,
                busy: busy,
              ),
              if (alternatives.isNotEmpty) ...[
                const SizedBox(height: ManoSpacing.lg),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ManoSpacing.md,
                      ),
                      child: Text(
                        dividerLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: ManoColors.faint,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: ManoSpacing.lg),
                for (final (i, alternative) in alternatives.indexed) ...[
                  if (i > 0) const SizedBox(height: ManoSpacing.sm),
                  alternative,
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
