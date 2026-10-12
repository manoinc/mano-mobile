import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';

/// A compact, frameless listing: square photo, then title, pro and price.
///
/// The narrow sibling of `ManoListingCard`, for free-scrolling rails.
class ManoListingTile extends StatelessWidget {
  const ManoListingTile({
    required this.title,
    required this.photoUrl,
    required this.professionalName,
    required this.priceLabel,
    required this.onTap,
    this.rating,
    super.key,
  });

  final String title;
  final String photoUrl;
  final String professionalName;

  /// Pre-formatted, e.g. "Desde $80.000".
  final String priceLabel;

  /// `null` hides the rating.
  final double? rating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final rating = this.rating;
    final muted = text.bodySmall?.copyWith(color: ManoColors.muted);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(ManoRadius.card),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                photoUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const ColoredBox(color: ManoColors.stone),
                errorBuilder: (context, error, stackTrace) =>
                    const ColoredBox(color: ManoColors.stone),
              ),
            ),
          ),
          const SizedBox(height: ManoSpacing.sm),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.bodyMedium?.copyWith(
              color: ManoColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            professionalName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: muted,
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  priceLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                    color: ManoColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (rating != null) ...[
                const Icon(Icons.star, size: 14, color: ManoColors.ink),
                const SizedBox(width: 2),
                Text(rating.toStringAsFixed(1), style: muted),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// A horizontal rail that scrolls freely, each child [itemWidth] wide.
///
/// Sized to its tallest child, so the screen never computes a height.
class ManoListingRail extends StatelessWidget {
  const ManoListingRail({
    required this.children,
    required this.itemWidth,
    super.key,
  });

  final List<Widget> children;
  final double itemWidth;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: ManoSpacing.md),
            SizedBox(width: itemWidth, child: children[i]),
          ],
        ],
      ),
    );
  }
}
