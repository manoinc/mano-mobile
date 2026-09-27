import 'package:flutter/material.dart';

import '../theme/mano_motion.dart';
import 'mano_logo_paths.g.dart';

/// The `mano` lockup, optionally part way through arriving.
///
/// [progress] 0 draws the `m` alone; 1 draws the whole lockup. In between, the
/// `a`, `n` and `o` rise into place in order, their windows overlapping so the
/// word reads as one movement rather than four.
///
/// The `m` never animates, because the app-open sequence has already been
/// showing it -- first as the native splash icon, then as Flutter's first
/// frame. The letters are what is new.
class ManoWordmark extends StatelessWidget {
  const ManoWordmark({
    super.key,
    this.progress = 1,
    this.color,
    this.height,
  }) : assert(progress >= 0 && progress <= 1, 'progress is a fraction');

  /// How far through the reveal, 0 to 1.
  final double progress;

  /// Defaults to the ambient text colour, so the wordmark inherits like type.
  final Color? color;

  /// The lockup's height. Width follows from the artwork's proportions.
  final double? height;

  /// Where a letter begins: low, and slightly small.
  static const double _rise = 0.22;
  static const double _shrink = 0.08;

  /// How far through its own arrival letter [index] is, 0 to 1.
  ///
  /// Exposed so the opening animation can line other things up against the
  /// letters without re-deriving the choreography.
  static double glyphProgress(int index, double progress) {
    // The `m` is already on screen, so the letters are one place along.
    if (index <= 0) return 1;
    return ManoMotion.stagger(index - 1, progress);
  }

  @override
  Widget build(BuildContext context) {
    final ink = color ??
        DefaultTextStyle.of(context).style.color ??
        Theme.of(context).colorScheme.onSurface;

    return Semantics(
      // The wordmark is the product's name, not decoration.
      label: 'Mano',
      image: true,
      child: SizedBox(
        height: height,
        child: AspectRatio(
          aspectRatio: kManoWordmarkSize.aspectRatio,
          child: CustomPaint(
            painter: _WordmarkPainter(progress: progress, color: ink),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _WordmarkPainter extends CustomPainter {
  _WordmarkPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / kManoWordmarkSize.width);

    for (var i = 0; i < kManoWordmarkGlyphs.length; i++) {
      final t = ManoWordmark.glyphProgress(i, progress);
      if (t <= 0) continue;

      final path = kManoWordmarkGlyphs[i]();
      final paint = Paint()..color = color.withValues(alpha: color.a * t);

      if (t >= 1) {
        canvas.drawPath(path, paint);
        continue;
      }

      // Each letter grows from its own baseline rather than the lockup's
      // centre, so they settle onto the line instead of converging on a point.
      final (left, right) = kManoWordmarkGlyphExtents[i];
      final anchor = Offset((left + right) / 2, kManoWordmarkSize.height);

      canvas
        ..save()
        ..translate(anchor.dx, anchor.dy)
        ..translate(0, (1 - t) * kManoWordmarkSize.height * ManoWordmark._rise)
        ..scale(1 - (1 - t) * ManoWordmark._shrink)
        ..translate(-anchor.dx, -anchor.dy)
        ..drawPath(path, paint)
        ..restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_WordmarkPainter old) =>
      old.progress != progress || old.color != color;
}
