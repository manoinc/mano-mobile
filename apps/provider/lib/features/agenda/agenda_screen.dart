import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'agenda_labels.dart';
import 'agenda_load_error.dart';

enum _Filter {
  upcoming('Próximos', 'No tienes trabajos próximos.'),
  inProgress('En curso', 'Ningún trabajo está en curso.'),
  history('Historial', 'Aún no tienes historial.');

  const _Filter(this.label, this.emptyMessage);

  final String label;
  final String emptyMessage;
}

/// The provider's jobs: what's next, what's happening, what's over.
class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  _Filter _filter = _Filter.upcoming;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            ManoSpacing.md,
            ManoSpacing.md,
            ManoSpacing.md,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Agenda', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: ManoSpacing.md),
              ManoProjectFilterTabs(
                labels: [for (final f in _Filter.values) f.label],
                selectedIndex: _filter.index,
                onSelected: (i) => setState(() => _filter = _Filter.values[i]),
              ),
              const SizedBox(height: ManoSpacing.md),
              Expanded(child: _AgendaList(filter: _filter)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgendaList extends ConsumerWidget {
  const _AgendaList({required this.filter});

  final _Filter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(switch (filter) {
      _Filter.upcoming => upcomingJobsProvider,
      _Filter.inProgress => jobsByStatusProvider(JobStatus.inProgress),
      _Filter.history => jobHistoryProvider,
    });

    return switch (jobs) {
      AsyncData(value: final jobs) when jobs.isEmpty => ManoEmptyState(
        icon: Icons.event_available_outlined,
        message: filter.emptyMessage,
        ctaLabel: 'Ver solicitudes',
        onCta: () => context.go('/home'),
      ),
      AsyncData(value: final jobs) => ListView(
        padding: const EdgeInsets.only(bottom: ManoSpacing.lg),
        children: filter == _Filter.upcoming
            ? _byDay(context, jobs)
            : [for (final job in jobs) _JobCard(job: job, timeOnly: false)],
      ),
      AsyncError() => AgendaLoadError(
        message: 'No pudimos cargar tu agenda.',
        onRetry: () => ref.invalidate(myJobsProvider),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }

  List<Widget> _byDay(BuildContext context, List<Job> jobs) {
    final now = DateTime.now();
    final style = Theme.of(context).textTheme.titleSmall
        ?.copyWith(color: ManoColors.muted);
    return [
      for (final group in groupJobsByDay(jobs)) ...[
        Padding(
          padding: const EdgeInsets.only(
            top: ManoSpacing.sm,
            bottom: ManoSpacing.sm,
          ),
          child: Text(dayLabel(group.day, now), style: style),
        ),
        for (final job in group.jobs) _JobCard(job: job, timeOnly: true),
      ],
    ];
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job, required this.timeOnly});

  final Job job;

  // Under a day header the date would repeat itself.
  final bool timeOnly;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = jobBadge(job.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: ManoSpacing.sm),
      child: ManoProjectCard(
        key: Key('agenda-job-${job.id}'),
        title: job.serviceTitle,
        professionalName: job.client.displayName,
        professionalPhotoUrl: job.client.photoUrl,
        statusLabel: label,
        statusTone: tone,
        scheduledLabel: timeOnly
            ? ManoFormat.time(job.start)
            : ManoFormat.dateTime(job.start),
        priceLabel: shortPrice(job.amountCop, job.rateType),
        onTap: () => context.push('/agenda/job/${job.id}'),
      ),
    );
  }
}
