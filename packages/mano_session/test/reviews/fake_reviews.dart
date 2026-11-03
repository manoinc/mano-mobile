import 'package:mano_session/mano_session.dart';

/// A scriptable [ReviewRepository] for the reviews tests.
final class FakeReviews implements ReviewRepository {
  Result<RatingSummary, DataFailure> rating = const Ok(
    RatingSummary(average: 4.5, count: 2),
  );
  Result<Review, DataFailure>? written;
  final pages = <String?, ReviewPage>{null: const ReviewPage(items: [])};
  final writes = <(String, String, int, String)>[];
  final reads = <(String, String?)>[];

  static Review review(String id, {int stars = 5}) => Review(
    id: id,
    reviewer: const Party(id: 'c', displayName: 'Ana', photoUrl: ''),
    stars: stars,
    date: DateTime(2026, 11, 2),
    text: 'Muy bien',
  );

  @override
  Future<Result<RatingSummary, DataFailure>> providerRating(String id) async =>
      rating;

  @override
  Future<Result<ReviewPage, DataFailure>> providerReviews(
    String id, {
    String? after,
  }) async {
    reads.add((id, after));
    return Ok(pages[after]!);
  }

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

  Result<Review, DataFailure> _write(
    String side,
    String jobId,
    ReviewDraft draft,
  ) {
    writes.add((side, jobId, draft.stars, draft.comment));
    return written ?? Ok(review('r-$jobId', stars: draft.stars));
  }
}
