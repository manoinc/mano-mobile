import 'package:flutter/material.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../features/explore/category_icons.dart';

void _showStub(BuildContext context) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Muy pronto')));
}

/// The CREATE action's content -- a real-looking entry point into posting a
/// job, even though the workflow behind it doesn't exist yet. A single
/// disabled row read as "not built"; this reads as "not built *yet*": every
/// tap answers with the same stub notice, but the button is live, the
/// categories are tappable, and the copy commits to what this becomes.
class CreateActionSheet extends StatelessWidget {
  const CreateActionSheet({super.key});

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
              'Cuéntanos qué necesitas y te conectamos con la persona ideal '
              'para hacerlo.',
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
                    onTap: () => _showStub(context),
                  );
                },
              ),
            ),
            const SizedBox(height: ManoSpacing.lg),
            ManoPrimaryButton(
              label: 'Publicar un trabajo',
              onPressed: () => _showStub(context),
            ),
            const SizedBox(height: ManoSpacing.sm),
            Text(
              'Muy pronto podrás publicar trabajos y recibir cotizaciones.',
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
