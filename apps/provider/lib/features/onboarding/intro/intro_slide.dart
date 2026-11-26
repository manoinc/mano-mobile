import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';

/// One intro slide: headline, one line, and a mock preview of the product.
class IntroSlide extends StatelessWidget {
  const IntroSlide({
    required this.title,
    required this.subtitle,
    required this.preview,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget preview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: ManoSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: ManoSpacing.xl),
          Text(title, style: theme.textTheme.headlineMedium),
          const SizedBox(height: ManoSpacing.sm),
          Text(
            subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(color: ManoColors.muted),
          ),
          const SizedBox(height: ManoSpacing.xl),
          // A picture of the product, not a control.
          IgnorePointer(child: preview),
          const SizedBox(height: ManoSpacing.lg),
        ],
      ),
    );
  }
}
