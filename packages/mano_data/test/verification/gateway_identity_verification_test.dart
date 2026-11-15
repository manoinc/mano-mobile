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

final class _FakeLauncher implements DiditLauncher {
  _FakeLauncher(this.outcome);

  final DiditOutcome outcome;
  final tokens = <String>[];

  @override
  Future<DiditOutcome> start(String sessionToken) async {
    tokens.add(sessionToken);
    return outcome;
  }
}

Map<String, Object?> _worker(
  String status, {
  String? attempt,
  int attemptsRemaining = 4,
  List<String> declineReasons = const [],
  String? decisionReason,
}) => {
  'status': status,
  'attemptsRemaining': attemptsRemaining,
  'latestAttempt': attempt == null
      ? null
      : {
          'status': attempt,
          'declineReasons': declineReasons,
          'decisionReason': decisionReason,
        },
};

http.Response _json(Object body) => http.Response(jsonEncode(body), 200);

http.Response _mine(Map<String, Object?> worker) => _json({
  'data': {'myVerification': worker},
});

http.Response _started() => _json({
  'data': {
    'startIdentityVerification': {'status': 'STARTED', 'sessionToken': 'tok-1'},
  },
});

http.Response _refused(String message) => _json({
  'errors': [
    {'message': message},
  ],
});

/// Answers the start and the read in turn, recording each document.
({GatewayIdentityVerification port, List<String> sent}) _port(
  _FakeLauncher launcher, {
  http.Response Function()? start,
  required Map<String, Object?> after,
}) {
  final sent = <String>[];
  final port = GatewayIdentityVerification(
    GatewayTransport(
      _config,
      httpClient: MockClient((r) async {
        final query = (jsonDecode(r.body) as Map)['query'] as String;
        sent.add(query);
        return query.contains('startIdentityVerification')
            ? (start ?? _started)()
            : _mine(after);
      }),
    ),
    launcher: launcher,
  );
  return (port: port, sent: sent);
}

Future<IdentityCheckStatus?> _statusOf(Map<String, Object?> worker) async =>
    (await _port(
      _FakeLauncher(DiditOutcome.finished),
      after: worker,
    ).port.status()).valueOrNull;

