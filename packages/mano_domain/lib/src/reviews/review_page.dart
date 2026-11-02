import 'review.dart';

/// One page of reviews, newest first.
final class ReviewPage {
  const ReviewPage({required this.items, this.nextCursor});

  final List<Review> items;

  /// Pass back as `after` for the next page; null on the last one.
  final String? nextCursor;

  bool get hasMore => nextCursor != null;
}
