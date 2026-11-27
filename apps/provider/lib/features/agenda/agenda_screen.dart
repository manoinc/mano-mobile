import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../availability/availability_labels.dart';
import '../availability/availability_view.dart';
import 'agenda_labels.dart';
import 'agenda_load_error.dart';
import '../account/account_gate.dart';

enum AgendaTab {
  calendar('Calendario', ''),
  availability('Disponibilidad', ''),
  inProgress('En curso', 'Ningún trabajo está en curso.'),
  history('Historial', 'Aún no tienes historial.');

  const AgendaTab(this.label, this.emptyMessage);

  final String label;
  final String emptyMessage;
}

/// The provider's jobs and availability: a calendar of what's coming and what's blocked, plus what's over.
class AgendaScreen extends ConsumerStatefulWidget {
  const AgendaScreen({this.initialTab = AgendaTab.calendar, super.key});

  final AgendaTab initialTab;

  @override
  ConsumerState<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends ConsumerState<AgendaScreen> {
  late AgendaTab _tab = widget.initialTab;

  // Jobs and availability together: the calendar shows both.
  Future<void> _refresh() async {
    await Future.wait([
      ref.refresh(myJobsProvider.future),
      ref.refresh(myCalendarBlocksProvider.future),
      if (_tab == AgendaTab.availability) ...[
        ref.refresh(myAvailabilityRulesProvider.future),
        ref.refresh(myCalendarFeedProvider.future),
      ],
    ]);
  }

  @override
  void didUpdateWidget(AgendaScreen old) {
    super.didUpdateWidget(old);
    if (old.initialTab != widget.initialTab) _tab = widget.initialTab;
  }

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
                labels: [for (final t in AgendaTab.values) t.label],
                selectedIndex: _tab.index,
                onSelected: (i) => setState(() => _tab = AgendaTab.values[i]),
              ),
              const SizedBox(height: ManoSpacing.md),
              Expanded(
                child: ManoPullToRefresh(
                  onRefresh: _refresh,
                  child: switch (_tab) {
                    AgendaTab.calendar => const _CalendarView(),
                    AgendaTab.availability => const AvailabilityView(),
                    _ => _StatusList(tab: _tab),
                  },
                ),
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
      _ => const ManoSkeletonList(),
    };
  }

  Future<void> _block() => requireAccount(
    context,
    ref,
    reason: AccountReason.availability,
    action: _blockNow,
  );

  Future<void> _unblock(CalendarBlock block) => requireAccount(
    context,
    ref,
    reason: AccountReason.availability,
    action: () => _unblockNow(block),
  );

  Future<void> _blockNow() => _report(
    ref
        .read(availabilityActionsProvider.notifier)
        .block(
          _selected,
          DateTime(_selected.year, _selected.month, _selected.day + 1),
        ),
  );

  Future<void> _unblockNow(CalendarBlock block) =>
      _report(ref.read(availabilityActionsProvider.notifier).unblock(block.id));

  Future<void> _report(Future<Result<Object?, DataFailure>> pending) async {
    final messenger = ScaffoldMessenger.of(context);
    if (await pending case Err(:final failure)) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  Widget _content(BuildContext context, List<Job> jobs) {
    final byDay = {
      for (final group in groupJobsByDay(
        [...jobs]..sort((a, b) => a.start.compareTo(b.start)),
      ))
        group.day: group.jobs,
    };
    final dayJobs = byDay[_selected] ?? const <Job>[];
    final blocks = ref.watch(myCalendarBlocksProvider).value ?? const [];
    final block = blockOn(_selected, blocks);
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.only(bottom: ManoSpacing.lg),
      children: [
        ManoMonthCalendar(
          month: _month,
          selected: _selected,
          markedDays: byDay.keys.toSet(),
          blockedDays: blockedDaysOf(blocks),
          onSelect: (day) => setState(() => _selected = day),
          onMonthChanged: (month) => setState(() => _month = month),
        ),
        const SizedBox(height: ManoSpacing.md),
        Row(
          children: [
            Expanded(
              child: Text(
                dayLabel(_selected, DateTime.now()),
                style: textTheme.titleSmall?.copyWith(
                  color: context.palette.muted,
                ),
              ),
            ),
            if (block != null)
              ManoTextAction(
                label: 'Desbloquear día',
                onPressed: () => _unblock(block),
              )
            else if (!_selected.isBefore(_today()))
              ManoTextAction(label: 'Bloquear día', onPressed: _block),
          ],
        ),
        if (block != null)
          Padding(
            padding: const EdgeInsets.only(bottom: ManoSpacing.sm),
            child: Text(
              'No recibirás reservas · ${blockLabel(block)}',
              key: const Key('agenda-blocked-note'),
              style: textTheme.bodyMedium?.copyWith(
                color: context.palette.faint,
              ),
            ),
          ),
        if (dayJobs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: ManoSpacing.lg),
            child: Text(
              'No tienes trabajos este día.',
              key: const Key('agenda-empty-day'),
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: context.palette.faint,
              ),
            ),
          ),
        for (final job in dayJobs) _JobCard(job: job, timeOnly: true),
      ],
    );
  }
}

class _StatusList extends ConsumerWidget {
  const _StatusList({required this.tab});

  final AgendaTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(switch (tab) {
      AgendaTab.inProgress => jobsByStatusProvider(JobStatus.inProgress),
      _ => jobHistoryProvider,
    });

    return switch (jobs) {
      AsyncData(value: final jobs) when jobs.isEmpty => ManoEmptyState(
        icon: Icons.event_available_outlined,
        message: tab.emptyMessage,
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
      _ => const ManoSkeletonList(),
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
        professionalName: job.clientName,
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
