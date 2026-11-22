import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';

/// A titled block of the screen with an optional action in its header.
class AvailabilitySection extends StatelessWidget {
  const AvailabilitySection({
    required this.title,
    required this.detail,
    required this.child,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String detail;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: textTheme.titleLarge)),
            if (actionLabel != null)
              ManoTextAction(label: actionLabel!, onPressed: onAction),
          ],
        ),
        Text(
          detail,
          style: textTheme.bodyMedium?.copyWith(color: ManoColors.muted),
        ),
        const SizedBox(height: ManoSpacing.sm),
        child,
      ],
    );
  }
}

/// A failed read with a way to try again.
class AvailabilityLoadError extends StatelessWidget {
  const AvailabilityLoadError({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AvailabilityQuiet(message),
        ManoTextAction(label: 'Reintentar', onPressed: onRetry),
      ],
    );
  }
}

/// Secondary copy for empty and error states.
class AvailabilityQuiet extends StatelessWidget {
  const AvailabilityQuiet(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ManoSpacing.sm),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: ManoColors.faint),
      ),
    );
  }
}

class AvailabilityLoading extends StatelessWidget {
  const AvailabilityLoading({super.key});

  @override
  Widget build(BuildContext context) => const ManoSkeletonList(rows: 2);
}
