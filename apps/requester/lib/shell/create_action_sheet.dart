import 'package:flutter/material.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../features/explore/category_icons.dart';

/// The CREATE action: start a project, from a category or from scratch.
class CreateActionSheet extends StatelessWidget {
  const CreateActionSheet({required this.onPublish, super.key});

  /// Called with the tapped category's id, or null for the button.
  final ValueChanged<String?> onPublish;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          ManoSpacing.lg,
          ManoSpacing.md,
          ManoSpacing.lg,
          ManoSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
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
            const SizedBox(height: ManoSpacing.sm),
            Text('¿Qué necesitas hacer?', style: theme.textTheme.headlineSmall),
            const SizedBox(height: ManoSpacing.xs),
            Text(
              'Publica un proyecto y recibe cotizaciones de profesionales '
              'cerca de ti.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: ManoColors.muted,
              ),
            ),
            const SizedBox(height: ManoSpacing.lg),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: ServiceCategories.all.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: ManoSpacing.sm),
                itemBuilder: (context, index) {
                  final category = ServiceCategories.all[index];
                  return ManoCategoryChip(
                    icon: categoryIcon(category.iconKey),
                    label: category.label,
                    selected: false,
                    onTap: () => onPublish(category.id),
                  );
                },
              ),
            ),
            const SizedBox(height: ManoSpacing.lg),
            ManoPrimaryButton(
              label: 'Publicar proyecto',
              onPressed: () => onPublish(null),
            ),
            const SizedBox(height: ManoSpacing.sm),
            Text(
              'Es gratis. Te avisamos cuando lleguen cotizaciones.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: ManoColors.faint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
