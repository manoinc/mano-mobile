import 'review.dart';

/// A provider's standing: the average of their stars and how many there are.
final class RatingSummary {
  const RatingSummary({required this.average, required this.count});

  /// Averages [reviews] the way the reviews service does: half up, two decimals.
  factory RatingSummary.of(List<Review> reviews) {
    if (reviews.isEmpty) return none;
    final total = reviews.fold<int>(0, (sum, r) => sum + r.stars);
    final average = (total * 100 / reviews.length).round() / 100;
    return RatingSummary(average: average, count: reviews.length);
  }

  static const none = RatingSummary(average: null, count: 0);

  /// Null until the first review.
  final double? average;
  final int count;

  bool get hasRatings => average != null && count > 0;

  @override
  bool operator ==(Object other) =>
      other is RatingSummary &&
      other.average == average &&
      other.count == count;

  @override
  int get hashCode => Object.hash(average, count);

  @override
  String toString() => 'RatingSummary($average, $count)';
}
