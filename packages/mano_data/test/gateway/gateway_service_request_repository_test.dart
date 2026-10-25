import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

import 'counting_catalog.dart';

const _config = ManoConfig(
  gatewayGraphQlUrl: 'http://gw/graphql',
  appRole: ManoRole.requester,
);

const _offerJson = {
  'id': 'o1',
  'jobServiceId': 's1',
  'offerantId': 'p1',
  'rateType': 'HOURLY',
  'amount': 45000.0,
  'zone': 'Chapinero',
  'status': 'ACTIVE',
};

Map<String, dynamic> _requestJson({
  String id = 'r1',
  String status = 'PENDING',
  Object? message = 'Gotea el lavaplatos',
  Object? proposedStart = '2030-01-07T14:00:00Z',
  Map<String, dynamic> offer = _offerJson,
}) => {
  'id': id,
  'client': {'id': 'c1'},
  'offer': offer,
  'message': message,
  'proposedStart': proposedStart,
  'status': status,
  'rejectionReason': null,
  'createdAt': '2030-01-01T12:00:00Z',
};

Map<String, dynamic> _body(http.Request r) =>
    jsonDecode(r.body) as Map<String, dynamic>;

http.Response _data(Object data) =>
    http.Response(jsonEncode({'data': data}), 200);

http.Response _error(String message) => http.Response(
  jsonEncode({
    'errors': [
      {'message': message},
    ],
  }),
  200,
);

({GatewayServiceRequestRepository repo, CountingCatalog catalog}) _repo(
  MockClientHandler handler,
) {
  final catalog = CountingCatalog();
  return (
    repo: GatewayServiceRequestRepository(
      GatewayTransport(_config, httpClient: MockClient(handler)),
      catalog,
    ),
    catalog: catalog,
  );
}

void main() {
  test('mine lists every request, enriched from the catalog', () async {
    final (:repo, :catalog) = _repo((r) async {
      expect(_body(r)['query'], contains('myServiceRequests'));
      expect(_body(r)['variables'], {'status': null});
      return _data({
        'myServiceRequests': {
          'items': [_requestJson(), _requestJson(id: 'r2')],
        },
      });
    });

    final requests = await repo.mine();

    expect(requests, hasLength(2));
    final first = requests.first;
    expect(first.id, 'r1');
    expect(first.serviceTitle, 'Reparación de fugas');
    expect(first.category, 'plumbing');
    expect(first.client, const Party(id: 'c1', displayName: '', photoUrl: ''));
    expect(
      first.provider,
      const Party(id: 'p1', displayName: '', photoUrl: ''),
    );
    expect(first.offer.rateType, RateType.hourly);
    expect(first.offer.amountCop, 45000);
    expect(first.message, 'Gotea el lavaplatos');
    expect(first.proposedStart, DateTime.utc(2030, 1, 7, 14).toLocal());
    expect(first.proposedStart!.isUtc, isFalse);
    expect(first.createdAt, DateTime.utc(2030, 1, 1, 12).toLocal());
    expect(first.status, ServiceRequestStatus.pending);
    expect(first.neighborhood, '');
    expect(first.photoUrls, isEmpty);
    expect(catalog.lookups, ['s1']);
  });

  test('mine filters by status in the gateway spelling', () async {
    final (:repo, catalog: _) = _repo((r) async {
      expect(_body(r)['variables'], {'status': 'ACCEPTED'});
      return _data({
        'myServiceRequests': {'items': []},
      });
    });

    expect(await repo.mine(status: ServiceRequestStatus.accepted), isEmpty);
  });

  test('an unknown service leaves title and category empty', () async {
    final (:repo, catalog: _) = _repo(
      (_) async => _data({
        'myServiceRequests': {
          'items': [
            _requestJson(
              offer: {..._offerJson, 'jobServiceId': 'gone'},
              message: null,
              proposedStart: null,
            ),
          ],
        },
      }),
    );

    final request = (await repo.mine()).single;
    expect(request.serviceTitle, '');
    expect(request.category, '');
    expect(request.message, '');
    expect(request.proposedStart, isNull);
  });

  test('request sends the offer, message and RFC 3339 start', () async {
    final (:repo, catalog: _) = _repo((r) async {
      expect(_body(r)['query'], contains('requestService'));
      expect(_body(r)['variables'], {
        'offerId': 'o1',
        'input': {
          'message': 'Hola',
          'proposedStart': '2030-01-07T14:00:00.000Z',
        },
      });
      return _data({'requestService': _requestJson()});
    });

    final result = await repo.request(
      'o1',
      message: 'Hola',
      proposedStart: DateTime.utc(2030, 1, 7, 14),
    );
    expect(result.valueOrNull?.id, 'r1');
  });

  test('accept, reject and cancel send the id and map the answer', () async {
    final sent = <String, Object?>{};
    final (:repo, catalog: _) = _repo((r) async {
      final body = _body(r);
      final query = body['query'] as String;
      final field = [
        'acceptServiceRequest',
        'rejectServiceRequest',
        'cancelServiceRequest',
      ].firstWhere(query.contains);
      sent[field] = body['variables'];
      return _data({field: _requestJson(status: 'CANCELLED')});
    });

    expect((await repo.accept('r1')).isOk, isTrue);
    expect((await repo.reject('r1', reason: 'Sin cupo')).isOk, isTrue);
    final cancelled = await repo.cancel('r1');

    expect(cancelled.valueOrNull?.status, ServiceRequestStatus.cancelled);
    expect(sent, {
      'acceptServiceRequest': {'id': 'r1'},
      'rejectServiceRequest': {'id': 'r1', 'reason': 'Sin cupo'},
      'cancelServiceRequest': {'id': 'r1'},
    });
  });

  test('a refused mutation is a failure, not a throw', () async {
    final (:repo, catalog: _) = _repo(
      (_) async => _error('FailedPrecondition: request is not pending'),
    );

    final result = await repo.accept('r1');
    expect(result.failureOrNull, isA<DataRejected>());
  });

  test('a missing request is DataNotFound', () async {
    final (:repo, catalog: _) = _repo(
      (_) async => _error('NotFound: no such request'),
    );
    expect((await repo.cancel('nope')).failureOrNull, isA<DataNotFound>());
  });
}
