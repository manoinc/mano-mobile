import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'rating_labels.dart';
import 'review_tile.dart';

/// Every review of one provider, newest first, a page at a time.
class ProviderReviewsScreen extends ConsumerWidget {
  const ProviderReviewsScreen({required this.providerId, super.key});

  final String providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(providerReviewsFeedProvider(providerId));
    final rating = ref.watch(providerRatingProvider(providerId)).value;
    final count = rating?.count ?? feed.value?.items.length ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(reviewsCountText(count))),
      body: switch (feed) {
        AsyncData(:final value) when value.items.isEmpty =>
          const ManoEmptyState(
            icon: Icons.rate_review_outlined,
            message: 'Aún sin reseñas',
          ),
        AsyncData(:final value) => _List(
          feed: value,
          onMore: ref
              .read(providerReviewsFeedProvider(providerId).notifier)
              .loadMore,
        ),
        AsyncError() => ManoEmptyState(
          icon: Icons.cloud_off_outlined,
          message: 'No pudimos cargar las reseñas',
          ctaLabel: 'Reintentar',
          onCta: () => ref.invalidate(providerReviewsFeedProvider(providerId)),
        ),
        _ => const ManoSkeletonList(),
      },
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.feed, required this.onMore});

  final ReviewFeed feed;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.all(ManoSpacing.lg),
    itemCount: feed.items.length + (feed.hasMore ? 1 : 0),
    separatorBuilder: (_, _) => const Divider(height: ManoSpacing.xl),
    itemBuilder: (context, i) {
      if (i < feed.items.length) return reviewTile(feed.items[i]);
      return Column(
        children: [
          if (feed.loadMoreFailed)
            Padding(
              padding: const EdgeInsets.only(bottom: ManoSpacing.sm),
              child: Text(
                'No pudimos cargar más reseñas',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: context.palette.muted),
              ),
            ),
          ManoOutlineButton(
            label: feed.loadMoreFailed ? 'Reintentar' : 'Ver más',
            busy: feed.loadingMore,
            onPressed: onMore,
          ),
        ],
      );
    },
  );
}
