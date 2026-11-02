/// What is wrong with a [ReviewDraft]; the screen words it in Spanish.
enum ReviewDraftProblem { noStars, starsOutOfRange, commentTooLong }

// The reviews service's own limit, in characters.
const int _commentMax = 4000;

/// A rating being written for the other side of a finished job.
final class ReviewDraft {
  const ReviewDraft({this.stars = 0, this.comment = ''});

  /// One to five; zero while nothing is chosen.
  final int stars;
  final String comment;

  Set<ReviewDraftProblem> get problems => {
    if (stars == 0) ReviewDraftProblem.noStars,
    if (stars < 0 || stars > 5) ReviewDraftProblem.starsOutOfRange,
    if (comment.trim().length > _commentMax) ReviewDraftProblem.commentTooLong,
  };

  bool get isValid => problems.isEmpty;

  ReviewDraft copyWith({int? stars, String? comment}) =>
      ReviewDraft(stars: stars ?? this.stars, comment: comment ?? this.comment);

  @override
  bool operator ==(Object other) =>
      other is ReviewDraft && other.stars == stars && other.comment == comment;

  @override
  int get hashCode => Object.hash(stars, comment);

  @override
  String toString() => 'ReviewDraft($stars, ${comment.length} chars)';
}
