import '../result.dart';
import '../shared/data_failure.dart';
import 'rating_summary.dart';
import 'review.dart';
import 'review_draft.dart';
import 'review_page.dart';

/// Ratings both sides leave once a job is finished, and a provider's record.
abstract interface class ReviewRepository {
  /// The requester rates the job's provider. Write-once: a repeat returns the first.
  Future<Result<Review, DataFailure>> reviewProvider(
    String jobId,
    ReviewDraft draft,
  );

  /// The provider rates the job's requester; only the two of them see it.
  Future<Result<Review, DataFailure>> reviewClient(
    String jobId,
    ReviewDraft draft,
  );

  /// Newest first; [after] is a previous page's cursor.
  Future<Result<ReviewPage, DataFailure>> providerReviews(
    String providerId, {
    String? after,
  });

  Future<Result<RatingSummary, DataFailure>> providerRating(String providerId);
}
