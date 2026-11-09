import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'profile_labels.dart';

/// Past performance as calm tiles; only what the backend serves is shown.
class StatsGrid extends ConsumerWidget {
  const StatsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(providerStatsProvider).value;
    if (stats == null) return const SizedBox.shrink();
    final rating = ref.watch(myRatingProvider).value ?? RatingSummary.none;
    final tiles = [
      ManoStatTile(
        value: ratingLabels(rating).average,
        label: 'Calificación',
        icon: Icons.star_rounded,
      ),
      if (stats.jobsCompleted case final jobs?)
        ManoStatTile(value: '$jobs', label: 'Trabajos completados'),
      if (stats.responseRatePct case final pct?)
        ManoStatTile(value: percentText(pct), label: 'Tasa de respuesta'),
      if (stats.completionRatePct case final pct?)
        ManoStatTile(value: percentText(pct), label: 'Trabajos cumplidos'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tu desempeño', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: ManoSpacing.md),
        for (var i = 0; i < tiles.length; i += 2) ...[
          if (i > 0) const SizedBox(height: ManoSpacing.sm),
          _row(tiles[i], i + 1 < tiles.length ? tiles[i + 1] : null),
        ],
      ],
    );
  }

  Widget _row(Widget a, Widget? b) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: a),
        const SizedBox(width: ManoSpacing.sm),
        Expanded(child: b ?? const SizedBox.shrink()),
      ],
    ),
  );
}
