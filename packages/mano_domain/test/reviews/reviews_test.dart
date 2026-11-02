import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

Review _review(int stars) => Review(
  id: 'r$stars',
  reviewer: const Party(id: 'p', displayName: '', photoUrl: ''),
  stars: stars,
  date: DateTime(2026, 11, 1),
  text: '',
);

void main() {
  group('ReviewDraft', () {
    test('needs a star rating', () {
      expect(const ReviewDraft().problems, {ReviewDraftProblem.noStars});
      expect(const ReviewDraft().isValid, isFalse);
    });

    test('takes one to five stars', () {
      for (final stars in [1, 3, 5]) {
        expect(ReviewDraft(stars: stars).isValid, isTrue);
      }
      expect(const ReviewDraft(stars: 6).problems, {
        ReviewDraftProblem.starsOutOfRange,
      });
      expect(const ReviewDraft(stars: -1).problems, {
        ReviewDraftProblem.starsOutOfRange,
      });
    });

    test('the comment is optional but capped at 4000 characters', () {
      expect(const ReviewDraft(stars: 4, comment: '').isValid, isTrue);
      expect(ReviewDraft(stars: 4, comment: 'a' * 4000).isValid, isTrue);
      expect(ReviewDraft(stars: 4, comment: 'a' * 4001).problems, {
        ReviewDraftProblem.commentTooLong,
      });
    });

    test('copyWith changes only what it is given', () {
      const draft = ReviewDraft(stars: 2, comment: 'ok');
      expect(
        draft.copyWith(stars: 5),
        const ReviewDraft(stars: 5, comment: 'ok'),
      );
      expect(
        draft.copyWith(comment: 'bien'),
        const ReviewDraft(stars: 2, comment: 'bien'),
      );
    });
  });

  group('RatingSummary', () {
    test('no reviews means no average', () {
      final summary = RatingSummary.of(const []);
      expect(summary.average, isNull);
      expect(summary.count, 0);
      expect(summary.hasRatings, isFalse);
      expect(summary, RatingSummary.none);
    });

    test('averages the stars, rounded half up to two decimals', () {
      final summary = RatingSummary.of([_review(5), _review(4), _review(4)]);
      expect(summary.count, 3);
      expect(summary.average, 4.33);
      expect(RatingSummary.of([_review(5), _review(4)]).average, 4.5);
      expect(
        RatingSummary.of([
          _review(5),
          _review(5),
          _review(4),
          _review(4),
          _review(4),
          _review(4),
          _review(4),
          _review(5),
        ]).average,
        4.38,
      );
    });
  });

  group('ReviewPage', () {
    test('has more while there is a cursor', () {
      expect(const ReviewPage(items: []).hasMore, isFalse);
      expect(const ReviewPage(items: [], nextCursor: 'c').hasMore, isTrue);
    });
  });

  group('isNotYetReviewable', () {
    test('is the reviews service refusing a job it has not seen finish', () {
      expect(
        const DataRejected(reason: 'FailedPrecondition: job not finished')
            .isNotYetReviewable,
        isTrue,
      );
      expect(
        const DataRejected(reason: 'PermissionDenied: x').isNotYetReviewable,
        isFalse,
      );
      expect(const DataUnavailable().isNotYetReviewable, isFalse);
    });
  });
}