void main() {
  group('status', () {
    test('an unverified worker has not started', () async {
      expect(
        await _statusOf(_worker('UNVERIFIED')),
        isA<IdentityCheckNotStarted>(),
      );
    });

    test('a session left open can be resumed, so it has not started', () async {
      expect(
        await _statusOf(_worker('IN_PROGRESS', attempt: 'STARTED')),
        isA<IdentityCheckNotStarted>(),
      );
    });

    test('Didit processing or the staff reviewing is pending', () async {
      expect(
        await _statusOf(_worker('IN_PROGRESS', attempt: 'PROCESSING')),
        isA<IdentityCheckPending>(),
      );
      expect(
        await _statusOf(_worker('PENDING_REVIEW', attempt: 'PENDING_REVIEW')),
        isA<IdentityCheckPending>(),
      );
    });

    test('verified is approved', () async {
      expect(
        await _statusOf(_worker('VERIFIED', attempt: 'APPROVED')),
        isA<IdentityCheckApproved>(),
      );
    });

    test('a staff rejection is final', () async {
      final status = await _statusOf(
        _worker(
          'REJECTED',
          attempt: 'REJECTED',
          decisionReason: 'BACKGROUND_CHECK',
        ),
      );
      expect(status, isA<IdentityCheckRejected>());
      expect((status! as IdentityCheckRejected).canRetry, isFalse);
    });

    test('a Didit decline with attempts left can be retried', () async {
      final status = await _statusOf(
        _worker(
          'UNVERIFIED',
          attempt: 'DECLINED',
          declineReasons: ['DOCUMENT_UNREADABLE'],
        ),
      );
      expect(status, isA<IdentityCheckRejected>());
      final rejected = status! as IdentityCheckRejected;
      expect(rejected.canRetry, isTrue);
      expect(rejected.reason, isNotEmpty);
    });

    test('a decline with no attempts left cannot be retried yet', () async {
      final status = await _statusOf(
        _worker('UNVERIFIED', attempt: 'DECLINED', attemptsRemaining: 0),
      );
      expect((status! as IdentityCheckRejected).canRetry, isFalse);
    });

    test('a request to resubmit can be retried', () async {
      final status = await _statusOf(
        _worker(
          'UNVERIFIED',
          attempt: 'RESUBMISSION_REQUIRED',
          decisionReason: 'DOCUMENT_UNCLEAR',
        ),
      );
      expect((status! as IdentityCheckRejected).canRetry, isTrue);
    });

    test('an outage is a failure', () async {
      final port = GatewayIdentityVerification(
        GatewayTransport(
          _config,
          httpClient: MockClient((_) async => http.Response('', 503)),
        ),
        launcher: _FakeLauncher(DiditOutcome.finished),
      );
      expect((await port.status()).failureOrNull, isA<DataUnavailable>());
    });
  });

  group('verify', () {
    test('hands the session token to Didit, then reads the result', () async {
      final launcher = _FakeLauncher(DiditOutcome.finished);
      final (:port, :sent) = _port(
        launcher,
        after: _worker('PENDING_REVIEW', attempt: 'PENDING_REVIEW'),
      );

      final status = (await port.verify()).valueOrNull;

      expect(launcher.tokens, ['tok-1']);
      expect(sent.first, contains('startIdentityVerification'));
      expect(sent.first, contains('sessionToken'));
      expect(sent.last, contains('myVerification'));
      expect(status, isA<IdentityCheckPending>());
    });

    test('finished before Didit\'s webhook arrives is still pending', () async {
      final (:port, sent: _) = _port(
        _FakeLauncher(DiditOutcome.finished),
        after: _worker('IN_PROGRESS', attempt: 'STARTED'),
      );

      expect((await port.verify()).valueOrNull, isA<IdentityCheckPending>());
    });

    test('closing Didit leaves the check not started', () async {
      final (:port, sent: _) = _port(
        _FakeLauncher(DiditOutcome.cancelled),
        after: _worker('IN_PROGRESS', attempt: 'STARTED'),
      );

      expect((await port.verify()).valueOrNull, isA<IdentityCheckNotStarted>());
    });

    test('Didit failing is an outage', () async {
      final (:port, sent: _) = _port(
        _FakeLauncher(DiditOutcome.failed),
        after: _worker('IN_PROGRESS', attempt: 'STARTED'),
      );

      expect((await port.verify()).failureOrNull, isA<DataUnavailable>());
    });

    test('a settled refusal to start reports the status instead', () async {
      final cases = {
        'FailedPrecondition: already verified': _worker(
          'VERIFIED',
          attempt: 'APPROVED',
        ),
        'PermissionDenied: the worker was rejected': _worker(
          'REJECTED',
          attempt: 'REJECTED',
        ),
        'ResourceExhausted: no attempts left': _worker(
          'UNVERIFIED',
          attempt: 'DECLINED',
          attemptsRemaining: 0,
        ),
      };
      for (final MapEntry(key: message, value: worker) in cases.entries) {
        final launcher = _FakeLauncher(DiditOutcome.finished);
        final (:port, sent: _) = _port(
          launcher,
          start: () => _refused(message),
          after: worker,
        );

        final status = (await port.verify()).valueOrNull;

        expect(status, isNotNull, reason: message);
        expect(status, isNot(isA<IdentityCheckPending>()), reason: message);
        expect(launcher.tokens, isEmpty, reason: message);
      }
    });

    test('any other refusal to start is a failure', () async {
      final (:port, sent: _) = _port(
        _FakeLauncher(DiditOutcome.finished),
        start: () => _refused('Unavailable: provider down'),
        after: _worker('UNVERIFIED'),
      );

      expect((await port.verify()).failureOrNull, isA<DataUnavailable>());
    });

    test('a started attempt without a token is an outage', () async {
      final launcher = _FakeLauncher(DiditOutcome.finished);
      final (:port, sent: _) = _port(
        launcher,
        start: () => _json({
          'data': {
            'startIdentityVerification': {
              'status': 'STARTED',
              'sessionToken': null,
            },
          },
        }),
        after: _worker('IN_PROGRESS', attempt: 'STARTED'),
      );

      expect((await port.verify()).failureOrNull, isA<DataUnavailable>());
      expect(launcher.tokens, isEmpty);
    });
  });
}
