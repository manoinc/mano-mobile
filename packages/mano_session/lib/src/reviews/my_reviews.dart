import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_domain/mano_domain.dart';

import '../session_notifier.dart';
import 'review_providers.dart';

/// The signed-in provider's rating; none for a guest.
final myRatingProvider = FutureProvider<RatingSummary>((ref) async {
  final subject = ref.watch(currentUserProvider)?.subject;
  if (subject == null) return RatingSummary.none;
  return ref.watch(providerRatingProvider(subject).future);
});

/// The reviews loaded so far and whether there are more.
final class ReviewFeed {
  const ReviewFeed({required this.items, this.nextCursor});

  static const empty = ReviewFeed(items: []);

  final List<Review> items;
  final String? nextCursor;

  bool get hasMore => nextCursor != null;
}

/// The signed-in provider's reviews, newest first, a page at a time.
final myReviewsProvider = AsyncNotifierProvider<MyReviews, ReviewFeed>(
  MyReviews.new,
);

final class MyReviews extends AsyncNotifier<ReviewFeed> {
  String? get _subject => ref.read(currentUserProvider)?.subject;

  @override
  Future<ReviewFeed> build() async {
    final subject = ref.watch(currentUserProvider)?.subject;
    if (subject == null) return ReviewFeed.empty;
    final page = await ref
        .watch(reviewRepositoryProvider)
        .providerReviews(subject);
    return switch (page) {
      Ok(:final value) => ReviewFeed(
        items: value.items,
        nextCursor: value.nextCursor,
      ),
      Err(:final failure) => throw failure,
    };
  }

  /// Appends the next page; a failure keeps what is already shown.
  Future<void> loadMore() async {
    final feed = state.value;
    final subject = _subject;
    if (feed == null || !feed.hasMore || subject == null) return;
    final page = await ref
        .read(reviewRepositoryProvider)
        .providerReviews(subject, after: feed.nextCursor);
    if (!ref.mounted) return;
    if (page case Ok(:final value)) {
      state = AsyncData(
        ReviewFeed(
          items: [...feed.items, ...value.items],
          nextCursor: value.nextCursor,
        ),
      );
    }
  }
}
