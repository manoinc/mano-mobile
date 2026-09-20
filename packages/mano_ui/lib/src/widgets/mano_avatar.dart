import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';

/// Somebody's face, before there is a photograph of it.
///
/// Drawn rather than loaded: this package ships no images, and initials on a
/// tint survive being offline.
class ManoAvatar extends StatelessWidget {
  const ManoAvatar({
    required this.initials,
    this.tint,
    this.size = 48,
    super.key,
  });

  final String initials;

  /// Defaults to a tint derived from [initials], so the same person keeps the
  /// same colour without anybody having to assign one.
  final Color? tint;

  final double size;

  /// Warm neighbours of the brand, none of them flame.
  static const List<Color> _palette = [
    ManoColors.clay,
    Color(0xFF8C5A3C),
    Color(0xFF9A4F2B),
    Color(0xFFB07C4A),
    Color(0xFF7A4A3A),
    Color(0xFF6E4230),
  ];

  static Color tintFor(String initials) {
    var hash = 0;
    for (final unit in initials.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return _palette[hash % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final ground = tint ?? tintFor(initials);

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(color: ground, shape: BoxShape.circle),
        child: Center(
          child: Text(
            initials,
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.36,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
