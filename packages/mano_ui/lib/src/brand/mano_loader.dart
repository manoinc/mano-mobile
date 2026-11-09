import 'package:flutter/material.dart';

import '../theme/mano_motion.dart';
import 'mano_logo_paths.g.dart';

/// The brand's loading state: the `m` wiping in, holding, fading, on a loop.
class ManoLoader extends StatefulWidget {
  const ManoLoader({this.color, this.height = 48, super.key});

  /// Sized to sit in place of a button label.
  const ManoLoader.small({this.color, super.key}) : height = 18;

  final Color? color;
  final double height;

  static const Duration cycle = Duration(milliseconds: 1400);

  @override
  State<ManoLoader> createState() => _ManoLoaderState();
}

class _ManoLoaderState extends State<ManoLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: ManoLoader.cycle,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _loop.stop();
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.color ?? Theme.of(context).colorScheme.primary;
    final still = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      container: true,
      label: 'Cargando',
      child: SizedBox(
        height: widget.height,
        child: AspectRatio(
          aspectRatio: kManoMonogramSize.aspectRatio,
          child: still
              ? ManoLoaderFrame(reveal: 1, opacity: 1, color: ink)
              : AnimatedBuilder(
                  animation: _loop,
                  builder: (_, _) => ManoLoaderFrame(
                    reveal: _reveal(_loop.value),
                    opacity: _opacity(_loop.value),
                    color: ink,
                  ),
                ),
        ),
      ),
    );
  }

  // Wipe in over the first 55%, hold, then fade over the last 25%.
  static double _reveal(double t) =>
      ManoMotion.entrance.transform((t / 0.55).clamp(0.0, 1.0));

  static double _opacity(double t) =>
      1 - ManoMotion.exit.transform(((t - 0.75) / 0.25).clamp(0.0, 1.0));
}

/// One frame of [ManoLoader]; public so the catalogue and tests can pin a frame.
class ManoLoaderFrame extends StatelessWidget {
  const ManoLoaderFrame({
    required this.reveal,
    required this.opacity,
    required this.color,
    super.key,
  });

  /// How much of the `m` is drawn, left to right, 0 to 1.
  final double reveal;
  final double opacity;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _WipePainter(reveal, color.withValues(alpha: color.a * opacity)),
    child: const SizedBox.expand(),
  );
}

class _WipePainter extends CustomPainter {
  _WipePainter(this.reveal, this.color);

  final double reveal;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (reveal <= 0) return;
    canvas
      ..save()
      ..clipRect(Offset.zero & Size(size.width * reveal, size.height))
      ..scale(size.width / kManoMonogramSize.width)
      ..drawPath(manoMonogram(), Paint()..color = color)
      ..restore();
  }

  @override
  bool shouldRepaint(_WipePainter old) =>
      old.reveal != reveal || old.color != color;
}
