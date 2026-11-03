import 'dart:async';

import 'package:mano_session/mano_session.dart';

const fakeProvider = PublicProviderProfile(
  party: Party(id: 'w1', displayName: 'Ana Gómez', photoUrl: ''),
  bio: 'Plomera certificada.',
  verified: true,
  skills: ['Plomería', 'Remodelación'],
  portfolioUrls: ['https://example.com/1.jpg'],
);

Review fakeReview(String id, String text) => Review(
  id: id,
  reviewer: const Party(id: 'c1', displayName: 'Laura Pérez', photoUrl: ''),
  stars: 5,
  date: DateTime(2026, 10, 12),
  text: text,
);

/// A directory that answers [answer], or waits on [gate] when set.
final class FakeDirectory implements ProviderDirectory {
  FakeDirectory([this.answer = const Ok(fakeProvider)]);

  Result<PublicProviderProfile, DataFailure> answer;
  Completer<void>? gate;
  var calls = 0;

  @override
  Future<Result<PublicProviderProfile, DataFailure>> profile(String id) async {
    calls++;
    await gate?.future;
    return answer;
  }
}

/// Reviews with a fixed [rating] and [pages] keyed by cursor.
final class FakeReviews implements ReviewRepository {
  FakeReviews({
    this.rating = const RatingSummary(average: 4.9, count: 32),
    Map<String?, ReviewPage>? pages,
  }) : pages =
           pages ??
           {
             null: ReviewPage(
               items: [
                 fakeReview('r1', 'Llegó a la hora.'),
                 fakeReview('r2', 'Muy ordenada.'),
                 fakeReview('r3', 'Excelente trabajo.'),
                 fakeReview('r4', 'Volvería a contratarla.'),
               ],
               nextCursor: '4',
             ),
             '4': ReviewPage(items: [fakeReview('r5', 'La recomiendo.')]),
           };

  final RatingSummary rating;
  final Map<String?, ReviewPage> pages;

  @override
  Future<Result<RatingSummary, DataFailure>> providerRating(String id) async =>
      Ok(rating);

  @override
  Future<Result<ReviewPage, DataFailure>> providerReviews(
    String id, {
    String? after,
  }) async => Ok(pages[after] ?? const ReviewPage(items: []));

  @override
  Future<Result<Review, DataFailure>> reviewProvider(String j, ReviewDraft d) =>
      throw UnimplementedError();

  @override
  Future<Result<Review, DataFailure>> reviewClient(String j, ReviewDraft d) =>
      throw UnimplementedError();
}
