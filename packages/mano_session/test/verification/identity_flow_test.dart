import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_session/mano_session.dart';

/// A port told what to report, before and after the vendor's flow.
final class _Port implements IdentityVerificationPort {
  IdentityCheckStatus reported = const IdentityCheckNotStarted();
  Result<IdentityCheckStatus, DataFailure> verified = const Ok(
    IdentityCheckPending(),
  );
  Completer<void>? gate;
  var verifies = 0;

  @override
  Future<Result<IdentityCheckStatus, DataFailure>> status() async =>
      Ok(reported);

  @override
  Future<Result<IdentityCheckStatus, DataFailure>> verify() async {
    verifies++;
    await gate?.future;
    return verified;
  }
}

Future<({ProviderContainer c, IdentityFlowNotifier n})> _setUp(
  _Port port,
) async {
  final c = ProviderContainer.test(
    overrides: [identityVerificationProvider.overrideWithValue(port)],
  );
  c.listen(identityFlowProvider, (_, _) {});
  await pumpEventQueue();
  return (c: c, n: c.read(identityFlowProvider.notifier));
}

IdentityFlowState _s(ProviderContainer c) => c.read(identityFlowProvider);

void _walkToSelfie(IdentityFlowNotifier n) => n
  ..next()
  ..next()
  ..next();

