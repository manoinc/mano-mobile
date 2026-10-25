import 'package:mano_domain/mano_domain.dart';

import 'gateway_transport.dart';

/// Runs a gateway call and reports a refusal or an outage as a [DataFailure].
///
/// [GatewayUnauthorized] is rethrown: an expired session is the session's
/// business, not the screen's.
Future<Result<T, DataFailure>> guardGateway<T>(
  Future<T> Function() call,
) async {
  try {
    return Ok(await call());
  } on GatewayRejected catch (e) {
    return Err(_fromRejection(e.message));
  } on GatewayUnavailable catch (e) {
    return Err(DataUnavailable(detail: e.detail));
  }
}

// Downstream services answer "<TonicCode>: message"; the code picks the failure.
DataFailure _fromRejection(String message) =>
    switch (message.split(':').first.trim()) {
      'NotFound' => const DataNotFound(),
      'Unavailable' => DataUnavailable(detail: message),
      _ => DataRejected(reason: message),
    };
