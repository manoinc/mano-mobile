import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_domain/mano_domain.dart';

import '../session_notifier.dart';
import 'provider_reviews_feed.dart';
import 'review_providers.dart';

/// The signed-in provider's rating; none for a guest.
final myRatingProvider = FutureProvider<RatingSummary>((ref) async {
  final subject = ref.watch(currentUserProvider)?.subject;
  if (subject == null) return RatingSummary.none;
  return ref.watch(providerRatingProvider(subject).future);
});

/// The signed-in provider's reviews: their own [providerReviewsFeedProvider].
final myReviewsProvider = Provider.autoDispose<AsyncValue<ReviewFeed>>((ref) {
  final subject = ref.watch(currentUserProvider)?.subject;
  if (subject == null) return const AsyncData(ReviewFeed.empty);
  return ref.watch(providerReviewsFeedProvider(subject));
});

/// Loads the next page of the signed-in provider's reviews.
final loadMoreMyReviewsProvider = Provider<Future<void> Function()>(
  (ref) => () async {
    final subject = ref.read(currentUserProvider)?.subject;
    if (subject == null) return;
    await ref.read(providerReviewsFeedProvider(subject).notifier).loadMore();
  },
);
