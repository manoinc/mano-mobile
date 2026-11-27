import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'mano_primary_button.dart';

/// A centered "nothing here yet" placeholder with one way forward.
///
/// Takes an icon, a message and an optional CTA -- no knowledge of *why* the list is
/// empty (no projects yet, a filter matched nothing, a search came back
/// blank). The screen decides the wording; this widget only lays it out.
class ManoEmptyState extends StatelessWidget {
  const ManoEmptyState({
    required this.icon,
    required this.message,
    this.ctaLabel,
    this.onCta,
    super.key,
  });

  final IconData icon;
  final String message;

  /// Both null when the screen already shows the way forward elsewhere.
  final String? ctaLabel;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ManoSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: context.palette.faint),
            const SizedBox(height: ManoSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (ctaLabel case final label?) ...[
              const SizedBox(height: ManoSpacing.lg),
              ManoPrimaryButton(label: label, onPressed: onCta),
            ],
          ],
        ),
      ),
    );
  }
}
