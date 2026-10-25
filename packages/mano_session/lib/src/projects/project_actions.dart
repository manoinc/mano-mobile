import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_domain/mano_domain.dart';

import 'project_providers.dart';

/// The requester's project actions; each success refreshes the project lists.
final class ProjectActions extends Notifier<void> {
  @override
  void build() {}

  ProjectRepository get _repo => ref.read(projectRepositoryProvider);

  Future<Result<Project, DataFailure>> publish(ProjectDraft draft) =>
      _refreshOnOk(_repo.publish(draft));

  Future<Result<Project, DataFailure>> cancel(String projectId) =>
      _refreshOnOk(_repo.cancel(projectId));

  Future<Result<Quote, DataFailure>> selectQuote(String quoteId) =>
      _refreshOnOk(_repo.selectQuote(quoteId));

  Future<Result<Quote, DataFailure>> discardQuote(String quoteId) =>
      _refreshOnOk(_repo.discardQuote(quoteId));

  Future<Result<T, DataFailure>> _refreshOnOk<T>(
    Future<Result<T, DataFailure>> action,
  ) async {
    final result = await action;
    // A project's status decides whether it is on the open board too.
    if (result.isOk) {
      ref
        ..invalidate(myProjectsProvider)
        ..invalidate(openProjectsProvider);
    }
    return result;
  }
}

final projectActionsProvider = NotifierProvider<ProjectActions, void>(
  ProjectActions.new,
);
