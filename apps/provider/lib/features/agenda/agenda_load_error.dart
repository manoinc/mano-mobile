import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';

/// A failed read with a way to try again.
class AgendaLoadError extends StatelessWidget {
  const AgendaLoadError({
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
                ?.copyWith(color: context.palette.muted),
          ),
          const SizedBox(height: ManoSpacing.sm),
          ManoQuietButton(label: 'Reintentar', onPressed: onRetry),
        ],
      ),
    );
  }
}
