import 'package:mano_domain/mano_domain.dart';

import '../gateway/gateway_failure.dart';
import '../gateway/gateway_transport.dart';
import 'project_json.dart';

/// [LeadRepository] over the gateway's D9 operations; quotes are free, leads cost coins.
final class GatewayLeadRepository implements LeadRepository {
  const GatewayLeadRepository(this._transport);

  final GatewayTransport _transport;

  static const _openQuery =
      '''
query OpenProjects(\$category: String) {
  openProjects(category: \$category, page: {first: 50}) { items { $projectFields } }
}''';

  static const _submitMutation =
      '''
mutation SubmitQuote(\$projectId: ID!, \$input: QuoteInput!) {
  submitQuote(projectId: \$projectId, input: \$input) { $standaloneQuoteFields }
}''';

  static const _myQuotesQuery =
      '''
query MyQuotes {
  myQuotes(page: {first: 50}) { items { $standaloneQuoteFields } }
}''';

  static const _purchaseMutation =
      '''
mutation PurchaseLead(\$quoteId: ID!) {
  purchaseProjectLead(quoteId: \$quoteId) { $standaloneQuoteFields }
}''';

  @override
  Future<List<Project>> openProjects({String? category}) async {
    final data = await _transport.run(
      _openQuery,
      variables: {'category': category},
    );
    return pageItems(data['openProjects']).map(projectFromJson).toList();
  }

  @override
  Future<Result<Quote, DataFailure>> submitQuote(
    String projectId, {
    required int amountCop,
    String? message,
  }) => guardGateway(() async {
    final data = await _transport.run(
      _submitMutation,
      variables: {
        'projectId': projectId,
        'input': {'amount': amountCop, 'message': message},
      },
    );
    return quoteFromJson(data['submitQuote'] as Map<String, dynamic>);
  });

  @override
  Future<List<Quote>> myQuotes() async {
    final data = await _transport.run(_myQuotesQuery);
    return pageItems(data['myQuotes']).map(quoteFromJson).toList();
  }

  @override
  Future<Result<Quote, DataFailure>> purchaseLead(String quoteId) =>
      guardGateway(() async {
        final data = await _transport.run(
          _purchaseMutation,
          variables: {'quoteId': quoteId},
        );
        return quoteFromJson(
          data['purchaseProjectLead'] as Map<String, dynamic>,
        );
      });
}
