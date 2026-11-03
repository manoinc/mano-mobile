import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';

const _party = Party(id: 'w1', displayName: 'Ana', photoUrl: '');

const _profile = PublicProviderProfile(
  party: _party,
  bio: 'Hola',
  verified: true,
);

Review _review(String id, int daysAgo) => Review(
  id: id,
  reviewer: const Party(id: 'c', displayName: 'Laura', photoUrl: ''),
  stars: 5,
  date: DateTime(2026, 11, 2).subtract(Duration(days: daysAgo)),
  text: 'Bien',
);

final class _Directory implements ProviderDirectory {
  Result<PublicProviderProfile, DataFailure> answer = const Ok(_profile);
  var calls = 0;

  @override
  Future<Result<PublicProviderProfile, DataFailure>> profile(String id) async {
    calls++;
    return answer;
  }
}

final class _Reviews implements ReviewRepository {
  Result<RatingSummary, DataFailure> rating = const Ok(
    RatingSummary(average: 4.9, count: 32),
  );
  Map<String?, Result<ReviewPage, DataFailure>> pages = {
    null: Ok(ReviewPage(items: [_review('a', 1)], nextCursor: '1')),
    '1': Ok(ReviewPage(items: [_review('b', 5)])),
  };
  final afters = <String?>[];

  @override
  Future<Result<RatingSummary, DataFailure>> providerRating(String id) async =>
      rating;

  @override
  Future<Result<ReviewPage, DataFailure>> providerReviews(
    String id, {
    String? after,
  }) async {
    afters.add(after);
    return pages[after]!;
  }

  @override
  Future<Result<Review, DataFailure>> reviewProvider(String j, ReviewDraft d) =>
      throw UnimplementedError();

  @override
  Future<Result<Review, DataFailure>> reviewClient(String j, ReviewDraft d) =>
      throw UnimplementedError();
}

void main() {
  late _Directory directory;
  late _Reviews reviews;
  late ProviderContainer container;

  setUp(() {
    directory = _Directory();
    reviews = _Reviews();
    container = ProviderContainer.test(
      overrides: [
        providerDirectoryProvider.overrideWithValue(directory),
        reviewRepositoryProvider.overrideWithValue(reviews),
      ],
    );
  });

  Future<ProviderProfileView?> view() {
    container.listen(providerProfileViewProvider('w1'), (_, _) {});
    return container.read(providerProfileViewProvider('w1').future);
  }

  group('providerProfileViewProvider', () {
    test('composes profile, rating and the first page of reviews', () async {
      final v = (await view())!;
      expect(v.profile, same(_profile));
      expect(v.rating, const RatingSummary(average: 4.9, count: 32));
      expect(v.reviews.items.map((r) => r.id), ['a']);
      expect(v.reviews.hasMore, isTrue);
    });

    test(
      'a provider the directory does not know is null, not an error',
      () async {
        directory.answer = const Err(DataNotFound());
        expect(await view(), isNull);
      },
    );

    test(
      'a directory outage is an error, shown without silent retries',
      () async {
        directory.answer = const Err(DataUnavailable());
        await expectLater(view(), throwsA(isA<DataUnavailable>()));
        expect(
          container.read(providerProfileViewProvider('w1')).hasError,
          isTrue,
        );
        expect(directory.calls, 1);
      },
    );

    test('ratings and reviews that cannot be read fall back to none', () async {
      reviews
        ..rating = const Err(DataUnavailable())
        ..pages = {null: const Err(DataUnavailable())};
      final v = (await view())!;
      expect(v.rating, RatingSummary.none);
      expect(v.reviews.items, isEmpty);
      expect(v.reviews.hasMore, isFalse);
    });
  });

  group('providerReviewsFeedProvider', () {
    ProviderReviewsFeed feed() =>
        container.read(providerReviewsFeedProvider('w1').notifier);

    Future<ReviewFeed> start() {
      container.listen(providerReviewsFeedProvider('w1'), (_, _) {});
      return container.read(providerReviewsFeedProvider('w1').future);
    }

    ReviewFeed current() =>
        container.read(providerReviewsFeedProvider('w1')).value!;

    test('starts on the first page', () async {
      final state = await start();
      expect(state.items.map((r) => r.id), ['a']);
      expect(state.hasMore, isTrue);
    });

    test('loadMore appends the next page with the cursor', () async {
      await start();
      await feed().loadMore();
      expect(current().items.map((r) => r.id), ['a', 'b']);
      expect(current().hasMore, isFalse);
      expect(reviews.afters, [null, '1']);
    });

    test('loadMore on the last page does nothing', () async {
      reviews.pages = {
        null: Ok(ReviewPage(items: [_review('a', 1)])),
      };
      await start();
      await feed().loadMore();
      expect(reviews.afters, [null]);
    });

    test('a failed next page keeps what is shown and allows a retry', () async {
      reviews.pages['1'] = const Err(DataUnavailable());
      await start();
      await feed().loadMore();
      expect(current().items.map((r) => r.id), ['a']);
      expect(current().hasMore, isTrue);
      expect(current().loadMoreFailed, isTrue);
      reviews.pages['1'] = Ok(ReviewPage(items: [_review('b', 5)]));
      await feed().loadMore();
      expect(current().items.map((r) => r.id), ['a', 'b']);
      expect(current().loadMoreFailed, isFalse);
    });

    test('a failed first page is an error', () async {
      reviews.pages = {null: const Err(DataUnavailable())};
      await expectLater(start(), throwsA(isA<DataUnavailable>()));
    });
  });
}
