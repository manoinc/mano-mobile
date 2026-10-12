import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'profile_labels.dart';

/// Past performance as four calm tiles.
class StatsGrid extends ConsumerWidget {
  const StatsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(providerStatsProvider).value;
    if (stats == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tu desempeño', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: ManoSpacing.md),
        _row(
          ManoStatTile(
            value: ratingText(stats.rating),
            label: 'Calificación',
            icon: Icons.star_rounded,
          ),
          ManoStatTile(
            value: '${stats.jobsCompleted}',
            label: 'Trabajos completados',
          ),
        ),
        const SizedBox(height: ManoSpacing.sm),
        _row(
          ManoStatTile(
            value: percentText(stats.responseRatePct),
            label: 'Tasa de respuesta',
          ),
          ManoStatTile(
            value: percentText(stats.completionRatePct),
            label: 'Trabajos cumplidos',
          ),
        ),
      ],
    );
  }

  Widget _row(Widget a, Widget b) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: a),
        const SizedBox(width: ManoSpacing.sm),
        Expanded(child: b),
      ],
    ),
  );
}
