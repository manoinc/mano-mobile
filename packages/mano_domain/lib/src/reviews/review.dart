import '../shared/party.dart';

/// What one side of a finished job wrote about the other.
final class Review {
  const Review({
    required this.id,
    required this.reviewer,
    required this.stars,
    required this.date,
    required this.text,
  });

  final String id;
  final Party reviewer;
  final int stars;
  final DateTime date;
  final String text;
}
