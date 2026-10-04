import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';

List<String> _ids(List<ServiceRequest> requests) => [
  for (final r in requests) r.id,
];

Future<List<String>> _idsIn(
  ProviderContainer c,
  ServiceRequestStatus status,
) async => _ids(await c.read(requestsByStatusProvider(status).future));

void main() {
  group('RequestActions', () {
    test('accept moves the request to accepted and schedules a job', () async {
      final c = ProviderContainer.test();
      await _idsIn(c, ServiceRequestStatus.pending);
      final jobsBefore = await c.read(myJobsProvider.future);

      final result = await c
          .read(requestActionsProvider.notifier)
          .accept('request-1');

      expect(result.valueOrNull?.status, ServiceRequestStatus.accepted);
      expect(
        await _idsIn(c, ServiceRequestStatus.pending),
        isNot(contains('request-1')),
      );
      expect(
        await _idsIn(c, ServiceRequestStatus.accepted),
        contains('request-1'),
      );
      final jobs = await c.read(myJobsProvider.future);
      expect(jobs.length, jobsBefore.length + 1);
    });

    test('reject stores the reason and refreshes the lists', () async {
      final c = ProviderContainer.test();
      await _idsIn(c, ServiceRequestStatus.rejected);

      final result = await c
          .read(requestActionsProvider.notifier)
          .reject('request-2', reason: 'Sin cupo');

      expect(result.valueOrNull?.rejectionReason, 'Sin cupo');
      expect(
        await _idsIn(c, ServiceRequestStatus.rejected),
        contains('request-2'),
      );
    });

    test('a failed accept reports the failure and leaves jobs alone', () async {
      final c = ProviderContainer.test();
      var jobBuilds = 0;
      c.listen(myJobsProvider, (_, _) => jobBuilds++);
      await c.read(myJobsProvider.future);
      final before = jobBuilds;

      final result = await c
          .read(requestActionsProvider.notifier)
          .accept('request-3');

      expect(result.failureOrNull, isA<DataRejected>());
      expect(jobBuilds, before);
    });
  });
}
