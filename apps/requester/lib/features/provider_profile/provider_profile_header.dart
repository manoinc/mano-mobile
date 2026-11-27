import 'package:flutter/material.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'rating_labels.dart';

/// Photo, name with the verified badge, and the rating at a glance.
class ProviderProfileHeader extends StatelessWidget {
  const ProviderProfileHeader({
    required this.profile,
    required this.rating,
    super.key,
  });

  final PublicProviderProfile profile;
  final RatingSummary rating;

  @override
  Widget build(BuildContext context) {
    final photo = profile.party.photoUrl;
    final average = rating.hasRatings ? rating.average : null;
    return Column(
      children: [
        ManoAvatar(photoUrl: photo.isEmpty ? null : photo, size: 96),
        const SizedBox(height: ManoSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                profile.party.nameOr('Profesional'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            if (profile.verified) ...[
              const SizedBox(width: ManoSpacing.xs),
              Icon(
                Icons.verified,
                size: 22,
                color: context.palette.clay,
                semanticLabel: 'Verificado',
              ),
            ],
          ],
        ),
        const SizedBox(height: ManoSpacing.md),
        ManoRatingSummary(
          average: average,
          averageLabel: average == null ? '' : ratingAverageText(average),
          countLabel: reviewsCountText(rating.count),
        ),
      ],
    );
  }
}
