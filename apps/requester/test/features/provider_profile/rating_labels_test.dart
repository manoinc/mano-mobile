import 'package:flutter_test/flutter_test.dart';
import 'package:mano_requester/features/provider_profile/rating_labels.dart';
import 'package:mano_session/mano_session.dart';

void main() {
  test('the average has one decimal and a comma', () {
    expect(ratingAverageText(4.75), '4,8');
    expect(ratingAverageText(5), '5,0');
  });

  test('reviews are counted in Spanish', () {
    expect(reviewsCountText(1), '1 reseña');
    expect(reviewsCountText(32), '32 reseñas');
  });

  test('a card badge reads average and count, or Nuevo', () {
    expect(
      ratingBadgeText(const RatingSummary(average: 4.9, count: 32)),
      '4,9 · 32',
    );
    expect(ratingBadgeText(RatingSummary.none), 'Nuevo');
  });
}
