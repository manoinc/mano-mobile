import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';

/// A failed read with a way to try again.
class ProjectsLoadError extends StatelessWidget {
  const ProjectsLoadError({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ManoSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: ManoColors.muted),
            ),
            const SizedBox(height: ManoSpacing.sm),
            ManoQuietButton(label: 'Reintentar', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
