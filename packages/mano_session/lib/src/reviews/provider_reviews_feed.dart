import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_domain/mano_domain.dart';

import 'review_providers.dart';

/// A provider's reviews loaded so far, and whether more can follow.
final class ReviewFeed {
  const ReviewFeed({
    required this.items,
    this.nextCursor,
    this.loadingMore = false,
    this.loadMoreFailed = false,
  });

  static const empty = ReviewFeed(items: []);

  final List<Review> items;
  final String? nextCursor;
  final bool loadingMore;
  final bool loadMoreFailed;

  bool get hasMore => nextCursor != null;
}

/// Every review of one provider, a page at a time, newest first.
final providerReviewsFeedProvider = AsyncNotifierProvider.autoDispose
    .family<ProviderReviewsFeed, ReviewFeed, String>(
      ProviderReviewsFeed.new,
      retry: (_, _) => null,
    );

final class ProviderReviewsFeed extends AsyncNotifier<ReviewFeed> {
  ProviderReviewsFeed(this.providerId);

  final String providerId;

  @override
  Future<ReviewFeed> build() async {
    final result = await ref
        .watch(reviewRepositoryProvider)
        .providerReviews(providerId);
    return switch (result) {
      Ok(:final value) => ReviewFeed(
        items: value.items,
        nextCursor: value.nextCursor,
      ),
      Err(:final failure) => throw failure,
    };
  }

  /// Appends the next page; a failure keeps what is shown.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(
      ReviewFeed(
        items: current.items,
        nextCursor: current.nextCursor,
        loadingMore: true,
      ),
    );
    final result = await ref
        .read(reviewRepositoryProvider)
        .providerReviews(providerId, after: current.nextCursor);
    if (!ref.mounted) return;
    state = AsyncData(switch (result) {
      Ok(:final value) => ReviewFeed(
        items: [...current.items, ...value.items],
        nextCursor: value.nextCursor,
      ),
      Err() => ReviewFeed(
        items: current.items,
        nextCursor: current.nextCursor,
        loadMoreFailed: true,
      ),
    });
  }
}
