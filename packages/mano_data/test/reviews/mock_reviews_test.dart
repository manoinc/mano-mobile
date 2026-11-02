import 'package:mano_data/mano_data.dart';
import 'package:mano_data/src/mock/mock_fixtures.dart';
import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

DateTime _clock() => DateTime(2026, 11, 2, 10);

void main() {
  group('MockReviewRepository', () {
    test(
      'seeded providers have reviews, newest first, and a matching rating',
      () async {
        final repo = MockReviewRepository(now: _clock);

        final page = (await repo.providerReviews('provider-1')).valueOrNull!;
        final rating = (await repo.providerRating('provider-1')).valueOrNull!;

        expect(page.items, isNotEmpty);
        for (var i = 1; i < page.items.length; i++) {
          expect(page.items[i].date.isAfter(page.items[i - 1].date), isFalse);
        }
        expect(rating, RatingSummary.of(page.items));
      },
    );

    test('an unknown provider has nothing yet', () async {
      final repo = MockReviewRepository(now: _clock);
      expect(
        (await repo.providerRating('nobody')).valueOrNull,
        RatingSummary.none,
      );
      expect(
        (await repo.providerReviews('nobody')).valueOrNull!.items,
        isEmpty,
      );
    });

    test('rating a provider is write-once per job', () async {
      final repo = MockReviewRepository(now: _clock);

      final first = (await repo.reviewProvider(
        'job-1',
        const ReviewDraft(stars: 5, comment: 'Excelente'),
      )).valueOrNull!;
      final again = (await repo.reviewProvider(
        'job-1',
        const ReviewDraft(stars: 1),
      )).valueOrNull!;

      expect(first.stars, 5);
      expect(again.id, first.id);
      expect(again.stars, 5);
    });

    test('both sides may rate the same job', () async {
      final repo = MockReviewRepository(now: _clock);

      final a = (await repo.reviewProvider(
        'job-1',
        const ReviewDraft(stars: 5),
      )).valueOrNull!;
      final b = (await repo.reviewClient(
        'job-1',
        const ReviewDraft(stars: 4),
      )).valueOrNull!;

      expect(a.id == b.id, isFalse);
    });

    test('an invalid draft is rejected', () async {
      final repo = MockReviewRepository(now: _clock);
      expect(
        (await repo.reviewClient('job-1', const ReviewDraft())).failureOrNull,
        isA<DataRejected>(),
      );
    });
  });

  group('MockProviderDirectory', () {
    test('knows every mock provider', () async {
      final directory = MockProviderDirectory();
      for (final party in mockProviders) {
        final profile = (await directory.profile(party.id)).valueOrNull!;
        expect(profile.party, party);
        expect(profile.bio, isNotEmpty);
        expect(profile.skills, isNotEmpty);
      }
    });

    test('an unknown id is not found', () async {
      expect(
        (await MockProviderDirectory().profile('nobody')).failureOrNull,
        isA<DataNotFound>(),
      );
    });
  });
}
