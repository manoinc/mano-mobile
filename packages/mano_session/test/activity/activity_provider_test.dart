import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_session/mano_session.dart';

final _now = DateTime(2026, 10, 4, 12);

ProviderContainer _container({bool projectsFail = false}) =>
    ProviderContainer.test(
      overrides: [
        offlineMarketplaceProvider.overrideWithValue(true),
        jobRepositoryProvider.overrideWithValue(
          MockJobRepository(now: () => _now),
        ),
        serviceRequestRepositoryProvider.overrideWithValue(
          MockServiceRequestRepository(now: () => _now),
        ),
        if (projectsFail)
          myProjectsProvider.overrideWith(
            (ref) async => throw StateError('offline'),
          ),
      ],
    );

String _id(ActivityItem item) => switch (item) {
  RequestActivity(:final request) => request.id,
  JobActivity(:final job) => job.id,
  ProjectActivity(:final project) => project.id,
};

void main() {
  test('each bucket merges requests, jobs and projects', () async {
    final c = _container();
    final pending = await c.read(
      activityProvider(ActivityBucket.pending).future,
    );
    final active = await c.read(activityProvider(ActivityBucket.active).future);
    final history = await c.read(
      activityProvider(ActivityBucket.history).future,
    );

    expect(pending.whereType<RequestActivity>(), isNotEmpty);
    expect(pending.whereType<ProjectActivity>(), isNotEmpty);
    expect(active.whereType<JobActivity>(), isNotEmpty);
    expect(active.whereType<ProjectActivity>(), isNotEmpty);
    expect(history.map(_id), containsAll(['job-5', 'job-6', 'request-4']));
    for (final (bucket, items) in [
      (ActivityBucket.pending, pending),
      (ActivityBucket.active, active),
      (ActivityBucket.history, history),
    ]) {
      expect(items.every((i) => i.bucket == bucket), isTrue, reason: '$bucket');
    }
  });

  test('items run newest first', () async {
    final items = await _container().read(
      activityProvider(ActivityBucket.active).future,
    );
    final times = [for (final i in items) i.sortedAt];
    expect(times, [...times]..sort((a, b) => b.compareTo(a)));
  });

  test('a failing source fails the bucket', () async {
    final c = _container(projectsFail: true);
    await expectLater(
      c.read(activityProvider(ActivityBucket.pending).future),
      throwsA(anything),
    );
  });

  test('a cancelled request moves to history', () async {
    final c = _container();
    await c.read(activityProvider(ActivityBucket.history).future);

    await c.read(activityActionsProvider.notifier).cancelRequest('request-1');

    final history = await c.read(
      activityProvider(ActivityBucket.history).future,
    );
    expect(history.map(_id), contains('request-1'));
  });
}
