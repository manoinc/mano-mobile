import 'package:mano_domain/mano_domain.dart';

import '../mock/mock_fixtures.dart';

const _pageSize = 20;

/// In-memory [ReviewRepository] with a few reviews for each mock provider.
final class MockReviewRepository implements ReviewRepository {
  MockReviewRepository({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final Map<String, Review> _written = {};
  int _next = 1;

  // (provider, client, stars, days ago, text)
  static const _seed = [
    (
      'provider-1',
      0,
      5,
      2,
      'Llegó a la hora y dejó todo impecable. Lo recomiendo.',
    ),
    (
      'provider-1',
      1,
      5,
      9,
      'Resolvió la fuga en una hora y explicó todo con paciencia.',
    ),
    (
      'provider-1',
      2,
      4,
      21,
      'Muy buen trabajo, solo se demoró un poco en llegar.',
    ),
    ('provider-1', 3, 5, 40, 'Ordenado y amable. Volvería a contratarlo.'),
    ('provider-2', 4, 5, 5, 'Súper cuidadosa con los muebles. Quedó perfecto.'),
    ('provider-2', 1, 4, 30, 'Buen servicio, buen precio.'),
  ];

  List<Review> _reviewsOf(String providerId) {
    final today = _now();
    return [
      for (final (i, (provider, client, stars, ago, text)) in _seed.indexed)
        if (provider == providerId)
          Review(
            id: 'seed-$i',
            reviewer: mockClients[client],
            stars: stars,
            date: today.subtract(Duration(days: ago)),
            text: text,
          ),
    ];
  }

  @override
  Future<Result<Review, DataFailure>> reviewProvider(
    String jobId,
    ReviewDraft draft,
  ) async => _write('provider:$jobId', draft, mockClient);

  @override
  Future<Result<Review, DataFailure>> reviewClient(
    String jobId,
    ReviewDraft draft,
  ) async => _write('client:$jobId', draft, mockProviders.first);

  @override
  Future<Result<ReviewPage, DataFailure>> providerReviews(
    String providerId, {
    String? after,
  }) async {
    final all = _reviewsOf(providerId);
    final start = int.tryParse(after ?? '') ?? 0;
    final end = (start + _pageSize).clamp(0, all.length);
    return Ok(
      ReviewPage(
        items: all.sublist(start.clamp(0, all.length), end),
        nextCursor: end < all.length ? '$end' : null,
      ),
    );
  }

  @override
  Future<Result<RatingSummary, DataFailure>> providerRating(
    String providerId,
  ) async => Ok(RatingSummary.of(_reviewsOf(providerId)));

  // Write-once like the service: a repeat returns what was stored first.
  Result<Review, DataFailure> _write(String key, ReviewDraft draft, Party me) {
    if (!draft.isValid) {
      return Err(DataRejected(reason: 'invalid draft: ${draft.problems}'));
    }
    return Ok(
      _written.putIfAbsent(
        key,
        () => Review(
          id: 'review-${_next++}',
          reviewer: me,
          stars: draft.stars,
          date: _now(),
          text: draft.comment.trim(),
        ),
      ),
    );
  }
}
