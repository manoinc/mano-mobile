import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'agenda_labels.dart';
import 'agenda_load_error.dart';

enum _Filter {
  calendar('Calendario', ''),
  inProgress('En curso', 'Ningún trabajo está en curso.'),
  history('Historial', 'Aún no tienes historial.');

  const _Filter(this.label, this.emptyMessage);

  final String label;
  final String emptyMessage;
}

/// The provider's jobs: a calendar of what's coming, plus what's happening and what's over.
class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  _Filter _filter = _Filter.calendar;

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
              Expanded(
                child: _filter == _Filter.calendar
                    ? const _CalendarView()
                    : _StatusList(filter: _filter),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarView extends ConsumerStatefulWidget {
  const _CalendarView();

  @override
  ConsumerState<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<_CalendarView> {
  late DateTime _selected = _today();
  late DateTime _month = DateTime(_selected.year, _selected.month);

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    return switch (ref.watch(myJobsProvider)) {
      AsyncData(value: final jobs) => _content(context, jobs),
      AsyncError() => AgendaLoadError(
        message: 'No pudimos cargar tu agenda.',
        onRetry: () => ref.invalidate(myJobsProvider),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }

  Widget _content(BuildContext context, List<Job> jobs) {
    final byDay = {
      for (final group in groupJobsByDay(
        [...jobs]..sort((a, b) => a.start.compareTo(b.start)),
      ))
        group.day: group.jobs,
    };
    final dayJobs = byDay[_selected] ?? const <Job>[];
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.only(bottom: ManoSpacing.lg),
      children: [
        ManoMonthCalendar(
          month: _month,
          selected: _selected,
          markedDays: byDay.keys.toSet(),
          onSelect: (day) => setState(() => _selected = day),
          onMonthChanged: (month) => setState(() => _month = month),
        ),
        const SizedBox(height: ManoSpacing.md),
        Text(
          dayLabel(_selected, DateTime.now()),
          style: textTheme.titleSmall?.copyWith(color: ManoColors.muted),
        ),
        const SizedBox(height: ManoSpacing.sm),
        if (dayJobs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: ManoSpacing.lg),
            child: Text(
              'No tienes trabajos este día.',
              key: const Key('agenda-empty-day'),
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(color: ManoColors.faint),
            ),
          ),
        for (final job in dayJobs) _JobCard(job: job, timeOnly: true),
      ],
    );
  }
}

class _StatusList extends ConsumerWidget {
  const _StatusList({required this.filter});

  final _Filter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(switch (filter) {
      _Filter.inProgress => jobsByStatusProvider(JobStatus.inProgress),
      _ => jobHistoryProvider,
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
        children: [for (final job in jobs) _JobCard(job: job, timeOnly: false)],
      ),
      AsyncError() => AgendaLoadError(
        message: 'No pudimos cargar tu agenda.',
        onRetry: () => ref.invalidate(myJobsProvider),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
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
