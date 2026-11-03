import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

/// One review as a tile; a reviewer without a name is "Cliente".
ManoReviewTile reviewTile(Review review) {
  final photo = review.reviewer.photoUrl;
  return ManoReviewTile(
    name: review.reviewer.nameOr('Cliente'),
    photoUrl: photo.isEmpty ? null : photo,
    stars: review.stars,
    dateLabel: ManoFormat.dayMonth(review.date),
    text: review.text,
  );
}
