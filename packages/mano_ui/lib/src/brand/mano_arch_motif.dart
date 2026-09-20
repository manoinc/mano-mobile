import 'package:flutter/material.dart';

import 'mano_logo_paths.g.dart';

/// The monogram, enlarged past the edge of whatever holds it.
///
/// The brand has no photography yet, and a hero with nothing behind it reads as
/// unfinished. This fills that ground with the mark itself, blown up far enough
/// that it stops being a logo and becomes an arch -- which is the shape the `m`
/// was drawn as anyway.
///
/// Decoration, so it is excluded from semantics and never takes a touch. Keep
/// [opacity] low enough that text sits comfortably on top: this is a texture,
/// not a second thing to look at.
class ManoArchMotif extends StatelessWidget {
  const ManoArchMotif({
    super.key,
    this.color,
    this.opacity,
    this.widthFactor = 1.45,
    this.alignment = const Alignment(0.55, -0.32),
  });

  /// Defaults to the surface's ink.
  final Color? color;

  /// Defaults by brightness, because the same alpha is not the same texture on
  /// both grounds: pale ink over a dark surface reads far stronger than dark
  /// ink over a light one, and a value tuned on white turns into a grey slab
  /// at night.
  final double? opacity;

  /// How many times the available width the monogram should span. Above 1 it
  /// necessarily bleeds, which is the point -- a motif that fits looks like a
  /// logo somebody left in the background.
  final double widthFactor;

  /// Where the monogram's centre sits.
  ///
  /// The default crops to one shoulder and the leg below it, running off the
  /// right-hand edge and leaving the lower left clear for the headline. Larger
  /// factors were tried and lose the shape: past about 2x the mark stops
  /// reading as an arch and becomes a pair of rectangles.
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alpha = opacity ??
        (theme.brightness == Brightness.dark ? 0.042 : 0.070);

    return ExcludeSemantics(
      child: IgnorePointer(
        child: ClipRect(
          child: ShaderMask(
            // The monogram's legs end in a straight edge, and a straight edge
            // across the middle of a screen reads as a mistake rather than as
            // texture. The fade has to reach zero *above* where they end, or it
            // only thins the edge instead of removing it -- measured on the
            // device the legs finish around 54% of the height, so this is done
            // by 45%, with room to spare on a taller screen.
            blendMode: BlendMode.dstIn,
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.white, Colors.transparent],
              stops: [0, 0.12, 0.45],
            ).createShader(bounds),
            child: CustomPaint(
              painter: _ArchPainter(
                color: (color ?? theme.colorScheme.onSurface)
                    .withValues(alpha: alpha),
                widthFactor: widthFactor,
                alignment: alignment,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArchPainter extends CustomPainter {
  _ArchPainter({
    required this.color,
    required this.widthFactor,
    required this.alignment,
  });

  final Color color;
  final double widthFactor;
  final Alignment alignment;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final width = size.width * widthFactor;
    final height = width / kManoMonogramSize.aspectRatio;
    final bounds = Rect.fromCenter(
      center: alignment.alongSize(size),
      width: width,
      height: height,
    );

    canvas
      ..save()
      ..translate(bounds.left, bounds.top)
      ..scale(width / kManoMonogramSize.width)
      ..drawPath(manoMonogram(), Paint()..color = color)
      ..restore();
  }

  @override
  bool shouldRepaint(_ArchPainter old) =>
      old.color != color ||
      old.widthFactor != widthFactor ||
      old.alignment != alignment;
}
