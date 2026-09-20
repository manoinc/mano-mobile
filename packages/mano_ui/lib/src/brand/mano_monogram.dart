import 'package:flutter/material.dart';

import 'mano_logo_paths.g.dart';

/// The `m` mark on its own.
///
/// A different drawing from the wordmark's `m`, but near enough the same
/// proportions to stand in for it: this is what the launcher icon and the
/// native splash show, and what the arch motif enlarges.
class ManoMonogram extends StatelessWidget {
  const ManoMonogram({super.key, this.color, this.height});

  final Color? color;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final ink = color ??
        DefaultTextStyle.of(context).style.color ??
        Theme.of(context).colorScheme.onSurface;

    return Semantics(
      label: 'Mano',
      image: true,
      child: SizedBox(
        height: height,
        child: AspectRatio(
          aspectRatio: kManoMonogramSize.aspectRatio,
          child: CustomPaint(
            painter: _MonogramPainter(ink),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _MonogramPainter extends CustomPainter {
  _MonogramPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / kManoMonogramSize.width)
      ..drawPath(manoMonogram(), Paint()..color = color)
      ..restore();
  }

  @override
  bool shouldRepaint(_MonogramPainter old) => old.color != color;
}
