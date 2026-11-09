import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

import 'counting_catalog.dart';

const _config = ManoConfig(
  gatewayGraphQlUrl: 'http://gw/graphql',
  appRole: ManoRole.provider,
);

const _offerJson = {
  'id': 'o1',
  'jobServiceId': 's1',
  'offerantId': 'p1',
  'rateType': 'FIXED',
  'amount': 120000,
  'zone': '',
  'status': 'ACTIVE',
};

const _appointment = {
  'start': '2030-01-07T14:00:00Z',
  'end': '2030-01-07T16:00:00Z',
};

Map<String, dynamic> _jobJson({
  String id = 'j1',
  String status = 'SCHEDULED',
  Object? appointment = _appointment,
  Map<String, dynamic> offer = _offerJson,
}) => {
  'id': id,
  'client': {'id': 'c1'},
  'worker': {'id': 'w1'},
  'offer': offer,
  'appointment': appointment,
  'status': status,
  'pricing': {'rateType': 'HOURLY', 'amount': 45000.0},
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

({GatewayJobRepository repo, CountingCatalog catalog}) _repo(
  MockClientHandler handler,
) {
  final catalog = CountingCatalog();
  return (
    repo: GatewayJobRepository(
      GatewayTransport(_config, httpClient: MockClient(handler)),
      catalog,
    ),
    catalog: catalog,
  );
}

void main() {
  test('mine lists jobs, enriched once per service', () async {
    final (:repo, :catalog) = _repo((r) async {
      expect(_body(r)['query'], contains('myJobs'));
      expect(_body(r)['variables'], {'status': null});
      return _data({
        'myJobs': {
          'items': [_jobJson(), _jobJson(id: 'j2', status: 'IN_PROGRESS')],
        },
      });
    });

    final jobs = await repo.mine();

    final job = jobs.first;
    expect(job.id, 'j1');
    expect(job.offerId, 'o1');
    expect(job.serviceTitle, 'Reparación de fugas');
    expect(job.client, const Party(id: 'c1', displayName: '', photoUrl: ''));
    expect(job.provider, const Party(id: 'w1', displayName: '', photoUrl: ''));
    expect(job.rateType, RateType.hourly);
    expect(job.amountCop, 45000);
    expect(job.start, DateTime.utc(2030, 1, 7, 14).toLocal());
    expect(job.start.isUtc, isFalse);
    expect(job.end, DateTime.utc(2030, 1, 7, 16).toLocal());
    expect(job.status, JobStatus.scheduled);
    expect(job.actualHours, isNull);
    expect(jobs.last.status, JobStatus.inProgress);
    expect(catalog.lookups, ['s1']);
  });

  test('mine filters by status in the gateway spelling', () async {
    final (:repo, catalog: _) = _repo((r) async {
      expect(_body(r)['variables'], {'status': 'IN_PROGRESS'});
      return _data({
        'myJobs': {'items': []},
      });
    });
    expect(await repo.mine(status: JobStatus.inProgress), isEmpty);
  });

  test(
    'without an appointment a job starts at its creation, with no end',
    () async {
      final (:repo, catalog: _) = _repo(
        (_) async => _data({
          'myJobs': {
            'items': [
              _jobJson(
                appointment: null,
                offer: {..._offerJson, 'jobServiceId': 'gone'},
              ),
            ],
          },
        }),
      );

      final job = (await repo.mine()).single;
      expect(job.start, DateTime.utc(2030, 1, 1, 12).toLocal());
      expect(job.end, isNull);
      expect(job.serviceTitle, '');
    },
  );

  test('job reads one job, and a missing one is null', () async {
    final (:repo, catalog: _) = _repo((r) async {
      final id = (_body(r)['variables'] as Map)['id'];
      return id == 'j1'
          ? _data({'job': _jobJson(status: 'FINISHED')})
          : _error('NotFound: no such job');
    });

    expect((await repo.job('j1'))?.status, JobStatus.finished);
    expect(await repo.job('nope'), isNull);
  });

  test('a finished job carries its final amount', () async {
    final (:repo, catalog: _) = _repo((r) async {
      expect(_body(r)['query'], contains('finalAmount { amount }'));
      return _data({
        'job': {
          ..._jobJson(status: 'FINISHED'),
          'finalAmount': {'amount': 62500.0, 'currency': 'COP'},
        },
      });
    });

    final job = await repo.job('j1');
    expect(job?.finalAmountCop, 62500);
    expect(job?.payableCop, 62500);
  });

  test('bookSlot sends the offer and an RFC 3339 start', () async {
    final (:repo, catalog: _) = _repo((r) async {
      expect(_body(r)['query'], contains('bookSlot'));
      expect(_body(r)['variables'], {
        'offerId': 'o1',
        'slotStart': '2030-01-07T14:00:00.000Z',
      });
      return _data({'bookSlot': _jobJson()});
    });

    final result = await repo.bookSlot('o1', DateTime.utc(2030, 1, 7, 14));
    expect(result.valueOrNull?.id, 'j1');
  });

  test('start, finish and cancel send their arguments', () async {
    final sent = <String, Object?>{};
    final (:repo, catalog: _) = _repo((r) async {
      final body = _body(r);
      final field = [
        'startJob',
        'finishJob',
        'cancelJob',
      ].firstWhere((body['query'] as String).contains);
      sent[field] = body['variables'];
      return _data({field: _jobJson(status: 'CANCELLED')});
    });

    expect((await repo.start('j1')).isOk, isTrue);
    expect((await repo.finish('j1', actualHours: 2.5)).isOk, isTrue);
    final cancelled = await repo.cancel('j1', reason: 'Viaje');

    expect(cancelled.valueOrNull?.status, JobStatus.cancelled);
    expect(sent, {
      'startJob': {'id': 'j1'},
      'finishJob': {'id': 'j1', 'actualHours': 2.5},
      'cancelJob': {'id': 'j1', 'reason': 'Viaje'},
    });
  });

  test('rebook files a new request for the same offer', () async {
    final (:repo, catalog: _) = _repo((r) async {
      expect(_body(r)['query'], contains('rebook'));
      expect(_body(r)['variables'], {'jobId': 'j1'});
      return _data({
        'rebook': {
          'id': 'r9',
          'client': {'id': 'c1'},
          'offer': _offerJson,
          'message': null,
          'proposedStart': null,
          'status': 'PENDING',
          'rejectionReason': null,
          'createdAt': '2030-01-02T12:00:00Z',
        },
      });
    });

    final request = (await repo.rebook('j1')).valueOrNull!;
    expect(request.id, 'r9');
    expect(request.serviceTitle, 'Reparación de fugas');
    expect(request.provider.id, 'p1');
  });

  test('a refused mutation is a failure, not a throw', () async {
    final (:repo, catalog: _) = _repo(
      (_) async => _error('InvalidArgument: slot is not published'),
    );
    final result = await repo.bookSlot('o1', DateTime.utc(2030, 1, 7, 14));
    expect(result.failureOrNull, isA<DataRejected>());
  });
}
