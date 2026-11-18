import 'package:mano_domain/mano_domain.dart';

import '../gateway/gateway_failure.dart';
import '../gateway/gateway_transport.dart';

/// [RegistrationRepository] over D2: the name typed at sign-up becomes the client profile's.
final class GatewayRegistrationRepository implements RegistrationRepository {
  GatewayRegistrationRepository(this._transport);

  final GatewayTransport _transport;

  static const _update = r'''
mutation SaveRegistrationName($input: UpdateClientProfileInput!) {
  updateClientProfile(input: $input) { displayName }
}''';

  @override
  Future<Result<void, RegistrationFailure>> submit(
    RegistrationDraft draft,
  ) async {
    final name = '${draft.givenName.trim()} ${draft.familyName.trim()}'.trim();
    final saved = await guardGateway(
      () => _transport.run(
        _update,
        variables: {
          'input': {'displayName': name},
        },
      ),
    );
    return saved.map<void>((_) {}).mapFailure(
      (failure) => switch (failure) {
        DataUnavailable(:final detail) => RegistrationUnavailable(
          detail: detail,
        ),
        _ => RegistrationRejected(reason: failure.message),
      },
    );
  }
}
