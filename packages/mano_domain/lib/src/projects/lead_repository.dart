import '../result.dart';
import '../shared/data_failure.dart';
import 'already_quoted.dart';
import 'project.dart';
import 'quote.dart';

/// Open projects a provider can quote on, and the quotes they sent.
abstract interface class LeadRepository {
  /// Open projects, newest first; [category] is a canonical id, exact match.
  Future<List<Project>> openProjects({String? category});

  /// One quote per provider per project; a second is refused (see [AlreadyQuoted]).
  Future<Result<Quote, DataFailure>> submitQuote(
    String projectId, {
    required int amountCop,
    String? message,
  });

  /// The signed-in provider's quotes, newest first.
  Future<List<Quote>> myQuotes();
}
