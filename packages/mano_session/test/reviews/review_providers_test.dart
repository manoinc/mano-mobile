import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_session/mano_session.dart';

final class _Reviews implements ReviewRepository {
  Result<RatingSummary, DataFailure> rating = const Ok(
    RatingSummary(average: 4.5, count: 2),
  );
  Result<Review, DataFailure> written = Ok(
    Review(
      id: 'r1',
      reviewer: const Party(id: 'c', displayName: '', photoUrl: ''),
      stars: 5,
      date: DateTime(2026, 11, 2),
      text: '',
    ),
  );
  var ratingCalls = 0;
  final writes = <(String, String, int)>[];

  @override
  Future<Result<RatingSummary, DataFailure>> providerRating(String id) async {
    ratingCalls++;
    return rating;
  }

  @override
  Future<Result<ReviewPage, DataFailure>> providerReviews(
    String id, {
    String? after,
  }) async => const Ok(ReviewPage(items: []));

  @override
  Future<Result<Review, DataFailure>> reviewProvider(
    String jobId,
    ReviewDraft draft,
  ) async {
    writes.add(('provider', jobId, draft.stars));
    return written;
  }

  @override
  Future<Result<Review, DataFailure>> reviewClient(
    String jobId,
    ReviewDraft draft,
  ) async {
    writes.add(('client', jobId, draft.stars));
    return written;
  }
}

void main() {
  late _Reviews reviews;
  late ProviderContainer container;

  setUp(() {
    reviews = _Reviews();
    container = ProviderContainer.test(
      overrides: [reviewRepositoryProvider.overrideWithValue(reviews)],
    );
  });

  test('a provider rating reads through the port', () async {
    expect(
      await container.read(providerRatingProvider('w1').future),
      const RatingSummary(average: 4.5, count: 2),
    );
  });

  test(
    'a rating that cannot be read shows as none rather than an error',
    () async {
      reviews.rating = const Err(DataUnavailable());
      expect(
        await container.read(providerRatingProvider('w1').future),
        RatingSummary.none,
      );
    },
  );

  test('rating a job marks it reviewed and refreshes the rating', () async {
    await container.read(providerRatingProvider('w1').future);
    final actions = container.read(reviewActionsProvider.notifier);

    final result = await actions.reviewProvider(
      'j1',
      const ReviewDraft(stars: 5),
    );
    await container.read(providerRatingProvider('w1').future);

    expect(result.isOk, isTrue);
    expect(reviews.writes, [('provider', 'j1', 5)]);
    expect(container.read(reviewedJobsProvider), {'j1'});
    expect(reviews.ratingCalls, 2);
  });

  test('a refused rating leaves the job unreviewed', () async {
    reviews.written = const Err(DataRejected(reason: 'FailedPrecondition: x'));
    final actions = container.read(reviewActionsProvider.notifier);

    final result = await actions.reviewClient(
      'j2',
      const ReviewDraft(stars: 3),
    );

    expect(result.failureOrNull!.isNotYetReviewable, isTrue);
    expect(reviews.writes, [('client', 'j2', 3)]);
    expect(container.read(reviewedJobsProvider), isEmpty);
  });

  test('offline the repository is the mock; live it is the gateway', () {
    ProviderContainer make(bool offline) => ProviderContainer.test(
      overrides: [
        manoConfigProvider.overrideWithValue(
          const ManoConfig(
            gatewayGraphQlUrl: 'http://gw/graphql',
            appRole: ManoRole.requester,
          ),
        ),
        offlineMarketplaceProvider.overrideWithValue(offline),
      ],
    );
    expect(
      make(true).read(reviewRepositoryProvider),
      isA<MockReviewRepository>(),
    );
    expect(
      make(false).read(reviewRepositoryProvider),
      isA<GatewayReviewRepository>(),
    );
    expect(
      make(true).read(providerDirectoryProvider),
      isA<MockProviderDirectory>(),
    );
  });
}
