import 'package:mano_domain/mano_domain.dart';

import '../gateway/gateway_failure.dart';
import '../gateway/gateway_transport.dart';

/// [ReferralLinker] over D2; codes match exactly, so only whitespace is trimmed.
final class GatewayReferralLinker implements ReferralLinker {
  GatewayReferralLinker(this._transport);

  final GatewayTransport _transport;

  static const _link = '''
mutation LinkWorker(\$code: String!) {
  linkWorkerByReferralCode(code: \$code) { displayName }
}''';

  @override
  Future<Result<String, DataFailure>> link(String code) async {
    final clean = code.trim();
    if (clean.isEmpty) return const Err(DataRejected(reason: 'empty code'));
    return guardGateway(() async {
      final data = await _transport.run(_link, variables: {'code': clean});
      final worker = data['linkWorkerByReferralCode'] as Map<String, dynamic>;
      return worker['displayName'] as String? ?? '';
    });
  }
}
