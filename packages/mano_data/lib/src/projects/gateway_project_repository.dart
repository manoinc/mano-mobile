import 'package:mano_domain/mano_domain.dart';

import '../gateway/gateway_failure.dart';
import '../gateway/gateway_transport.dart';
import 'project_json.dart';

/// [ProjectRepository] over the gateway's D9 projects operations.
final class GatewayProjectRepository implements ProjectRepository {
  const GatewayProjectRepository(this._transport);

  final GatewayTransport _transport;

  static const _mineQuery =
      '''
query MyProjects {
  myProjects(page: {first: 50}) { items { $ownedProjectFields } }
}''';

  static const _publishMutation =
      '''
mutation Publish(\$input: ProjectInput!) {
  publishProject(input: \$input) { $ownedProjectFields }
}''';

  static const _cancelMutation =
      '''
mutation Cancel(\$id: ID!) {
  cancelProject(projectId: \$id) { $ownedProjectFields }
}''';

  static const _selectMutation = '''
mutation Select(\$id: ID!) { selectQuote(quoteId: \$id) { $standaloneQuoteFields } }''';

  static const _discardMutation = '''
mutation Discard(\$id: ID!) { discardQuote(quoteId: \$id) { $standaloneQuoteFields } }''';

  @override
  Future<List<Project>> mine() async {
    final data = await _transport.run(_mineQuery);
    return pageItems(data['myProjects']).map(projectFromJson).toList();
  }

  @override
  Future<Result<Project, DataFailure>> publish(ProjectDraft draft) async {
    if (!draft.isValid) {
      return Err(DataRejected(reason: 'InvalidArgument: ${draft.problems}'));
    }
    return guardGateway(() async {
      final data = await _transport.run(
        _publishMutation,
        variables: {
          'input': {
            'category': draft.category,
            'title': draft.title.trim(),
            'description': draft.description.trim(),
            'photos': draft.photoUrls,
            'estimatedBudget': draft.budgetCop,
          },
        },
      );
      return projectFromJson(data['publishProject'] as Map<String, dynamic>);
    });
  }

  @override
  Future<Result<Project, DataFailure>> cancel(String projectId) =>
      guardGateway(() async {
        final data = await _transport.run(
          _cancelMutation,
          variables: {'id': projectId},
        );
        return projectFromJson(data['cancelProject'] as Map<String, dynamic>);
      });

  @override
  Future<Result<Quote, DataFailure>> selectQuote(String quoteId) =>
      _decide(_selectMutation, 'selectQuote', quoteId);

  @override
  Future<Result<Quote, DataFailure>> discardQuote(String quoteId) =>
      _decide(_discardMutation, 'discardQuote', quoteId);

  Future<Result<Quote, DataFailure>> _decide(
    String mutation,
    String field,
    String quoteId,
  ) => guardGateway(() async {
    final data = await _transport.run(mutation, variables: {'id': quoteId});
    return quoteFromJson(data[field] as Map<String, dynamic>);
  });
}
