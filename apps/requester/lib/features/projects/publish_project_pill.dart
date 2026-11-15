import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';

/// The floating Angi-style pill, outlined: the shell's centre "+" is the flame.
class PublishProjectPill extends StatelessWidget {
  const PublishProjectPill({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return OutlinedButton.icon(
      key: const Key('publish-project-pill'),
      onPressed: onTap,
      icon: const Icon(Icons.add),
      label: const Text('Publicar proyecto'),
      style: OutlinedButton.styleFrom(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        side: BorderSide(color: scheme.onSurface, width: 1.5),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(
          horizontal: ManoSpacing.lg,
          vertical: ManoSpacing.md,
        ),
        textStyle: theme.textTheme.labelLarge,
      ),
    );
  }
}
