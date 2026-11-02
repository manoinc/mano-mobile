import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

import '../offline_marketplace_provider.dart';
import '../session_providers.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>(
  (ref) => ref.watch(offlineMarketplaceProvider)
      ? MockReviewRepository()
      : GatewayReviewRepository(ref.watch(gatewayTransportProvider)),
);

// Mock until the gateway can look a provider up by id (docs/develop/reviews.md).
final providerDirectoryProvider = Provider<ProviderDirectory>(
  (ref) => MockProviderDirectory(),
);

/// A provider's stars; a rating that can't be read shows as none.
final providerRatingProvider = FutureProvider.family<RatingSummary, String>((
  ref,
  providerId,
) async {
  final result = await ref
      .watch(reviewRepositoryProvider)
      .providerRating(providerId);
  return result.valueOrNull ?? RatingSummary.none;
});

/// Jobs rated in this session; the gateway has no "already reviewed" field.
final reviewedJobsProvider = NotifierProvider<ReviewedJobs, Set<String>>(
  ReviewedJobs.new,
);

final class ReviewedJobs extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void add(String jobId) => state = {...state, jobId};
}

/// Rating either side of a finished job.
final class ReviewActions extends Notifier<void> {
  @override
  void build() {}

  ReviewRepository get _repo => ref.read(reviewRepositoryProvider);

  Future<Result<Review, DataFailure>> reviewProvider(
    String jobId,
    ReviewDraft draft,
  ) => _record(jobId, _repo.reviewProvider(jobId, draft));

  Future<Result<Review, DataFailure>> reviewClient(
    String jobId,
    ReviewDraft draft,
  ) => _record(jobId, _repo.reviewClient(jobId, draft));

  Future<Result<Review, DataFailure>> _record(
    String jobId,
    Future<Result<Review, DataFailure>> write,
  ) async {
    final result = await write;
    if (result.isOk) {
      ref.read(reviewedJobsProvider.notifier).add(jobId);
      ref.invalidate(providerRatingProvider);
    }
    return result;
  }
}

final reviewActionsProvider = NotifierProvider<ReviewActions, void>(
  ReviewActions.new,
);
