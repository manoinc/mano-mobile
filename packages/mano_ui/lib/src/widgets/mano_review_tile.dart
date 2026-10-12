import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'mano_avatar.dart';

/// A review: reviewer portrait and name, stars, date and the written text.
class ManoReviewTile extends StatelessWidget {
  const ManoReviewTile({
    required this.name,
    required this.photoUrl,
    required this.stars,
    required this.dateLabel,
    required this.text,
    super.key,
  });

  final String name;
  final String? photoUrl;

  /// Out of five.
  final int stars;
  final String dateLabel;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ManoAvatar(photoUrl: photoUrl, size: 40),
            const SizedBox(width: ManoSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: theme.titleSmall),
                  Text(
                    dateLabel,
                    style: theme.bodySmall?.copyWith(color: ManoColors.faint),
                  ),
                ],
              ),
            ),
            Semantics(
              label: '$stars de 5 estrellas',
              child: ExcludeSemantics(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < 5; i++)
                      Icon(
                        i < stars
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 16,
                        color: i < stars ? ManoColors.clay : ManoColors.faint,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: ManoSpacing.sm),
        Text(text, style: theme.bodyMedium),
      ],
    );
  }
}
