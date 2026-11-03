import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_domain/mano_domain.dart';

import 'review_providers.dart';

/// Everything the requester's provider profile shows, read at once.
final class ProviderProfileView {
  const ProviderProfileView({
    required this.profile,
    required this.rating,
    required this.reviews,
  });

  final PublicProviderProfile profile;
  final RatingSummary rating;

  /// The first page, newest first.
  final ReviewPage reviews;
}

/// Null when the directory has no such provider; other failures are errors.
final providerProfileViewProvider = FutureProvider.autoDispose
    .family<ProviderProfileView?, String>(
      (ref, providerId) async {
        final reviews = ref.watch(reviewRepositoryProvider);
        final (found, rating, page) = await (
          ref.watch(providerDirectoryProvider).profile(providerId),
          ref.watch(providerRatingProvider(providerId).future),
          reviews.providerReviews(providerId),
        ).wait;
        final profile = switch (found) {
          Ok(:final value) => value,
          Err(failure: DataNotFound()) => null,
          Err(:final failure) => throw failure,
        };
        if (profile == null) return null;
        return ProviderProfileView(
          profile: profile,
          rating: rating,
          reviews: page.valueOrNull ?? const ReviewPage(items: []),
        );
      },
      // The screen offers its own retry; silent retries would hide the error.
      retry: (_, _) => null,
    );
