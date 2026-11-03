import 'package:mano_session/mano_session.dart';

// Ratings -> Spanish (Colombia) copy, shared by cards, the profile and chat.

/// "4,9"
String ratingAverageText(double average) =>
    average.toStringAsFixed(1).replaceAll('.', ',');

/// "32 reseñas"
String reviewsCountText(int count) =>
    count == 1 ? '1 reseña' : '$count reseñas';

/// "4,9 · 32", or "Nuevo" before the first review.
String ratingBadgeText(RatingSummary rating) => rating.hasRatings
    ? '${ratingAverageText(rating.average!)} · ${rating.count}'
    : 'Nuevo';