void main() {
  group('opening', () {
    test('a fresh check opens on the intro', () async {
      final (:c, n: _) = await _setUp(_Port());
      expect(_s(c).step, IdentityFlowStep.intro);
    });

    test('a check already sent opens on pending', () async {
      final (:c, n: _) = await _setUp(
        _Port()..reported = const IdentityCheckPending(),
      );
      expect(_s(c).step, IdentityFlowStep.pending);
    });

    test('an approved check opens approved and counts as verified', () async {
      final (:c, n: _) = await _setUp(
        _Port()..reported = const IdentityCheckApproved(),
      );
      expect(_s(c).step, IdentityFlowStep.approved);
      expect(c.read(identityVerifiedProvider), isTrue);
    });

    test('a refused check opens on the reason', () async {
      final (:c, n: _) = await _setUp(
        _Port()
          ..reported = const IdentityCheckRejected(
            reason: 'Borrosa',
            canRetry: true,
          ),
      );
      expect(_s(c).step, IdentityFlowStep.rejected);
      expect(_s(c).rejection, 'Borrosa');
      expect(_s(c).canRetry, isTrue);
      expect(c.read(identityVerifiedProvider), isFalse);
    });
  });

  test('intro, front, back, selfie: the briefs Nu walks', () async {
    final (:c, :n) = await _setUp(_Port());
    final seen = <IdentityFlowStep>[];
    for (var i = 0; i < 4; i++) {
      n.next();
      seen.add(_s(c).step);
    }
    expect(seen, [
      IdentityFlowStep.frontBrief,
      IdentityFlowStep.backBrief,
      IdentityFlowStep.selfieBrief,
      IdentityFlowStep.selfieBrief,
    ], reason: 'the last brief starts the check instead');
  });

  test('back walks the briefs to the intro', () async {
    final (:c, :n) = await _setUp(_Port());
    _walkToSelfie(n);
    n.back();
    expect(_s(c).step, IdentityFlowStep.backBrief);
    n
      ..back()
      ..back()
      ..back();
    expect(_s(c).step, IdentityFlowStep.intro);
  });

  test('start is busy while the vendor runs, then pending', () async {
    final port = _Port()..gate = Completer<void>();
    final (:c, :n) = await _setUp(port);
    _walkToSelfie(n);

    final starting = n.start();
    expect(_s(c).busy, isTrue);
    await n.start();
    expect(port.verifies, 1, reason: 'a second tap while busy is ignored');
    port.gate!.complete();
    await starting;

    expect(_s(c).busy, isFalse);
    expect(_s(c).step, IdentityFlowStep.pending);
  });

  test('closing the vendor\'s flow stays on the selfie brief', () async {
    final port = _Port()..verified = const Ok(IdentityCheckNotStarted());
    final (:c, :n) = await _setUp(port);
    _walkToSelfie(n);

    await n.start();

    expect(_s(c).step, IdentityFlowStep.selfieBrief);
    expect(_s(c).failure, isNull);
  });

  test('a failure stays on the brief and says why', () async {
    final port = _Port()..verified = const Err(DataUnavailable());
    final (:c, :n) = await _setUp(port);
    _walkToSelfie(n);

    await n.start();

    expect(_s(c).step, IdentityFlowStep.selfieBrief);
    expect(_s(c).failure, isA<DataUnavailable>());
    n.acknowledgeFailure();
    expect(_s(c).failure, isNull);
  });

  test('start does nothing off the selfie brief', () async {
    final port = _Port();
    final (c: _, :n) = await _setUp(port);
    await n.start();
    expect(port.verifies, 0);
  });

  test('retry after a retryable refusal walks the briefs again', () async {
    final (:c, :n) = await _setUp(
      _Port()
        ..reported = const IdentityCheckRejected(
          reason: 'Borrosa',
          canRetry: true,
        ),
    );
    n.retry();
    expect(_s(c).step, IdentityFlowStep.frontBrief);
  });

  test('a final refusal cannot be retried', () async {
    final (:c, :n) = await _setUp(
      _Port()
        ..reported = const IdentityCheckRejected(reason: 'No', canRetry: false),
    );
    n.retry();
    expect(_s(c).step, IdentityFlowStep.rejected);
  });

  test('progress runs across the briefs', () async {
    final (:c, :n) = await _setUp(_Port());
    expect(_s(c).progress, closeTo(1 / 4, 1e-9));
    _walkToSelfie(n);
    expect(_s(c).progress, 1);
    await n.start();
    expect(_s(c).progress, isNull);
  });

  group('the verification gate', () {
    test('only an approved check counts, even before the flow loads', () async {
      final port = _Port()..reported = const IdentityCheckApproved();
      final c = ProviderContainer.test(
        overrides: [identityVerificationProvider.overrideWithValue(port)],
      );

      expect(await c.read(identityFlowProvider.notifier).verified(), isTrue);
    });

    test('a pending check is not verified yet', () async {
      final (c: _, :n) = await _setUp(
        _Port()..reported = const IdentityCheckPending(),
      );
      expect(await n.verified(), isFalse);
    });

    test('a debug build set to approve approves on start', () async {
      final c = ProviderContainer.test(
        overrides: [
          manoConfigProvider.overrideWithValue(
            const ManoConfig(
              gatewayGraphQlUrl: 'http://gw/graphql',
              appRole: ManoRole.provider,
              approveIdentityChecks: true,
            ),
          ),
        ],
      );
      c.listen(identityFlowProvider, (_, _) {});
      await pumpEventQueue();
      final n = c.read(identityFlowProvider.notifier);
      _walkToSelfie(n);

      await n.start();

      expect(_s(c).step, IdentityFlowStep.approved);
      expect(c.read(identityVerifiedProvider), isTrue);
    });
  });

  group('the port', () {
    ManoConfig config({String? authApiDomain}) => ManoConfig(
      gatewayGraphQlUrl: 'http://gw/graphql',
      appRole: ManoRole.provider,
      authApiDomain: authApiDomain,
    );

    test('without an auth domain the check is the mock', () {
      final c = ProviderContainer.test(
        overrides: [manoConfigProvider.overrideWithValue(config())],
      );
      expect(
        c.read(identityVerificationProvider),
        isA<MockIdentityVerification>(),
      );
    });

    test('with an auth domain it goes through the gateway and Didit', () {
      final c = ProviderContainer.test(
        overrides: [
          manoConfigProvider.overrideWithValue(
            config(authApiDomain: 'http://localhost:3001'),
          ),
          diditLauncherProvider.overrideWithValue(_NoDidit()),
        ],
      );
      expect(
        c.read(identityVerificationProvider),
        isA<GatewayIdentityVerification>(),
      );
    });
  });
}

final class _NoDidit implements DiditLauncher {
  @override
  Future<DiditOutcome> start(String sessionToken) async =>
      DiditOutcome.cancelled;
}
