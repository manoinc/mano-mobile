import 'package:mano_domain/mano_domain.dart';

import '../mock/mock_fixtures.dart';

/// In-memory [ServiceRequestRepository]: realistic leads per category plus one per other status.
final class MockServiceRequestRepository implements ServiceRequestRepository {
  MockServiceRequestRepository({DateTime Function()? now, this.onAccepted})
    : _now = now ?? DateTime.now {
    final today = _now();
    _requests.addAll([
      _make(
        'request-1',
        mockOffers[0],
        ServiceRequestStatus.pending,
        'Acabamos de mudarnos y el apartamento quedó con polvo y residuos de '
            'obra. Necesito limpieza profunda de 2 habitaciones y 2 baños.',
        today.add(const Duration(days: 3)),
        category: ServiceCategories.cleaning,
        title: 'Limpieza profunda post-mudanza',
        neighborhood: 'Chapinero',
        photos: ['1527515637462-cff94eecc1ac', '1581578731548-c64695cc6952'],
      ),
      _make(
        'request-2',
        mockOffers[1],
        ServiceRequestStatus.pending,
        'Se me está filtrando el lavaplatos de la cocina, gotea debajo del '
            'mueble y ya se humedeció la madera.',
        today.add(const Duration(days: 1)),
        client: mockClients[1],
        category: ServiceCategories.plumbing,
        title: 'Fuga debajo del lavaplatos',
        neighborhood: 'Laureles',
        photos: ['1607472586893-edb57bdc0e39', '1558618666-fcd25c85cd64'],
      ),
      _make(
        'request-6',
        mockOffers[1],
        ServiceRequestStatus.pending,
        'Se fue la luz en dos tomas de la sala y el breaker se baja cada vez '
            'que prendo el aire. Necesito revisar el tablero.',
        today.add(const Duration(days: 2)),
        client: mockClients[2],
        category: ServiceCategories.electrical,
        title: 'Revisión de tablero y tomas',
        neighborhood: 'El Poblado',
        photos: ['1621905251189-08b45d6a269e'],
      ),
      _make(
        'request-7',
        mockOffers[2],
        ServiceRequestStatus.pending,
        'Quiero pintar la sala y el comedor (unos 35 m²) de blanco hueso. '
            'Las paredes tienen algunas grietas pequeñas.',
        today.add(const Duration(days: 6)),
        client: mockClients[3],
        category: ServiceCategories.painting,
        title: 'Pintura de sala y comedor',
        neighborhood: 'Usaquén',
        photos: ['1595814433015-e6f5ce69614e'],
      ),
      _make(
        'request-8',
        mockOffers[0],
        ServiceRequestStatus.pending,
        'Necesito cortar el pasto y podar los arbustos del antejardín. Hace '
            'meses nadie le hace mantenimiento.',
        today.add(const Duration(days: 4)),
        client: mockClients[4],
        category: ServiceCategories.gardening,
        title: 'Mantenimiento de antejardín',
        neighborhood: 'Envigado',
        photos: ['1558904541-efa843a96f01', '1416879595882-3373a0480b5b'],
      ),
      _make(
        'request-3',
        mockOffers[1],
        ServiceRequestStatus.accepted,
        'Revisión del calentador: no calienta y hace un ruido raro.',
        today.add(const Duration(days: 5)),
        category: ServiceCategories.plumbing,
        title: 'Revisión del calentador',
        neighborhood: 'Chapinero',
        photos: ['1584622650111-993a426fbf0a'],
      ),
      _make(
        'request-4',
        mockOffers[0],
        ServiceRequestStatus.rejected,
        'Limpieza de alfombras de la sala y dos habitaciones.',
        today.subtract(const Duration(days: 2)),
        category: ServiceCategories.cleaning,
        title: 'Lavado de alfombras',
        neighborhood: 'Chapinero',
        rejectionReason: 'No tengo disponibilidad esa semana.',
      ),
      _make(
        'request-5',
        mockOffers[0],
        ServiceRequestStatus.cancelled,
        'Limpieza después de mudanza.',
        today.subtract(const Duration(days: 6)),
        category: ServiceCategories.cleaning,
        title: 'Limpieza después de mudanza',
        neighborhood: 'Chapinero',
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
    Party client = mockClient,
    String? title,
    String category = '',
    String neighborhood = '',
    List<String> photos = const [],
    String? rejectionReason,
  }) => ServiceRequest(
    id: id,
    offer: offer,
    serviceTitle: title ?? mockTitleFor(offer),
    client: client,
    category: category,
    neighborhood: neighborhood,
    photoUrls: [for (final p in photos) mockPhoto(p)],
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
