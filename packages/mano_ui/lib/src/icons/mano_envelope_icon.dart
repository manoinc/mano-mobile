import 'package:flutter/widgets.dart';

/// Heroicons' outline envelope (v2.2.0, MIT), drawn as a path so `mano_ui` ships no images.
class ManoEnvelopeIcon extends StatelessWidget {
  const ManoEnvelopeIcon({this.size, this.color, super.key});

  /// Defaults to the ambient [IconTheme] size.
  final double? size;

  /// Defaults to the ambient [IconTheme] colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final side = size ?? theme.size ?? 24;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: side,
        child: CustomPaint(
          painter: _EnvelopePainter(
            color ?? theme.color ?? const Color(0xFF000000),
          ),
        ),
      ),
    );
  }
}

/// The envelope on Heroicons' 24 x 24 grid.
Path manoEnvelopePath() {
  const r = Radius.circular(2.25);
  return Path()
    ..moveTo(21.75, 6.75)
    ..lineTo(21.75, 17.25)
    ..arcToPoint(const Offset(19.5, 19.5), radius: r)
    ..lineTo(4.5, 19.5)
    ..arcToPoint(const Offset(2.25, 17.25), radius: r)
    ..lineTo(2.25, 6.75)
    ..moveTo(21.75, 6.75)
    ..arcToPoint(const Offset(19.5, 4.5), radius: r, clockwise: false)
    ..lineTo(4.5, 4.5)
    ..arcToPoint(const Offset(2.25, 6.75), radius: r, clockwise: false)
    ..moveTo(21.75, 6.75)
    ..lineTo(21.75, 6.993)
    ..arcToPoint(const Offset(20.68, 8.909), radius: r)
    ..lineTo(13.18, 13.524)
    ..arcToPoint(const Offset(10.82, 13.524), radius: r)
    ..lineTo(3.32, 8.91)
    ..arcToPoint(const Offset(2.25, 6.994), radius: r)
    ..lineTo(2.25, 6.75);
}

class _EnvelopePainter extends CustomPainter {
  _EnvelopePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / 24)
      ..drawPath(
        manoEnvelopePath(),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_EnvelopePainter old) => old.color != color;
}
