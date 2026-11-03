import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';

/// A provider's stars in one line, e.g. "★ 4,9 · 32", or "Nuevo" before any.
class ManoRatingBadge extends StatelessWidget {
  const ManoRatingBadge({required this.label, this.rated = true, super.key});

  /// Already formatted by the screen.
  final String label;

  /// False before the first review: the label shows without a star.
  final bool rated;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodySmall;
    final style = rated
        ? base?.copyWith(color: ManoColors.ink, fontWeight: FontWeight.w600)
        : base?.copyWith(color: ManoColors.clay);
    // One rich text, so a narrow card ellipsizes instead of overflowing.
    return Text.rich(
      TextSpan(
        children: [
          if (rated)
            const WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: EdgeInsets.only(right: 2),
                child: Icon(
                  Icons.star_rounded,
                  size: 15,
                  color: ManoColors.clay,
                ),
              ),
            ),
          TextSpan(text: label),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }
}
