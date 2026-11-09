import 'package:mano_domain/mano_domain.dart';

import '../gateway/gateway_failure.dart';
import '../gateway/gateway_transport.dart';

const _fields = 'displayName photoUrl phone email';

/// [ClientProfileRepository] over D2 (mano-profiles); blanks fall back to [seed].
final class GatewayClientProfileRepository implements ClientProfileRepository {
  GatewayClientProfileRepository(this._transport, {required this.seed});

  final GatewayTransport _transport;

  /// What sign-up knew, for an account the profiles service has not seen yet.
  final ClientProfile seed;

  static const _query =
      'query ClientProfile { viewer { clientProfile { $_fields } } }';

  static const _update =
      '''
mutation UpdateClientProfile(\$input: UpdateClientProfileInput!) {
  updateClientProfile(input: \$input) { $_fields }
}''';

  @override
  Future<ClientProfile> profile() async {
    final data = await _transport.run(_query);
    final viewer = data['viewer'] as Map<String, dynamic>;
    return _fromJson(viewer['clientProfile'] as Map<String, dynamic>?);
  }

  @override
  Future<Result<ClientProfile, DataFailure>> update(
    ClientProfile profile,
  ) async {
    if (profile.problems.isNotEmpty) {
      return Err(DataRejected(reason: '${profile.problems}'));
    }
    return _write(_contact(profile));
  }

  static Map<String, Object?> _contact(ClientProfile profile) => {
    'displayName': profile.displayName.trim(),
    'phone': profile.phone.trim(),
    'email': profile.email.trim(),
  };

  @override
  Future<Result<ClientProfile, DataFailure>> updatePhoto(
    MediaAttachment photo,
  ) => _write({'photoMediaId': photo.id});

  Future<Result<ClientProfile, DataFailure>> _write(
    Map<String, Object?> input,
  ) => guardGateway(() async {
    final data = await _transport.run(_update, variables: {'input': input});
    return _fromJson(data['updateClientProfile'] as Map<String, dynamic>);
  });

  ClientProfile _fromJson(Map<String, dynamic>? json) {
    String or(String key, String fallback) {
      final value = json?[key] as String? ?? '';
      return value.isEmpty ? fallback : value;
    }

    return ClientProfile(
      displayName: or('displayName', seed.displayName),
      phone: or('phone', seed.phone),
      email: or('email', seed.email),
      photoUrl: json?['photoUrl'] as String? ?? seed.photoUrl,
    );
  }
}
