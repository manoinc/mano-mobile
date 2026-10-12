import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';

import '../mock_previews.dart';
import 'scene_parts.dart';

/// Slide 1: there are people nearby, and they are rated.
class SlideDiscovery extends StatelessWidget {
  const SlideDiscovery({required this.reveal, super.key});

  /// 0 to 1. Drives the staggered arrival of the scene.
  final double reveal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = mockTaskers[0];
    final second = mockTaskers[1];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: ManoSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: ManoSpacing.xl),
          Text(
            'Encuentra a la persona ideal para lo que necesitas hacer.',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: ManoSpacing.xl),
          Arriving(
            progress: ManoMotion.stagger(0, reveal),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    top: ManoSpacing.md,
                    right: ManoSpacing.md,
                  ),
                  child: _ProCard(tasker: first),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: SceneChip(
                    label: first.ratingLabel,
                    icon: Icons.star_rounded,
                    hot: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ManoSpacing.md),
          Arriving(
            progress: ManoMotion.stagger(1, reveal),
            child: Padding(
              padding: const EdgeInsets.only(left: ManoSpacing.lg),
              child: _ProCard(tasker: second),
            ),
          ),
          const SizedBox(height: ManoSpacing.lg),
          Arriving(
            progress: ManoMotion.stagger(2, reveal),
            child: const _NearbyBubbles(),
          ),
          const SizedBox(height: ManoSpacing.lg),
        ],
      ),
    );
  }
}

class _ProCard extends StatelessWidget {
  const _ProCard({required this.tasker});

  final TaskerPreview tasker;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SceneCard(
      child: Row(
        children: [
          ManoAvatar(photoUrl: tasker.photoUrl, size: 56),
          const SizedBox(width: ManoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tasker.name, style: theme.textTheme.titleMedium),
                const SizedBox(height: ManoSpacing.xs),
                Text(
                  tasker.detail,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: ManoColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Overlapping portraits followed by the nearby count.
class _NearbyBubbles extends StatelessWidget {
  const _NearbyBubbles();

  static const _size = 40.0;
  static const _step = 28.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: _step * (nearbyPhotos.length - 1) + _size,
          height: _size,
          child: Stack(
            children: [
              for (final (index, url) in nearbyPhotos.indexed)
                Positioned(
                  left: index * _step,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: ManoAvatar(photoUrl: url, size: _size),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: ManoSpacing.md),
        const Flexible(
          child: SceneChip(label: '+120 profesionales cerca', dark: true),
        ),
      ],
    );
  }
}
