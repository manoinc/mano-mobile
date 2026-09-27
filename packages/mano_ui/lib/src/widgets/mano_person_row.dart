import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';

/// A professional, at a glance: who they are, what they do, how they rate.
///
/// [rating] fills the stars; [ratingLabel] is the text beside them, already
/// worded and formatted by the caller — decimal separators are a locale
/// decision this package has no way to make.
class ManoPersonRow extends StatelessWidget {
  const ManoPersonRow({
    required this.avatar,
    required this.name,
    required this.detail,
    required this.rating,
    required this.ratingLabel,
    super.key,
  });

  final Widget avatar;
  final String name;
  final String detail;

  /// 0 to 5.
  final double rating;
  final String ratingLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(ManoSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(ManoRadius.card),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          avatar,
          const SizedBox(width: ManoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ManoColors.faint,
                  ),
                ),
                const SizedBox(height: ManoSpacing.sm),
                _Stars(rating: rating, label: ratingLabel),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.rating, required this.label});

  final double rating;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    IconData glyph(int i) {
      if (rating >= i + 1) return Icons.star_rounded;
      if (rating >= i + 0.5) return Icons.star_half_rounded;
      return Icons.star_outline_rounded;
    }

    return Semantics(
      label: label,
      container: true,
      child: ExcludeSemantics(
        child: Row(
          children: [
            for (var i = 0; i < 5; i++)
              Icon(
                glyph(i),
                size: 16,
                // Clay, not flame: a rating is secondary emphasis, and flame is
                // spoken for by the one action on the screen.
                color: ManoColors.clay,
              ),
            const SizedBox(width: ManoSpacing.sm),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: ManoColors.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
