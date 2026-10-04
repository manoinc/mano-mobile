import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_session/mano_session.dart';

final class _FailingJobs implements JobRepository {
  int booked = 0;

  @override
  Future<Result<Job, DataFailure>> bookSlot(String offerId, DateTime s) async {
    booked++;
    return const Err(DataUnavailable());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FailingRequests implements ServiceRequestRepository {
  @override
  Future<Result<ServiceRequest, DataFailure>> request(
    String offerId, {
    required String message,
    DateTime? proposedStart,
  }) async => const Err(DataRejected());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ProviderContainer _container({
  JobRepository? jobs,
  ServiceRequestRepository? requests,
}) => ProviderContainer.test(
  overrides: [
    jobRepositoryProvider.overrideWithValue(jobs ?? MockJobRepository()),
    serviceRequestRepositoryProvider.overrideWithValue(
      requests ?? MockServiceRequestRepository(),
    ),
  ],
);

void main() {
  final slot = DateTime(2030, 1, 7, 9);

  ({ProviderContainer c, BookingNotifier n}) setUp0({
    JobRepository? jobs,
    ServiceRequestRepository? requests,
  }) {
    final c = _container(jobs: jobs, requests: requests);
    c.listen(bookingProvider('offer-1'), (_, _) {});
    return (c: c, n: c.read(bookingProvider('offer-1').notifier));
  }

  test('starts idle with a 14-day window from today', () {
    final (:c, n: _) = setUp0();
    final state = c.read(bookingProvider('offer-1'));
    final today = DateTime.now();
    expect(state.days, hasLength(14));
    expect(state.days.first, DateTime(today.year, today.month, today.day));
    expect(state.range.to, state.days.last.add(const Duration(days: 1)));
    expect(state.selectedDay, isNull);
    expect(state.selectedSlot, isNull);
    expect(state.status, isA<BookingIdle>());
  });

  test('picking a day clears the slot; picking a slot keeps the day', () {
    final (:c, :n) = setUp0();
    n.selectDay(DateTime(2030, 1, 7));
    n.selectSlot(slot);
    expect(c.read(bookingProvider('offer-1')).selectedSlot, slot);

    n.selectDay(DateTime(2030, 1, 8));
    final state = c.read(bookingProvider('offer-1'));
    expect(state.selectedDay, DateTime(2030, 1, 8));
    expect(state.selectedSlot, isNull);
  });

  test('confirm books the slot and refreshes my jobs', () async {
    final (:c, :n) = setUp0();
    final before = await c.read(myJobsProvider.future);
    n.selectDay(DateTime(2030, 1, 7));
    n.selectSlot(slot);

    await n.confirm();

    final status = c.read(bookingProvider('offer-1')).status;
    expect(status, isA<BookingBooked>());
    expect((status as BookingBooked).job.start, slot);
    final after = await c.read(myJobsProvider.future);
    expect(after.length, before.length + 1);
  });

  test('a failed booking keeps the selection and carries the failure', () async {
    final jobs = _FailingJobs();
    final (:c, :n) = setUp0(jobs: jobs);
    n.selectDay(DateTime(2030, 1, 7));
    n.selectSlot(slot);

    await n.confirm();

    final state = c.read(bookingProvider('offer-1'));
    expect(state.status, isA<BookingFailed>());
    expect((state.status as BookingFailed).failure, isA<DataUnavailable>());
    expect(state.selectedSlot, slot);
    expect(state.selectedDay, DateTime(2030, 1, 7));
  });

  test('confirm without a slot does nothing', () async {
    final jobs = _FailingJobs();
    final (:c, :n) = setUp0(jobs: jobs);
    await n.confirm();
    expect(jobs.booked, 0);
    expect(c.read(bookingProvider('offer-1')).status, isA<BookingIdle>());
  });

  test('propose sends a request and refreshes my requests', () async {
    final (:c, :n) = setUp0();
    final before = await c.read(myServiceRequestsProvider.future);
    final at = DateTime(2030, 1, 9, 15);

    await n.propose(message: '¿Puede ser en la tarde?', start: at);

    final status = c.read(bookingProvider('offer-1')).status;
    expect(status, isA<BookingRequested>());
    expect((status as BookingRequested).request.proposedStart, at);
    final after = await c.read(myServiceRequestsProvider.future);
    expect(after.length, before.length + 1);
  });

  test('a failed proposal reports its failure', () async {
    final (:c, :n) = setUp0(requests: _FailingRequests());
    await n.propose(message: 'Hola', start: DateTime(2030, 1, 9, 15));
    final status = c.read(bookingProvider('offer-1')).status;
    expect((status as BookingFailed).failure, isA<DataRejected>());
  });

  test('available slots are read for the worker and range', () async {
    final c = ProviderContainer.test(
      overrides: [
        availabilityRepositoryProvider.overrideWithValue(
          MockAvailabilityRepository(now: () => DateTime(2030, 1, 6)),
        ),
      ],
    );
    final slots = await c.read(
      availableSlotsProvider((
        workerId: 'provider-1',
        from: DateTime(2030, 1, 7),
        to: DateTime(2030, 1, 8),
      )).future,
    );
    expect(slots, isNotEmpty);
    expect(slots.every((s) => s.start.day == 7), isTrue);
  });
}
