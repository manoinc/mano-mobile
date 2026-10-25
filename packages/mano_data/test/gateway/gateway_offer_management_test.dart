import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

const _config = ManoConfig(
  gatewayGraphQlUrl: 'http://gw/graphql',
  appRole: ManoRole.provider,
);

Map<String, dynamic> _offerJson({String id = 'o1', String status = 'ACTIVE'}) =>
    {
      'id': id,
      'jobServiceId': 's1',
      'offerantId': 'p1',
      'rateType': 'HOURLY',
      'amount': 45000.0,
      'zone': 'Chapinero',
      'status': status,
    };

const _offer = ServiceOffer(
  id: 'o1',
  jobServiceId: 's1',
  offerantId: 'p1',
  rateType: RateType.hourly,
  amountCop: 45000,
  zone: 'Chapinero',
  status: OfferStatus.active,
);

GatewayOfferManagement _offers(MockClientHandler handler) =>
    GatewayOfferManagement(
      GatewayTransport(_config, httpClient: MockClient(handler)),
    );

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

void main() {
  test('myOffers asks without deleted ones and maps them', () async {
    final offers = _offers((r) async {
      expect(_body(r)['query'], contains('myJobServiceOffers'));
      expect(_body(r)['variables'], {'includeDeleted': false});
      return _data({
        'myJobServiceOffers': [
          _offerJson(),
          _offerJson(id: 'o2', status: 'DELETED'),
        ],
      });
    });

    expect(await offers.myOffers(), [_offer]);
  });

  test('create sends the input with amount as a number', () async {
    final offers = _offers((r) async {
      expect(_body(r)['query'], contains('createJobServiceOffer'));
      expect(_body(r)['variables'], {
        'input': {
          'jobServiceId': 's1',
          'rateType': 'HOURLY',
          'amount': 45000,
          'zone': 'Chapinero',
        },
      });
      return _data({'createJobServiceOffer': _offerJson()});
    });

    final result = await offers.create(
      jobServiceId: 's1',
      rateType: RateType.hourly,
      amountCop: 45000,
      zone: 'Chapinero',
    );

    expect(result.valueOrNull, _offer);
  });

  test('update sends only the fields given', () async {
    final offers = _offers((r) async {
      expect(_body(r)['query'], contains('updateJobServiceOffer'));
      expect(_body(r)['variables'], {
        'id': 'o1',
        'input': {'amount': 50000},
      });
      return _data({'updateJobServiceOffer': _offerJson()});
    });

    expect((await offers.update('o1', amountCop: 50000)).isOk, isTrue);
  });

  test('update maps every field when all are given', () async {
    final offers = _offers((r) async {
      expect(_body(r)['variables'], {
        'id': 'o1',
        'input': {'rateType': 'FIXED', 'amount': 1, 'zone': ''},
      });
      return _data({'updateJobServiceOffer': _offerJson()});
    });

    await offers.update('o1', rateType: RateType.fixed, amountCop: 1, zone: '');
  });

  final transitions =
      <
        (
          String,
          String,
          Future<Result<ServiceOffer, DataFailure>> Function(
            GatewayOfferManagement,
          ),
          OfferStatus,
        )
      >[
        (
          'pause',
          'pauseJobServiceOffer',
          (o) => o.pause('o1'),
          OfferStatus.paused,
        ),
        (
          'resume',
          'resumeJobServiceOffer',
          (o) => o.resume('o1'),
          OfferStatus.active,
        ),
        (
          'delete',
          'deleteJobServiceOffer',
          (o) => o.delete('o1'),
          OfferStatus.deleted,
        ),
      ];
  for (final (name, field, call, status) in transitions) {
    test('$name calls $field with the id', () async {
      final wire = switch (status) {
        OfferStatus.active => 'ACTIVE',
        OfferStatus.paused => 'PAUSED',
        OfferStatus.deleted => 'DELETED',
      };
      final offers = _offers((r) async {
        expect(_body(r)['query'], contains(field));
        expect(_body(r)['variables'], {'id': 'o1'});
        return _data({field: _offerJson(status: wire)});
      });

      expect((await call(offers)).valueOrNull?.status, status);
    });
  }

  test('a rejected mutation is a failure, not an exception', () async {
    final offers = _offers((_) async => _error('NotFound: no offer o9'));
    expect((await offers.pause('o9')).failureOrNull, const DataNotFound());
  });

  test('an outage is DataUnavailable', () async {
    final offers = _offers((_) async => http.Response('', 503));
    expect((await offers.delete('o1')).failureOrNull, isA<DataUnavailable>());
  });
}
