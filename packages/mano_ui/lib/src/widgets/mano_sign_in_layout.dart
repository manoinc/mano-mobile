import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'mano_primary_button.dart';

/// Wise's log-in: close, title, fields, the flame pill, a link, and the other ways at the bottom.
class ManoSignInLayout extends StatelessWidget {
  const ManoSignInLayout({
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    this.message,
    this.busy = false,
    this.linkLabel,
    this.onLink,
    this.footerLabel,
    this.footer,
    this.onClose,
    this.notice,
    super.key,
  });

  final String title;
  final String? message;

  /// The fields: a phone number or a code.
  final Widget body;
  final String primaryLabel;

  /// `null` disables the primary.
  final VoidCallback? onPrimary;
  final bool busy;

  /// A centred underlined link under the primary, e.g. "¿Problemas para entrar?".
  final String? linkLabel;
  final VoidCallback? onLink;

  /// Pinned to the bottom under [footerLabel], hidden while the keyboard is up.
  final Widget? footer;
  final String? footerLabel;

  /// Shows a round close button top-left.
  final VoidCallback? onClose;

  /// A failure the field cannot carry, e.g. the server being down.
  final Widget? notice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final footer = this.footer;
    final link = linkLabel;

    // While typing, the other ways step aside, as Wise's do.
    final showFooter =
        footer != null && MediaQuery.viewInsetsOf(context).bottom == 0;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
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
                    Text(title, style: theme.textTheme.headlineMedium),
                    if (message case final message?) ...[
                      const SizedBox(height: ManoSpacing.sm),
                      Text(
                        message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: context.palette.muted,
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
                    if (link != null) ...[
                      const SizedBox(height: ManoSpacing.sm),
                      Center(
                        child: TextButton(
                          onPressed: busy ? null : onLink,
                          style: TextButton.styleFrom(
                            minimumSize: const Size(44, 44),
                            foregroundColor: scheme.onSurface,
                            textStyle: theme.textTheme.labelLarge?.copyWith(
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          child: Text(link),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (showFooter)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  ManoSpacing.lg,
                  ManoSpacing.sm,
                  ManoSpacing.lg,
                  ManoSpacing.lg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (footerLabel case final label?) ...[
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: context.palette.muted,
                        ),
                      ),
                      const SizedBox(height: ManoSpacing.md),
                    ],
                    footer,
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
