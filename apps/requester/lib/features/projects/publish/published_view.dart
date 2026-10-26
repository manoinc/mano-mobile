import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';

/// The full-screen confirmation once a project is out.
class PublishedView extends StatelessWidget {
  const PublishedView({required this.onOpen, super.key});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(ManoSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(
                Icons.check_circle_outline,
                size: 72,
                color: ManoColors.clay,
              ),
              const SizedBox(height: ManoSpacing.lg),
              Text(
                'Proyecto publicado',
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium,
              ),
              const SizedBox(height: ManoSpacing.sm),
              Text(
                'Te avisaremos cuando lleguen cotizaciones.',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(color: ManoColors.muted),
              ),
              const Spacer(),
              ManoPrimaryButton(label: 'Ver proyecto', onPressed: onOpen),
            ],
          ),
        ),
      ),
    );
  }
}
