import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../activity/activity_labels.dart';
import '../activity/load_error.dart';

/// Historial de pedidos: finished and cancelled jobs, newest first.
class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(orderHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de pedidos')),
      body: switch (history) {
        AsyncData(value: final jobs) when jobs.isEmpty => ManoEmptyState(
          icon: Icons.history,
          message: 'Aquí verás los trabajos terminados y cancelados.',
          ctaLabel: 'Explorar servicios',
          onCta: () => context.go('/home'),
        ),
        AsyncData(value: final jobs) => ManoPullToRefresh(
          onRefresh: () => ref.refresh(myJobsProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(ManoSpacing.md),
            children: [for (final job in jobs) _card(context, job)],
          ),
        ),
        AsyncError() => ActivityLoadError(
          message: 'No pudimos cargar tu historial.',
          onRetry: () => ref.invalidate(myJobsProvider),
        ),
        _ => const ManoSkeletonList(),
      },
    );
  }

  Widget _card(BuildContext context, Job job) {
    final (label, tone) = jobDetailBadge(job);
    return Padding(
      padding: const EdgeInsets.only(bottom: ManoSpacing.sm),
      child: ManoProjectCard(
        key: Key('history-job-${job.id}'),
        title: job.serviceTitle,
        professionalName: job.providerName,
        professionalPhotoUrl: job.provider.photoUrl,
        statusLabel: label,
        statusTone: tone,
        scheduledLabel: ManoFormat.dateTime(job.start),
        priceLabel: shortPrice(job.amountCop, job.rateType),
        onTap: () => context.push('/profile/history/job/${job.id}'),
      ),
    );
  }
}
