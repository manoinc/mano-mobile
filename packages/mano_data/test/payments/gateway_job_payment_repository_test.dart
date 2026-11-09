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

Map<String, dynamic> _body(http.Request r) =>
    jsonDecode(r.body) as Map<String, dynamic>;

GatewayJobPaymentRepository _repo(MockClientHandler handler) =>
    GatewayJobPaymentRepository(
      GatewayTransport(_config, httpClient: MockClient(handler)),
    );

const _nequi = JobPaymentDraft(
  jobId: 'job-1',
  method: JobPaymentMethod.nequi,
  phone: '300 123 4567',
  payerEmail: ' ana@mano.test ',
  termsAccepted: true,
);

Map<String, Object?> _result({
  String status = 'PENDING',
  String next = 'AWAIT_APPROVAL',
  String? url,
  String? reason,
}) => {
  'payment': {
    'id': 'pay-1',
    'purpose': 'JOB',
    'jobId': 'job-1',
    'amount': {'amount': 120000.0, 'currency': 'COP'},
    'feeAmount': {'amount': 6000.0, 'currency': 'COP'},
    'netToWorker': {'amount': 114000.0, 'currency': 'COP'},
    'method': 'WALLET',
    'status': status,
    'failureReason': reason,
  },
  'nextAction': {'type': next, 'redirectUrl': url},
};

void main() {
  test('a Nequi payment sends the wallet method and awaits approval', () async {
    final repo = _repo((r) async {
      expect(_body(r)['query'], contains('payJob('));
      expect(_body(r)['variables'], {
        'jobId': 'job-1',
        'method': {
          'wallet': {'phone': '3001234567'},
        },
        'payerEmail': 'ana@mano.test',
        'termsAccepted': true,
      });
      return _data({'payJob': _result()});
    });

    final payment = (await repo.pay(_nequi)).valueOrNull!;

    expect(payment.status, JobPaymentStatus.awaitingApproval);
    expect(payment.paymentId, 'pay-1');
    expect(payment.jobId, 'job-1');
    expect(payment.amount, 120000);
    expect(payment.feeAmount, 6000);
  });

  test('a PSE payment sends the bank and payer, and redirects', () async {
    final repo = _repo((r) async {
      expect(_body(r)['variables']['method'], {
        'pse': {
          'institutionCode': '1022',
          'personType': 'NATURAL',
          'legalIdType': 'CC',
          'legalId': '1020304050',
        },
      });
      return _data({
        'payJob': _result(next: 'REDIRECT', url: 'https://bank.test/pay'),
      });
    });

    final payment = (await repo.pay(
      _nequi.copyWith(
        method: JobPaymentMethod.pse,
        bankCode: '1022',
        legalId: '1.020.304.050',
      ),
    )).valueOrNull!;

    expect(payment.status, JobPaymentStatus.redirect);
    expect(payment.redirectUrl, 'https://bank.test/pay');
  });

  test('PENDING, a redirect with no URL yet, or NONE is pending', () async {
    for (final reply in [
      _result(next: 'PENDING'),
      _result(next: 'REDIRECT'),
      _result(next: 'NONE'),
    ]) {
      final repo = _repo((r) async => _data({'payJob': reply}));
      expect(
        (await repo.pay(_nequi)).valueOrNull!.status,
        JobPaymentStatus.pending,
      );
    }
  });

  test('a completed payment is settled', () async {
    final repo = _repo(
      (r) async =>
          _data({'payJob': _result(status: 'COMPLETED', next: 'NONE')}),
    );
    expect((await repo.pay(_nequi)).valueOrNull!.isSettled, isTrue);
  });

  test('a failed payment carries its reason', () async {
    final repo = _repo(
      (r) async => _data({
        'payJob': _result(status: 'FAILED', next: 'NONE', reason: 'declined'),
      }),
    );
    final payment = (await repo.pay(_nequi)).valueOrNull!;
    expect(payment.status, JobPaymentStatus.failed);
    expect(payment.failureReason, 'declined');
  });

  test('an invalid draft never reaches the gateway', () async {
    final repo = _repo((r) async => fail('must not be sent'));
    expect(
      (await repo.pay(_nequi.copyWith(termsAccepted: false))).failureOrNull,
      isA<DataRejected>(),
    );
  });

  test('a billing refusal arrives as a rejection', () async {
    final repo = _repo(
      (r) async => _error('FailedPrecondition: the job is not payable'),
    );
    expect((await repo.pay(_nequi)).failureOrNull, isA<DataRejected>());
  });

  test('jobPayment reads the live payment by job', () async {
    final repo = _repo((r) async {
      expect(_body(r)['query'], contains('jobPayment('));
      expect(_body(r)['variables'], {'jobId': 'job-1'});
      return _data({'jobPayment': _result(status: 'COMPLETED', next: 'NONE')});
    });
    expect((await repo.payment('job-1')).valueOrNull!.isSettled, isTrue);
  });

  test('an unpaid job has no payment', () async {
    final repo = _repo((r) async => _data({'jobPayment': null}));
    final result = await repo.payment('job-1');
    expect(result.failureOrNull, isNull);
    expect(result.valueOrNull, isNull);
  });

  test('checkout terms and PSE banks', () async {
    final repo = _repo((r) async {
      final query = _body(r)['query'] as String;
      if (query.contains('checkoutTerms')) {
        return _data({
          'checkoutTerms': [
            {'label': 'Términos', 'url': 'https://terms.test'},
          ],
        });
      }
      return _data({
        'pseBanks': [
          {'code': '1022', 'name': 'Banco Union'},
        ],
      });
    });
    expect((await repo.checkoutTerms()).valueOrNull, const [
      CheckoutTerm(label: 'Términos', url: 'https://terms.test'),
    ]);
    expect((await repo.pseBanks()).valueOrNull, const [
      Bank(code: '1022', name: 'Banco Union'),
    ]);
  });

  test('billing being down is unavailable', () async {
    final repo = _repo((r) async => _error('Unavailable: billing is down'));
    expect((await repo.payment('job-1')).failureOrNull, isA<DataUnavailable>());
  });
}
