import 'package:mano_session/mano_session.dart';

/// A [ReviewRepository] that records writes and serves scripted reads.
final class FakeReviews implements ReviewRepository {
  FakeReviews({
    this.written,
    this.rating = RatingSummary.none,
    Map<String?, ReviewPage>? pages,
  }) : pages = pages ?? {null: const ReviewPage(items: [])};

  final Result<Review, DataFailure>? written;
  final RatingSummary rating;
  final Map<String?, ReviewPage> pages;
  final writes = <(String, String, int, String)>[];
  final reads = <(String, String?)>[];

  static Review review(String id, {String name = 'Ana Gómez', int stars = 5}) =>
      Review(
        id: id,
        reviewer: Party(id: 'c-$id', displayName: name, photoUrl: ''),
        stars: stars,
        date: DateTime(2026, 10, 20),
        text: 'Muy cumplido',
      );

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
  }) async {
    reads.add((providerId, after));
    return Ok(pages[after]!);
  }

  @override
  Future<Result<RatingSummary, DataFailure>> providerRating(
    String providerId,
  ) async => Ok(rating);

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
