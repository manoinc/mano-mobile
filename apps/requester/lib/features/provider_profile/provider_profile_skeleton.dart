import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';

/// Stone blocks in the profile's shape while it loads.
class ProviderProfileSkeleton extends StatelessWidget {
  const ProviderProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Padding(
      key: const Key('provider-profile-skeleton'),
      padding: const EdgeInsets.all(ManoSpacing.lg),
      child: Column(
        children: [
          const _Block(width: 96, height: 96, round: true),
          const SizedBox(height: ManoSpacing.md),
          const _Block(width: 180, height: 24),
          const SizedBox(height: ManoSpacing.md),
          const _Block(width: 140, height: 40),
          const SizedBox(height: ManoSpacing.xl),
          for (final width in const [120.0, double.infinity, 240.0]) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: _Block(width: width, height: 16),
            ),
            const SizedBox(height: ManoSpacing.sm),
          ],
          const SizedBox(height: ManoSpacing.lg),
          const _Block(width: double.infinity, height: 160),
        ],
      ),
    ),
  );
}

class _Block extends StatelessWidget {
  const _Block({required this.width, required this.height, this.round = false});

  final double width;
  final double height;
  final bool round;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: ManoColors.stone,
      borderRadius: BorderRadius.circular(
        round ? ManoRadius.pill : ManoRadius.card,
      ),
    ),
  );
}
