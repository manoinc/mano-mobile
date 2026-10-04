import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_domain/mano_domain.dart';

import '../activity/activity_providers.dart';
import '../marketplace_providers.dart';

/// Scheduled jobs, soonest first.
final upcomingJobsProvider = FutureProvider<List<Job>>((ref) async {
  final jobs = await ref.watch(
    jobsByStatusProvider(JobStatus.scheduled).future,
  );
  return [...jobs]..sort((a, b) => a.start.compareTo(b.start));
});

/// Finished and cancelled jobs, newest first.
final jobHistoryProvider = FutureProvider<List<Job>>((ref) async {
  final jobs = await ref.watch(myJobsProvider.future);
  return [
    for (final job in jobs)
      if (job.status == JobStatus.finished || job.status == JobStatus.cancelled)
        job,
  ]..sort((a, b) => b.start.compareTo(a.start));
});

typedef JobDay = ({DateTime day, List<Job> jobs});

/// Splits already-sorted [jobs] into one group per calendar day.
List<JobDay> groupJobsByDay(List<Job> jobs) {
  final groups = <JobDay>[];
  for (final job in jobs) {
    final day = DateTime(job.start.year, job.start.month, job.start.day);
    if (groups.isNotEmpty && groups.last.day == day) {
      groups.last.jobs.add(job);
    } else {
      groups.add((day: day, jobs: [job]));
    }
  }
  return groups;
}

/// Where the hour logger reads "now"; overridden in tests.
final agendaClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// The provider's job lifecycle; each success invalidates every job read.
final class AgendaActions extends Notifier<void> {
  @override
  void build() {}

  Future<Result<Job, DataFailure>> start(String id) =>
      _refreshOnOk(ref.read(jobRepositoryProvider).start(id));

  Future<Result<Job, DataFailure>> finish(String id, {double? actualHours}) =>
      _refreshOnOk(
        ref.read(jobRepositoryProvider).finish(id, actualHours: actualHours),
      );

  Future<Result<Job, DataFailure>> _refreshOnOk(
    Future<Result<Job, DataFailure>> call,
  ) async {
    final result = await call;
    if (result.isOk) {
      ref
        ..invalidate(myJobsProvider)
        ..invalidate(jobProvider);
    }
    return result;
  }
}

final agendaActionsProvider = NotifierProvider<AgendaActions, void>(
  AgendaActions.new,
);
