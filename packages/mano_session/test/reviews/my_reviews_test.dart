import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';

import 'fake_reviews.dart';

void main() {
  late FakeReviews reviews;

  ProviderContainer make({String? subject = 'w1'}) => ProviderContainer.test(
    overrides: [
      reviewRepositoryProvider.overrideWithValue(reviews),
      currentUserProvider.overrideWithValue(
        subject == null
            ? null
            : AuthenticatedUser(subject: subject, roles: const {}),
      ),
    ],
  );

  setUp(() {
    reviews = FakeReviews()
      ..pages[null] = ReviewPage(
        items: [FakeReviews.review('a')],
        nextCursor: 'c1',
      )
      ..pages['c1'] = ReviewPage(items: [FakeReviews.review('b')]);
  });

  test('my reviews are the signed-in provider\'s first page', () async {
    final container = make();

    final feed = await container.read(myReviewsProvider.future);

    expect(reviews.reads, [('w1', null)]);
    expect(feed.items.map((r) => r.id), ['a']);
    expect(feed.hasMore, isTrue);
  });

  test('more appends the next page and stops at the last', () async {
    final container = make();
    await container.read(myReviewsProvider.future);

    await container.read(myReviewsProvider.notifier).loadMore();

    final feed = container.read(myReviewsProvider).value!;
    expect(reviews.reads.last, ('w1', 'c1'));
    expect(feed.items.map((r) => r.id), ['a', 'b']);
    expect(feed.hasMore, isFalse);
  });

  test('a guest has no reviews to read', () async {
    final container = make(subject: null);

    expect((await container.read(myReviewsProvider.future)).items, isEmpty);
    expect(await container.read(myRatingProvider.future), RatingSummary.none);
    expect(reviews.reads, isEmpty);
  });

  test('my rating reads the signed-in provider\'s summary', () async {
    final container = make();

    expect(
      await container.read(myRatingProvider.future),
      const RatingSummary(average: 4.5, count: 2),
    );
  });
}
