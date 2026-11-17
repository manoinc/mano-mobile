import 'package:mano_domain/mano_domain.dart';

import '../gateway/gateway_failure.dart';
import '../gateway/gateway_transport.dart';
import 'didit_launcher.dart';
import 'worker_verification_json.dart';

/// [IdentityVerificationPort] over D10: the gateway opens a Didit session, Didit's SDK runs it.
final class GatewayIdentityVerification implements IdentityVerificationPort {
  GatewayIdentityVerification(this._transport, {required this.launcher});

  final GatewayTransport _transport;
  final DiditLauncher launcher;

  static const _mine =
      'query MyVerification { myVerification { $workerVerificationFields } }';

  static const _start =
      'mutation StartIdentityVerification { '
      'startIdentityVerification { status sessionToken } }';

  // Refusals that only mean the check is settled; the status says how.
  static const _settled = {
    'FailedPrecondition',
    'PermissionDenied',
    'ResourceExhausted',
  };

  @override
  Future<Result<IdentityCheckStatus, DataFailure>> status() =>
      guardGateway(() async {
        final data = await _transport.run(_mine);
        return identityStatusFromJson(
          data['myVerification'] as Map<String, dynamic>,
        );
      });

  @override
  Future<Result<IdentityCheckStatus, DataFailure>> verify() async {
    final String? token;
    switch (await guardGateway(() => _transport.run(_start))) {
      case Err(failure: DataRejected(:final reason?))
          when _settled.contains(reason.split(':').first.trim()):
        return status();
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        final attempt = value['startIdentityVerification'] as Map;
        token = attempt['sessionToken'] as String?;
    }

    // No token: the live attempt is already past Didit (in review).
    if (token == null) return _known(await status());

    final outcome = await launcher.start(token);
    if (outcome == DiditOutcome.failed) {
      return const Err(DataUnavailable(detail: 'Didit failed'));
    }
    final after = await status();
    // Didit has the photos; its webhook may simply not have landed yet.
    if (outcome == DiditOutcome.finished &&
        after.valueOrNull is IdentityCheckNotStarted) {
      return const Ok(IdentityCheckPending());
    }
    return after;
  }

  // A started attempt the SDK cannot open is the gateway's fault, not the person's.
  Result<IdentityCheckStatus, DataFailure> _known(
    Result<IdentityCheckStatus, DataFailure> result,
  ) => result.valueOrNull is IdentityCheckNotStarted
      ? const Err(DataUnavailable(detail: 'no session token'))
      : result;
}
