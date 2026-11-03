import 'package:mano_session/mano_session.dart';

/// A [ReviewRepository] that records writes and answers [written].
final class FakeReviews implements ReviewRepository {
  FakeReviews({this.written});

  final Result<Review, DataFailure>? written;
  final writes = <(String, String, int, String)>[];

  @override
  Future<Result<Review, DataFailure>> reviewProvider(
    String jobId,
    ReviewDraft draft,
  ) async => _write('provider', jobId, draft);

  @override
  Future<Result<Review, DataFailure>> reviewClient(
    String jobId,
    ReviewDraft draft,
  ) async => _write('client', jobId, draft);

  @override
  Future<Result<ReviewPage, DataFailure>> providerReviews(
    String providerId, {
    String? after,
  }) async => const Ok(ReviewPage(items: []));

  @override
  Future<Result<RatingSummary, DataFailure>> providerRating(
    String providerId,
  ) async => const Ok(RatingSummary.none);

  Result<Review, DataFailure> _write(
    String side,
    String jobId,
    ReviewDraft draft,
  ) {
    writes.add((side, jobId, draft.stars, draft.comment));
    return written ??
        Ok(
          Review(
            id: 'r-$jobId',
            reviewer: const Party(id: 'me', displayName: '', photoUrl: ''),
            stars: draft.stars,
            date: DateTime(2026, 11, 2),
            text: draft.comment,
          ),
        );
  }
}
