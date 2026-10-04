import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';

/// A failed read with a way to try again.
class ActivityLoadError extends StatelessWidget {
  const ActivityLoadError({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: ManoColors.muted),
          ),
          const SizedBox(height: ManoSpacing.sm),
          ManoQuietButton(label: 'Reintentar', onPressed: onRetry),
        ],
      ),
    );
  }
}
