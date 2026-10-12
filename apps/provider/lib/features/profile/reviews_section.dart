import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

/// One review as a tile.
ManoReviewTile reviewTile(Review review) => ManoReviewTile(
  name: review.reviewer.displayName,
  photoUrl: review.reviewer.photoUrl,
  stars: review.stars,
  dateLabel: ManoFormat.dayMonth(review.date),
  text: review.text,
);

/// The latest two reviews and a way to all of them.
class ReviewsSection extends ConsumerWidget {
  const ReviewsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(providerReviewsProvider).value;
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

/// Every review, newest first.
class ReviewsScreen extends ConsumerWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(providerReviewsProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(title: const Text('Reseñas')),
      body: ListView.separated(
        padding: const EdgeInsets.all(ManoSpacing.md),
        itemCount: reviews.length,
        separatorBuilder: (_, _) => const Divider(height: ManoSpacing.xl),
        itemBuilder: (_, i) => reviewTile(reviews[i]),
      ),
    );
  }
}
