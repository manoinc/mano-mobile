import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'profile_labels.dart';

/// One review as a tile.
ManoReviewTile reviewTile(Review review) => ManoReviewTile(
  name: review.reviewer.displayName,
  photoUrl: review.reviewer.photoUrl,
  stars: review.stars,
  dateLabel: ManoFormat.dayMonth(review.date),
  text: review.text,
);

/// The latest two live reviews and a way to all of them.
class ReviewsSection extends ConsumerWidget {
  const ReviewsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(myReviewsProvider).value?.items;
    if (reviews == null || reviews.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Reseñas',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ManoTextAction(
              label: 'Ver todas',
              onPressed: () => context.push('/profile/reviews'),
            ),
          ],
        ),
        for (final review in reviews.take(2)) ...[
          const SizedBox(height: ManoSpacing.md),
          reviewTile(review),
        ],
      ],
    );
  }
}

/// The rating up top, then every review newest first, a page at a time.
class ReviewsScreen extends ConsumerStatefulWidget {
  const ReviewsScreen({super.key});

  @override
  ConsumerState<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends ConsumerState<ReviewsScreen> {
  bool _loading = false;

  Future<void> _more() async {
    setState(() => _loading = true);
    await ref.read(myReviewsProvider.notifier).loadMore();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(myReviewsProvider).value ?? ReviewFeed.empty;
    final rating = ref.watch(myRatingProvider).value ?? RatingSummary.none;
    final labels = ratingLabels(rating);

    return Scaffold(
      appBar: AppBar(title: const Text('Reseñas')),
      body: ListView(
        padding: const EdgeInsets.all(ManoSpacing.md),
        children: [
          ManoRatingSummary(
            average: rating.average,
            averageLabel: labels.average,
            countLabel: labels.count,
          ),
          const SizedBox(height: ManoSpacing.lg),
          for (final (i, review) in feed.items.indexed) ...[
            if (i > 0) const Divider(height: ManoSpacing.xl),
            reviewTile(review),
          ],
          if (feed.hasMore) ...[
            const SizedBox(height: ManoSpacing.lg),
            ManoOutlineButton(
              label: 'Ver más',
              busy: _loading,
              onPressed: _more,
            ),
          ],
        ],
      ),
    );
  }
}
