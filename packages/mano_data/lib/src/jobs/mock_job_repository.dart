import 'package:mano_domain/mano_domain.dart';

import '../mock/mock_fixtures.dart';

/// In-memory [JobRepository] enforcing the domain's lifecycle rules.
final class MockJobRepository implements JobRepository {
  MockJobRepository({DateTime Function()? now}) : _now = now ?? DateTime.now {
    final today = _now();
    DateTime at(int days, int hour) =>
        DateTime(today.year, today.month, today.day + days, hour);
    _jobs.addAll([
      _make('job-1', mockOffers[0], JobStatus.scheduled, at(2, 9)),
      _make('job-2', mockOffers[1], JobStatus.scheduled, at(4, 14)),
      _make('job-3', mockOffers[1], JobStatus.inProgress, at(0, 8)),
      _make('job-4', mockOffers[0], JobStatus.inProgress, at(0, 7)),
      _make('job-5', mockOffers[0], JobStatus.finished, at(-7, 10)),
      _make('job-6', mockOffers[2], JobStatus.cancelled, at(-3, 15)),
    ]);
  }

  final DateTime Function() _now;
  final List<Job> _jobs = [];
  int _nextId = 100;

  Job _make(String id, ServiceOffer offer, JobStatus status, DateTime start) =>
      Job(
        id: id,
        offerId: offer.id,
        serviceTitle: mockTitleFor(offer),
        client: mockClient,
        provider: mockProviderFor(offer),
        rateType: offer.rateType,
        amountCop: offer.amountCop,
        start: start,
        end: start.add(const Duration(hours: 2)),
        status: status,
      );

  @override
  Future<List<Job>> mine({JobStatus? status}) async =>
      _jobs.where((j) => status == null || j.status == status).toList();

  @override
  Future<Job?> job(String id) async {
    for (final j in _jobs) {
      if (j.id == id) return j;
    }
    return null;
  }

  @override
  Future<Result<Job, DataFailure>> bookSlot(
    String offerId,
    DateTime slotStart,
  ) async {
    final job = _make(
      'job-${_nextId++}',
      mockOfferById(offerId),
      JobStatus.scheduled,
      slotStart,
    );
    _jobs.insert(0, job);
    return Ok(job);
  }

  @override
  Future<Result<Job, DataFailure>> start(String id) async => _change(
    id,
    (j) => j.canStart,
    (j) => j.copyWith(status: JobStatus.inProgress),
  );

  @override
  Future<Result<Job, DataFailure>> finish(
    String id, {
    double? actualHours,
  }) async {
    final job = await this.job(id);
    if (job != null &&
        job.requiresHoursOnFinish &&
        (actualHours == null || actualHours <= 0)) {
      return const Err(DataRejected(reason: 'hourly jobs need actual hours'));
    }
    return _change(
      id,
      (j) => j.canFinish,
      (j) => j.copyWith(status: JobStatus.finished, actualHours: actualHours),
    );
  }

  @override
  Future<Result<Job, DataFailure>> cancel(String id, {String? reason}) async =>
      _change(
        id,
        (j) => j.canCancel,
        (j) => j.copyWith(status: JobStatus.cancelled),
      );

  @override
  Future<Result<ServiceRequest, DataFailure>> rebook(String jobId) async {
    final job = await this.job(jobId);
    if (job == null) return const Err(DataNotFound());
    if (!job.canRebook) {
      return Err(DataRejected(reason: 'job is ${job.status}'));
    }
    return Ok(
      ServiceRequest(
        id: 'request-${_nextId++}',
        offer: mockOfferById(job.offerId),
        serviceTitle: job.serviceTitle,
        client: job.client,
        provider: job.provider,
        message: 'Quiero volver a contratar este servicio.',
        status: ServiceRequestStatus.pending,
        createdAt: _now(),
      ),
    );
  }

  Result<Job, DataFailure> _change(
    String id,
    bool Function(Job) allowed,
    Job Function(Job) change,
  ) {
    final index = _jobs.indexWhere((j) => j.id == id);
    if (index < 0) return const Err(DataNotFound());
    if (!allowed(_jobs[index])) {
      return Err(DataRejected(reason: 'job is ${_jobs[index].status}'));
    }
    return Ok(_jobs[index] = change(_jobs[index]));
  }
}
