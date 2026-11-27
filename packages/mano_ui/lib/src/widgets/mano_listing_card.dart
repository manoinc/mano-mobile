import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'mano_avatar.dart';

/// A single service listing, as shown in the Home tab's feed.
///
/// Takes only strings, a nullable rating and a callback -- no `Listing`
/// entity, no currency formatting. `priceLabel` arrives pre-formatted
/// because turning cents into "Desde $80.000 COP" needs a locale, which is a
/// screen-level concern.
class ManoListingCard extends StatelessWidget {
  const ManoListingCard({
    required this.title,
    required this.photoUrl,
    required this.professionalName,
    required this.professionalPhotoUrl,
    required this.priceLabel,
    this.rating,
    required this.onTap,
    super.key,
  });

  final String title;
  final String photoUrl;
  final String professionalName;
  final String professionalPhotoUrl;

  /// Pre-formatted, e.g. "Desde $80.000 COP".
  final String priceLabel;

  /// `null` hides the rating entirely.
  final double? rating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rating = this.rating;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return ColoredBox(color: context.palette.stone);
                    },
                    errorBuilder: (context, error, stackTrace) =>
                        ColoredBox(color: context.palette.stone),
                  ),
                  Positioned(
                    left: ManoSpacing.sm,
                    bottom: ManoSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ManoSpacing.sm,
                        vertical: ManoSpacing.xs,
                      ),
                      decoration: const BoxDecoration(
                        color: ManoColors.flame,
                        borderRadius: BorderRadius.all(
                          Radius.circular(ManoRadius.pill),
                        ),
                      ),
                      child: Text(
                        priceLabel,
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(ManoSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      ManoAvatar(photoUrl: professionalPhotoUrl, size: 28),
                      const SizedBox(width: ManoSpacing.xs),
                      Expanded(
                        child: Text(
                          professionalName,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                      if (rating != null) ...[
                        const SizedBox(width: ManoSpacing.xs),
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: ManoColors.flame,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          rating.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: ManoSpacing.xs),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: scheme.onSurface),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
