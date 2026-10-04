import 'package:mano_session/mano_session.dart';

const fakeService = JobService(
  id: 'service-cleaning',
  category: 'cleaning',
  title: 'Limpieza profunda',
  description: '',
);

const fakeOffer = ServiceOffer(
  id: 'offer-1',
  jobServiceId: 'service-cleaning',
  offerantId: 'provider-1',
  rateType: RateType.fixed,
  amountCop: 120000,
  zone: 'Chapinero',
  status: OfferStatus.active,
);

/// A catalog that knows one service and the offers it is handed.
final class FakeServiceCatalog implements ServiceCatalog {
  FakeServiceCatalog({this.offers = const [fakeOffer]});

  final List<ServiceOffer> offers;

  @override
  Future<List<JobService>> search({String? category, String? text}) async => [
    fakeService,
  ];

  @override
  Future<JobService?> service(String id) async =>
      id == fakeService.id ? fakeService : null;

  @override
  Future<ServiceOffer?> offer(String id) async {
    for (final o in offers) {
      if (o.id == id) return o;
    }
    return null;
  }

  @override
  Future<List<ServiceOffer>> offersFor(String jobServiceId) async => offers;
}

/// Tomorrow at 9 is bookable, 10 is taken; nothing else in the window.
final class FakeAvailability implements AvailabilityRepository {
  static DateTime get tomorrow {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }

  static DateTime get openSlot => tomorrow.add(const Duration(hours: 9));
  static DateTime get takenSlot => tomorrow.add(const Duration(hours: 10));

  @override
  Future<List<AvailableSlot>> slotsFor(
    String workerId, {
    required DateTime from,
    required DateTime to,
  }) async => [
    AvailableSlot(
      start: openSlot,
      end: openSlot.add(const Duration(hours: 1)),
      bookable: true,
    ),
    AvailableSlot(
      start: takenSlot,
      end: takenSlot.add(const Duration(hours: 1)),
      bookable: false,
    ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Every booking and request is refused by the backend.
final class FailingJobs implements JobRepository {
  @override
  Future<Result<Job, DataFailure>> bookSlot(String offerId, DateTime s) async =>
      const Err(DataUnavailable());

  @override
  Future<List<Job>> mine({JobStatus? status}) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
