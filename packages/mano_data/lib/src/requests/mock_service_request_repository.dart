import 'package:mano_domain/mano_domain.dart';

import '../mock/mock_fixtures.dart';

/// In-memory [ServiceRequestRepository] with one request per status.
final class MockServiceRequestRepository implements ServiceRequestRepository {
  MockServiceRequestRepository({DateTime Function()? now, this.onAccepted})
    : _now = now ?? DateTime.now {
    final today = _now();
    _requests.addAll([
      _make(
        'request-1',
        mockOffers[0],
        ServiceRequestStatus.pending,
        '¿Podrías venir el sábado en la mañana?',
        today.add(const Duration(days: 3)),
      ),
      _make(
        'request-2',
        mockOffers[1],
        ServiceRequestStatus.pending,
        'Tengo una fuga debajo del lavaplatos.',
        today.add(const Duration(days: 1)),
      ),
      _make(
        'request-3',
        mockOffers[1],
        ServiceRequestStatus.accepted,
        'Revisión del calentador.',
        today.add(const Duration(days: 5)),
      ),
      _make(
        'request-4',
        mockOffers[0],
        ServiceRequestStatus.rejected,
        'Limpieza de alfombras.',
        today.subtract(const Duration(days: 2)),
        rejectionReason: 'No tengo disponibilidad esa semana.',
      ),
      _make(
        'request-5',
        mockOffers[0],
        ServiceRequestStatus.cancelled,
        'Limpieza después de mudanza.',
        today.subtract(const Duration(days: 6)),
      ),
    ]);
  }

  /// Lets the job store schedule accepted work, as the backend will.
  final void Function(ServiceRequest accepted)? onAccepted;
  final DateTime Function() _now;
  final List<ServiceRequest> _requests = [];
  int _nextId = 100;

  ServiceRequest _make(
    String id,
    ServiceOffer offer,
    ServiceRequestStatus status,
    String message,
    DateTime? proposedStart, {
    String? rejectionReason,
  }) => ServiceRequest(
    id: id,
    offer: offer,
    serviceTitle: mockTitleFor(offer),
    client: mockClient,
    provider: mockProviderFor(offer),
    message: message,
    proposedStart: proposedStart,
    status: status,
    rejectionReason: rejectionReason,
    createdAt: _now(),
  );

  @override
  Future<List<ServiceRequest>> mine({ServiceRequestStatus? status}) async =>
      _requests.where((r) => status == null || r.status == status).toList();

  @override
  Future<Result<ServiceRequest, DataFailure>> request(
    String offerId, {
    required String message,
    DateTime? proposedStart,
  }) async {
    final created = _make(
      'request-${_nextId++}',
      mockOfferById(offerId),
      ServiceRequestStatus.pending,
      message,
      proposedStart,
    );
    _requests.insert(0, created);
    return Ok(created);
  }

  @override
  Future<Result<ServiceRequest, DataFailure>> accept(String id) async {
    final result = _answer(id, ServiceRequestStatus.accepted);
    if (result case Ok(:final value)) onAccepted?.call(value);
    return result;
  }

  @override
  Future<Result<ServiceRequest, DataFailure>> reject(
    String id, {
    String? reason,
  }) async => _answer(id, ServiceRequestStatus.rejected, reason: reason);

  @override
  Future<Result<ServiceRequest, DataFailure>> cancel(String id) async =>
      _answer(id, ServiceRequestStatus.cancelled);

  Result<ServiceRequest, DataFailure> _answer(
    String id,
    ServiceRequestStatus status, {
    String? reason,
  }) {
    final index = _requests.indexWhere((r) => r.id == id);
    if (index < 0) return const Err(DataNotFound());
    if (!_requests[index].canRespond) {
      return Err(DataRejected(reason: 'request is ${_requests[index].status}'));
    }
    return Ok(
      _requests[index] = _requests[index].copyWith(
        status: status,
        rejectionReason: reason,
      ),
    );
  }
}
