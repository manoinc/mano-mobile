import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'profile_labels.dart';

/// The big total for a period, its bars and the way to the breakdown.
class EarningsSection extends ConsumerStatefulWidget {
  const EarningsSection({super.key});

  @override
  ConsumerState<EarningsSection> createState() => _EarningsSectionState();
}

class _EarningsSectionState extends ConsumerState<EarningsSection> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final period = periodAt(_selected);
    final summary = ref.watch(earningsProvider(period)).value;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ganancias', style: text.titleLarge),
        const SizedBox(height: ManoSpacing.md),
        ManoProjectFilterTabs(
          labels: periodNames,
          selectedIndex: _selected,
          onSelected: (i) => setState(() => _selected = i),
        ),
        const SizedBox(height: ManoSpacing.md),
        if (summary != null) ...[
          Text(
            ManoFormat.cop(summary.totalCop),
            key: const Key('earnings-total'),
            style: text.displaySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            payoutLine(summary.nextPayout),
            style: text.bodyMedium?.copyWith(color: context.palette.muted),
          ),
          const SizedBox(height: ManoSpacing.md),
          ManoBarChart(
            labels: chartLabels(summary),
            values: [for (final b in summary.buckets) b.amountCop],
            semanticLabel: 'Ganancias ${periodNames[_selected].toLowerCase()}',
          ),
          ManoTextAction(
            label: 'Ver desglose',
            onPressed: () =>
                context.push('/profile/earnings?period=${period.name}'),
          ),
        ],
      ],
    );
  }
}
