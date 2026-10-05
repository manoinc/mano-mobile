import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';

/// The catalogue's landing page: what this is and how to read it.
class CatalogueHome extends StatelessWidget {
  const CatalogueHome({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Theme(
      data: ManoTheme.light(),
      child: Material(
        color: Colors.white,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(ManoSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ManoMonogram(height: 56, color: ManoColors.flame),
                  const SizedBox(height: ManoSpacing.lg),
                  Text('Mano components', style: t.headlineLarge),
                  const SizedBox(height: ManoSpacing.sm),
                  Text(
                    'Every widget in mano_ui, as both apps use it. Pick one on the left, '
                    'change its knobs on the right, and switch theme, phone size and text '
                    'scale under Addons.',
                    style: t.bodyLarge?.copyWith(color: ManoColors.muted),
                  ),
                  const SizedBox(height: ManoSpacing.md),
                  Text(
                    'Start with Foundations for colour, type, spacing, corners and motion.',
                    style: t.bodyMedium?.copyWith(color: ManoColors.faint),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
