import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'profile_labels.dart';

/// The paid jobs behind an earnings total.
class EarningsBreakdownScreen extends ConsumerWidget {
  const EarningsBreakdownScreen({required this.period, super.key});

  final EarningsPeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(earningsProvider(period)).value;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(periodNames[period.index])),
      body: summary == null
          ? const Center(child: ManoLoader())
          : ListView(
              padding: const EdgeInsets.all(ManoSpacing.md),
              children: [
                Text(
                  ManoFormat.cop(summary.totalCop),
                  style: text.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  payoutLine(summary.nextPayout),
                  style: text.bodyMedium?.copyWith(color: ManoColors.muted),
                ),
                const SizedBox(height: ManoSpacing.lg),
                Text('Trabajos pagados', style: text.titleLarge),
                const SizedBox(height: ManoSpacing.sm),
                for (final job in summary.recent) _PaidJobRow(job: job),
              ],
            ),
    );
  }
}

class _PaidJobRow extends StatelessWidget {
  const _PaidJobRow({required this.job});

  final PaidJob job;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ManoSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.title, style: text.titleSmall),
                Text(
                  '${job.client} · ${ManoFormat.dayMonth(job.paidAt)}',
                  style: text.bodySmall?.copyWith(color: ManoColors.faint),
                ),
              ],
            ),
          ),
          Text(ManoFormat.cop(job.amountCop), style: text.titleSmall),
        ],
      ),
    );
  }
}
