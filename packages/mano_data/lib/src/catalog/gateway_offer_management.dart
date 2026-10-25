import 'package:mano_domain/mano_domain.dart';

import '../gateway/gateway_failure.dart';
import '../gateway/gateway_transport.dart';
import '../gateway/offer_json.dart';

/// [OfferManagement] backed by the gateway's offer mutations (auth required).
final class GatewayOfferManagement implements OfferManagement {
  const GatewayOfferManagement(this._transport);

  final GatewayTransport _transport;

  static const _mineQuery =
      '''
query MyOffers(\$includeDeleted: Boolean) {
  myJobServiceOffers(includeDeleted: \$includeDeleted) { $offerFields }
}''';

  static const _createMutation =
      '''
mutation Create(\$input: CreateJobServiceOfferInput!) {
  createJobServiceOffer(input: \$input) { $offerFields }
}''';

  static const _updateMutation =
      '''
mutation Update(\$id: ID!, \$input: UpdateJobServiceOfferInput!) {
  updateJobServiceOffer(id: \$id, input: \$input) { $offerFields }
}''';

  @override
  Future<List<ServiceOffer>> myOffers() async {
    final data = await _transport.run(
      _mineQuery,
      variables: {'includeDeleted': false},
    );
    return (data['myJobServiceOffers'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(offerFromJson)
        .where((o) => o.status != OfferStatus.deleted)
        .toList();
  }

  @override
  Future<Result<ServiceOffer, DataFailure>> create({
    required String jobServiceId,
    required RateType rateType,
    required int amountCop,
    required String zone,
  }) => _offer(_createMutation, 'createJobServiceOffer', {
    'input': {
      'jobServiceId': jobServiceId,
      'rateType': rateTypeToJson(rateType),
      'amount': amountCop,
      'zone': zone,
    },
  });

  @override
  Future<Result<ServiceOffer, DataFailure>> update(
    String offerId, {
    RateType? rateType,
    int? amountCop,
    String? zone,
  }) => _offer(_updateMutation, 'updateJobServiceOffer', {
    'id': offerId,
    'input': {
      'rateType': ?(rateType == null ? null : rateTypeToJson(rateType)),
      'amount': ?amountCop,
      'zone': ?zone,
    },
  });

  @override
  Future<Result<ServiceOffer, DataFailure>> pause(String offerId) =>
      _byId('pauseJobServiceOffer', offerId);

  @override
  Future<Result<ServiceOffer, DataFailure>> resume(String offerId) =>
      _byId('resumeJobServiceOffer', offerId);

  /// Soft delete: the gateway answers with the offer, status DELETED.
  @override
  Future<Result<ServiceOffer, DataFailure>> delete(String offerId) =>
      _byId('deleteJobServiceOffer', offerId);

  Future<Result<ServiceOffer, DataFailure>> _byId(String field, String id) =>
      _offer(
        'mutation Transition(\$id: ID!) { $field(id: \$id) { $offerFields } }',
        field,
        {'id': id},
      );

  Future<Result<ServiceOffer, DataFailure>> _offer(
    String document,
    String field,
    Map<String, Object?> variables,
  ) => guardGateway(() async {
    final data = await _transport.run(document, variables: variables);
    return offerFromJson(data[field] as Map<String, dynamic>);
  });
}
