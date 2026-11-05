import 'package:mano_domain/mano_domain.dart';

import '../billing/billing_documents.dart';
import '../billing/billing_json.dart';
import '../gateway/gateway_failure.dart';
import '../gateway/gateway_transport.dart';

/// [PayoutAccounts] over D6; the gateway cannot read or remove an account, so only this session's registration is known.
final class GatewayPayoutAccounts implements PayoutAccounts {
  GatewayPayoutAccounts(this._transport);

  final GatewayTransport _transport;
  PayoutAccount? _registered;

  @override
  Future<Result<PayoutAccount?, DataFailure>> current() async =>
      Ok(_registered);

  @override
  Future<Result<PayoutAccount, DataFailure>> register({
    required PayoutDestination destination,
    required AccountHolder holder,
  }) => guardGateway(() async {
    final data = await _transport.run(
      registerPayoutAccountMutation,
      variables: {'input': payoutAccountInput(destination, holder)},
    );
    final json = data['registerPayoutAccount'] as Map<String, dynamic>;
    return _registered = PayoutAccount(
      id: json['id'] as String,
      destination: destination,
      holder: holder,
    );
  });

  @override
  Future<Result<void, DataFailure>> remove(String accountId) async =>
      const Err(DataRejected(reason: 'billing cannot remove a payout account'));

  @override
  Future<Result<List<Bank>, DataFailure>> banks() => guardGateway(() async {
    final data = await _transport.run(payoutBanksQuery);
    return [
      for (final json in data['payoutBanks'] as List<dynamic>)
        bankFromJson(json as Map<String, dynamic>),
    ];
  });
}
