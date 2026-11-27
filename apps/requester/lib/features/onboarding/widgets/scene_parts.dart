import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';

/// Rises and fades a piece of the scene into place.
class Arriving extends StatelessWidget {
  const Arriving({required this.progress, required this.child, super.key});

  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: progress.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, (1 - progress) * 16),
        child: child,
      ),
    );
  }
}

/// A sand card with a stone edge, the surface every scene piece sits on.
class SceneCard extends StatelessWidget {
  const SceneCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.palette.sand,
        borderRadius: BorderRadius.circular(ManoRadius.card),
        border: Border.all(color: context.palette.stone),
      ),
      child: Padding(
        padding: const EdgeInsets.all(ManoSpacing.md),
        child: child,
      ),
    );
  }
}

/// A small pill floating over a card; [hot] makes it the one flame surface.
class SceneChip extends StatelessWidget {
  const SceneChip({
    required this.label,
    this.icon,
    this.hot = false,
    this.dark = false,
    super.key,
  });

  final String label;
  final IconData? icon;
  final bool hot;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final filled = hot || dark;
    final background = hot
        ? ManoColors.flame
        : dark
        ? context.palette.ink
        : context.palette.paper;
    final foreground = hot
        ? Colors.white
        : dark
        ? context.palette.paper
        : context.palette.ink;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(ManoRadius.pill),
        border: filled ? null : Border.all(color: context.palette.stone),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ManoSpacing.md,
          vertical: ManoSpacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: ManoSpacing.xs),
            ],
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: foreground, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
