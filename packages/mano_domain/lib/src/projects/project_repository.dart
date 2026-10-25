import '../result.dart';
import '../shared/data_failure.dart';
import 'project.dart';
import 'project_draft.dart';
import 'quote.dart';

/// The requester's projects and the quotes they received.
abstract interface class ProjectRepository {
  /// Every project the signed-in requester published, newest first, with quotes.
  Future<List<Project>> mine();

  Future<Result<Project, DataFailure>> publish(ProjectDraft draft);

  Future<Result<Project, DataFailure>> cancel(String projectId);

  Future<Result<Quote, DataFailure>> selectQuote(String quoteId);

  Future<Result<Quote, DataFailure>> discardQuote(String quoteId);
}
