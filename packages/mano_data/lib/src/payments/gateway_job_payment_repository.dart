import 'package:mano_domain/mano_domain.dart';

import '../billing/billing_documents.dart';
import '../billing/billing_json.dart';
import '../gateway/gateway_failure.dart';
import '../gateway/gateway_transport.dart';

/// [JobPaymentRepository] over D6 (mano-billing).
final class GatewayJobPaymentRepository implements JobPaymentRepository {
  GatewayJobPaymentRepository(this._transport);

  final GatewayTransport _transport;

  @override
  Future<Result<JobPayment, DataFailure>> pay(JobPaymentDraft draft) async {
    if (!draft.isValid) {
      return Err(DataRejected(reason: 'invalid draft: ${draft.problems}'));
    }
    return guardGateway(() async {
      final data = await _transport.run(
        payJobMutation,
        variables: payJobVariables(draft),
      );
      return jobPaymentFromJson(data['payJob'] as Map<String, dynamic>);
    });
  }

  @override
  Future<Result<JobPayment?, DataFailure>> payment(String jobId) =>
      guardGateway(() async {
        final data = await _transport.run(
          jobPaymentQuery,
          variables: {'jobId': jobId},
        );
        final json = data['jobPayment'] as Map<String, dynamic>?;
        return json == null ? null : jobPaymentFromJson(json);
      });

  @override
  Future<Result<List<CheckoutTerm>, DataFailure>> checkoutTerms() =>
      guardGateway(() async {
        final data = await _transport.run(checkoutTermsQuery);
        return [
          for (final json in data['checkoutTerms'] as List<dynamic>)
            termFromJson(json as Map<String, dynamic>),
        ];
      });

  @override
  Future<Result<List<Bank>, DataFailure>> pseBanks() => guardGateway(() async {
    final data = await _transport.run(pseBanksQuery);
    return [
      for (final json in data['pseBanks'] as List<dynamic>)
        bankFromJson(json as Map<String, dynamic>),
    ];
  });
}
