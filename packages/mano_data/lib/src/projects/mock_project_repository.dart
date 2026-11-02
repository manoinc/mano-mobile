import 'package:mano_domain/mano_domain.dart';

import '../mock/mock_fixtures.dart';
import 'mock_project_board.dart';

/// In-memory [ProjectRepository], signed in as the mock requester.
final class MockProjectRepository implements ProjectRepository {
  MockProjectRepository(this._board, {String? clientId})
    : _clientId = clientId ?? mockClient.id;

  final MockProjectBoard _board;
  final String _clientId;

  @override
  Future<List<Project>> mine() async => [
    for (final p in _board.projects)
      if (_board.owners[p.id] == _clientId) p,
  ];

  @override
  Future<Result<Project, DataFailure>> publish(ProjectDraft draft) async {
    if (!draft.isValid) {
      return Err(DataRejected(reason: 'InvalidArgument: ${draft.problems}'));
    }
    final project = Project(
      id: _board.nextId('project'),
      category: draft.category,
      title: draft.title.trim(),
      description: draft.description.trim(),
      budgetCop: draft.budgetCop,
      photoUrls: draft.photoUrls,
      status: ProjectStatus.open,
      createdAt: _board.now(),
      quotes: const [],
    );
    _board.projects.insert(0, project);
    _board.owners[project.id] = _clientId;
    return Ok(project);
  }

  @override
  Future<Result<Project, DataFailure>> cancel(String projectId) async {
    final project = _board.byId(projectId);
    if (project == null || _board.owners[projectId] != _clientId) {
      return const Err(DataNotFound());
    }
    if (!project.canCancel) return _precondition(project);
    final cancelled = project.copyWith(status: ProjectStatus.cancelled);
    _board.replace(cancelled);
    return Ok(cancelled);
  }

  @override
  Future<Result<Quote, DataFailure>> selectQuote(String quoteId) =>
      _decide(quoteId, (project, quote) => project.canSelect(quote), (q) {
        if (q.id == quoteId) return q.copyWith(status: QuoteStatus.selected);
        // Selecting swaps out the earlier pick.
        if (q.status == QuoteStatus.selected) {
          return q.copyWith(status: QuoteStatus.discarded);
        }
        return q;
      });

  @override
  Future<Result<Quote, DataFailure>> discardQuote(String quoteId) => _decide(
    quoteId,
    (project, quote) => project.canDiscard(quote),
    (q) => q.id == quoteId ? q.copyWith(status: QuoteStatus.discarded) : q,
  );

  Future<Result<Quote, DataFailure>> _decide(
    String quoteId,
    bool Function(Project project, Quote quote) allowed,
    Quote Function(Quote quote) update,
  ) async {
    final project = _board.holding(quoteId);
    if (project == null || _board.owners[project.id] != _clientId) {
      return const Err(DataNotFound());
    }
    final quote = project.quotes!.firstWhere((q) => q.id == quoteId);
    if (!allowed(project, quote)) return _precondition(project);
    final quotes = project.quotes!.map(update).toList();
    final awarded = quotes.any((q) => q.status == QuoteStatus.selected);
    _board.replace(
      project.copyWith(
        quotes: quotes,
        status: awarded ? ProjectStatus.awarded : ProjectStatus.open,
      ),
    );
    return Ok(quotes.firstWhere((q) => q.id == quoteId));
  }

  Err<T, DataFailure> _precondition<T>(Project project) => Err(
    DataRejected(
      reason: 'FailedPrecondition: project ${project.id} is ${project.status}',
    ),
  );
}
