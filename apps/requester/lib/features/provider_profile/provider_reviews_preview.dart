import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'provider_profile_route.dart';
import 'rating_labels.dart';
import 'review_tile.dart';

const _shown = 3;

/// The newest reviews and, when there are more, a way to all of them.
class ProviderReviewsPreview extends StatelessWidget {
  const ProviderReviewsPreview({
    required this.providerId,
    required this.rating,
    required this.reviews,
    super.key,
  });

  final String providerId;
  final RatingSummary rating;
  final ReviewPage reviews;

  @override
  Widget build(BuildContext context) {
    if (reviews.items.isEmpty) return const SizedBox.shrink();
    final total = rating.count > reviews.items.length
        ? rating.count
        : reviews.items.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Reseñas', style: Theme.of(context).textTheme.titleLarge),
        for (final review in reviews.items.take(_shown)) ...[
          const SizedBox(height: ManoSpacing.lg),
          reviewTile(review),
        ],
        if (reviews.hasMore || reviews.items.length > _shown) ...[
          const SizedBox(height: ManoSpacing.lg),
          ManoOutlineButton(
            label: 'Ver las ${reviewsCountText(total)}',
            onPressed: () =>
                context.push('${providerProfilePath(providerId)}/reviews'),
          ),
        ],
      ],
    );
  }
}
