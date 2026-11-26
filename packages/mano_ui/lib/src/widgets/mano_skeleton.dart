import 'package:flutter/material.dart';

import '../theme/mano_motion.dart';
import '../theme/mano_theme.dart';

/// A rounded placeholder box with a soft opacity pulse; still under reduced motion.
class ManoSkeleton extends StatefulWidget {
  const ManoSkeleton({this.width, this.height = 16, super.key})
    : circle = false;

  /// A round placeholder, e.g. for an avatar.
  const ManoSkeleton.circle({required double size, super.key})
    : width = size,
      height = size,
      circle = true;

  final double? width;
  final double height;
  final bool circle;

  @override
  State<ManoSkeleton> createState() => _ManoSkeletonState();
}

class _ManoSkeletonState extends State<ManoSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: ManoMotion.skeleton,
  );

  late final Animation<double> _opacity = Tween<double>(
    begin: 1,
    end: ManoMotion.skeletonDim,
  ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: 'Cargando',
    child: FadeTransition(
      opacity: _opacity,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: widget.circle
              ? null
              : BorderRadius.circular(ManoRadius.pill),
        ),
      ),
    ),
  );
}

/// [rows] placeholder rows (avatar plus two lines) under one "Cargando" label.
class ManoSkeletonList extends StatelessWidget {
  const ManoSkeletonList({this.rows = 6, super.key});

  final int rows;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: 'Cargando',
    child: ExcludeSemantics(
      child: ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(ManoSpacing.md),
        children: [for (var i = 0; i < rows; i++) const _Row()],
      ),
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: ManoSpacing.sm),
    child: Row(
      children: [
        ManoSkeleton.circle(size: 48),
        SizedBox(width: ManoSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ManoSkeleton(height: 14),
              SizedBox(height: ManoSpacing.sm),
              FractionallySizedBox(
                widthFactor: 0.6,
                child: ManoSkeleton(height: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
