import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_domain/mano_domain.dart';

import 'project_providers.dart';

/// The provider's quoting; free this round, no Mano coins involved.
final class LeadActions extends Notifier<void> {
  @override
  void build() {}

  Future<Result<Quote, DataFailure>> submitQuote(
    String projectId, {
    required int amountCop,
    String? message,
  }) async {
    final result = await ref
        .read(leadRepositoryProvider)
        .submitQuote(projectId, amountCop: amountCop, message: message);
    if (result.isOk) {
      ref
        ..invalidate(myQuotesProvider)
        ..invalidate(openProjectsProvider)
        // Offline the same board backs the requester's projects.
        ..invalidate(myProjectsProvider);
    }
    return result;
  }
}

final leadActionsProvider = NotifierProvider<LeadActions, void>(
  LeadActions.new,
);
