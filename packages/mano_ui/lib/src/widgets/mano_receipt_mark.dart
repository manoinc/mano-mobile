import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';

/// How far one of my messages got: out, on their phone, or seen.
enum ManoReceipt { sent, delivered, read }

/// Signal-style receipt: one circle-check sent, two overlapping delivered,
/// two flame-filled once read; [color] tints the outlined states.
class ManoReceiptMark extends StatelessWidget {
  const ManoReceiptMark({
    required this.receipt,
    this.color,
    this.size = 14,
    super.key,
  });

  final ManoReceipt receipt;
  final Color? color;
  final double size;

  static const _overlap = 0.4;

  /// Width the mark takes, so a bubble can reserve room for it.
  double get width =>
      receipt == ManoReceipt.sent ? size : size * (2 - _overlap);

  @override
  Widget build(BuildContext context) {
    final label = switch (receipt) {
      ManoReceipt.sent => 'Enviado',
      ManoReceipt.delivered => 'Entregado',
      ManoReceipt.read => 'Leído',
    };
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        key: Key('chat-receipt-${receipt.name}'),
        width: width,
        height: size,
        child: CustomPaint(
          painter: _ReceiptPainter(
            pair: receipt != ManoReceipt.sent,
            filled: receipt == ManoReceipt.read,
            color: color ?? context.palette.stone,
          ),
        ),
      ),
    );
  }
}

class _ReceiptPainter extends CustomPainter {
  _ReceiptPainter({
    required this.pair,
    required this.filled,
    required this.color,
  });

  final bool pair;
  final bool filled;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final d = size.height;
    final back = Offset(d / 2, d / 2);
    if (!pair) {
      _circle(canvas, back, d);
      return;
    }
    final front = Offset(size.width - d / 2, d / 2);
    // The front circle carves a thin gap out of the back one.
    final gap = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(Rect.fromCircle(center: front, radius: d / 2 + 1.2));
    canvas
      ..save()
      ..clipPath(gap);
    _circle(canvas, back, d);
    canvas.restore();
    _circle(canvas, front, d);
  }

  void _circle(Canvas canvas, Offset c, double d) {
    final tone = filled ? ManoColors.flame : color;
    final stroke = d / 11;
    if (filled) {
      canvas.drawCircle(c, d / 2, Paint()..color = tone);
    } else {
      canvas.drawCircle(
        c,
        d / 2 - stroke / 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = tone,
      );
    }
    final tick = Path()
      ..moveTo(c.dx - d * 0.2, c.dy + d * 0.02)
      ..lineTo(c.dx - d * 0.04, c.dy + d * 0.18)
      ..lineTo(c.dx + d * 0.22, c.dy - d * 0.14);
    canvas.drawPath(
      tick,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = filled ? Colors.white : tone,
    );
  }

  @override
  bool shouldRepaint(_ReceiptPainter old) =>
      old.pair != pair || old.filled != filled || old.color != color;
}
