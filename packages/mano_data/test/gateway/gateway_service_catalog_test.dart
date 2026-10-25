import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

const _config = ManoConfig(
  gatewayGraphQlUrl: 'http://gw/graphql',
  appRole: ManoRole.requester,
);

const _serviceJson = {
  'id': 's1',
  'category': 'cleaning',
  'title': 'Limpieza profunda',
  'description': 'Cocina y baños',
};

GatewayServiceCatalog _catalog(MockClientHandler handler) =>
    GatewayServiceCatalog(
      GatewayTransport(_config, httpClient: MockClient(handler)),
    );

Map<String, dynamic> _body(http.Request r) =>
    jsonDecode(r.body) as Map<String, dynamic>;

http.Response _data(Object data) =>
    http.Response(jsonEncode({'data': data}), 200);

void main() {
  test('search passes category and text and maps services', () async {
    final catalog = _catalog((r) async {
      expect(_body(r)['variables'], {'category': 'cleaning', 'text': 'cocina'});
      return _data({
        'jobServices': {
          'items': [_serviceJson],
        },
      });
    });

    final services = await catalog.search(category: 'cleaning', text: 'cocina');

    expect(services, const [
      JobService(
        id: 's1',
        category: 'cleaning',
        title: 'Limpieza profunda',
        description: 'Cocina y baños',
      ),
    ]);
  });

  test('blank search filters are sent as null', () async {
    final catalog = _catalog((r) async {
      expect(_body(r)['variables'], {'category': null, 'text': null});
      return _data({
        'jobServices': {'items': []},
      });
    });

    expect(await catalog.search(text: '  '), isEmpty);
  });

  test('service maps one service', () async {
    final catalog = _catalog((_) async => _data({'jobService': _serviceJson}));
    expect((await catalog.service('s1'))?.title, 'Limpieza profunda');
  });

  test("backend spellings of a category map to the app's id", () async {
    final catalog = _catalog(
      (_) async => _data({
        'jobService': {..._serviceJson, 'category': 'Plomería'},
      }),
    );
    expect((await catalog.service('s1'))?.category, 'plumbing');
  });

  test('a rejected service lookup is null', () async {
    final catalog = _catalog(
      (_) async => http.Response(
        jsonEncode({
          'errors': [
            {'message': 'job service not found'},
          ],
        }),
        200,
      ),
    );
    expect(await catalog.service('nope'), isNull);
  });

  test('offersFor maps rate type, status and decimal amounts', () async {
    final catalog = _catalog((r) async {
      expect(_body(r)['variables'], {'id': 's1'});
      return _data({
        'offersByJobService': {
          'items': [
            {
              'id': 'o1',
              'jobServiceId': 's1',
              'offerantId': 'p1',
              'rateType': 'HOURLY',
              'amount': 45000.0,
              'zone': 'Chapinero',
              'status': 'ACTIVE',
            },
            {
              'id': 'o2',
              'jobServiceId': 's1',
              'offerantId': 'p2',
              'rateType': 'FIXED',
              'amount': 120000,
              'zone': '',
              'status': 'PAUSED',
            },
          ],
        },
      });
    });

    final offers = await catalog.offersFor('s1');

    expect(offers, const [
      ServiceOffer(
        id: 'o1',
        jobServiceId: 's1',
        offerantId: 'p1',
        rateType: RateType.hourly,
        amountCop: 45000,
        zone: 'Chapinero',
        status: OfferStatus.active,
      ),
      ServiceOffer(
        id: 'o2',
        jobServiceId: 's1',
        offerantId: 'p2',
        rateType: RateType.fixed,
        amountCop: 120000,
        zone: '',
        status: OfferStatus.paused,
      ),
    ]);
  });

  test('offer maps one offer and a rejected lookup is null', () async {
    final found = _catalog(
      (_) async => _data({
        'jobServiceOffer': {
          'id': 'o1',
          'jobServiceId': 's1',
          'offerantId': 'p1',
          'rateType': 'FIXED',
          'amount': 80000,
          'zone': '',
          'status': 'ACTIVE',
        },
      }),
    );
    expect((await found.offer('o1'))?.offerantId, 'p1');

    final missing = _catalog(
      (_) async => http.Response(
        jsonEncode({
          'errors': [
            {'message': 'not found'},
          ],
        }),
        200,
      ),
    );
    expect(await missing.offer('nope'), isNull);
  });
}
