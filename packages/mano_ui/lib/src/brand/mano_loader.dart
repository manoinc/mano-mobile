import 'package:flutter/material.dart';

import '../theme/mano_motion.dart';
import 'mano_logo_paths.g.dart';

/// The brand's loading state: the `m` sweeping through, left to right, on a seamless loop.
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
              ? ManoLoaderFrame(from: 0, to: 1, color: ink)
              : AnimatedBuilder(
                  animation: _loop,
                  builder: (_, _) => ManoLoaderFrame(
                    from: _from(_loop.value),
                    to: _to(_loop.value),
                    color: ink,
                  ),
                ),
        ),
      ),
    );
  }

  // In by 45%, hold, out from 55%: empty at both ends, so the loop has no seam.
  static double _to(double t) =>
      ManoMotion.entrance.transform((t / 0.45).clamp(0.0, 1.0));

  static double _from(double t) =>
      ManoMotion.exit.transform(((t - 0.55) / 0.45).clamp(0.0, 1.0));
}

/// One frame of [ManoLoader]; public so the catalogue and tests can pin a frame.
class ManoLoaderFrame extends StatelessWidget {
  const ManoLoaderFrame({
    required this.from,
    required this.to,
    required this.color,
    super.key,
  });

  /// The drawn band of the `m`, as fractions of its width, 0 to 1.
  final double from;
  final double to;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _WipePainter(from, to, color),
    child: const SizedBox.expand(),
  );
}

class _WipePainter extends CustomPainter {
  _WipePainter(this.from, this.to, this.color);

  final double from;
  final double to;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (to <= from) return;
    canvas
      ..save()
      ..clipRect(
        Rect.fromLTRB(size.width * from, 0, size.width * to, size.height),
      )
      ..scale(size.width / kManoMonogramSize.width)
      ..drawPath(manoMonogram(), Paint()..color = color)
      ..restore();
  }

  @override
  bool shouldRepaint(_WipePainter old) =>
      old.from != from || old.to != to || old.color != color;
}
