import 'package:mano_domain/mano_domain.dart';

import '../mock/mock_fixtures.dart';
import 'mock_project_board.dart';

/// In-memory [LeadRepository], signed in as the mock provider; offline a lead spends no coins.
final class MockLeadRepository implements LeadRepository {
  MockLeadRepository(this._board, {Party? worker})
    : _worker = worker ?? mockProviders.first;

  final MockProjectBoard _board;
  final Party _worker;

  @override
  Future<List<Project>> openProjects({String? category}) async => [
    for (final p in _board.projects)
      if (p.acceptsQuotes && (category == null || p.category == category))
        // Quotes are the owner's to see.
        Project(
          id: p.id,
          category: p.category,
          title: p.title,
          description: p.description,
          photoUrls: p.photoUrls,
          budgetCop: p.budgetCop,
          status: p.status,
          createdAt: p.createdAt,
        ),
  ];

  @override
  Future<Result<Quote, DataFailure>> submitQuote(
    String projectId, {
    required int amountCop,
    String? message,
  }) async {
    final project = _board.byId(projectId);
    if (project == null) return const Err(DataNotFound());
    if (!project.acceptsQuotes) {
      return Err(
        DataRejected(reason: 'FailedPrecondition: project is not open'),
      );
    }
    if (amountCop < 0) {
      return const Err(
        DataRejected(reason: 'InvalidArgument: negative amount'),
      );
    }
    if (project.quotes!.any((q) => q.worker.id == _worker.id)) {
      return const Err(
        DataRejected(reason: 'AlreadyExists: one quote per worker'),
      );
    }
    final trimmed = message?.trim();
    final quote = Quote(
      id: _board.nextId('quote'),
      projectId: project.id,
      projectTitle: project.title,
      worker: _worker,
      amountCop: amountCop,
      message: trimmed == null || trimmed.isEmpty ? null : trimmed,
      status: QuoteStatus.submitted,
      createdAt: _board.now(),
    );
    _board.replace(project.copyWith(quotes: [...project.quotes!, quote]));
    return Ok(quote);
  }

  @override
  Future<List<Quote>> myQuotes() async => [
    for (final p in _board.projects)
      for (final q in p.quotes!)
        if (q.worker.id == _worker.id) q.copyWith(projectCategory: p.category),
  ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<Result<Quote, DataFailure>> purchaseLead(String quoteId) async {
    final project = _board.holding(quoteId);
    final quote = project?.quotes!.firstWhere((q) => q.id == quoteId);
    if (project == null || quote == null || quote.worker.id != _worker.id) {
      return const Err(DataNotFound());
    }
    if (quote.status != QuoteStatus.selected) {
      return const Err(
        DataRejected(reason: 'FailedPrecondition: the quote is not selected'),
      );
    }
    final bought = quote.copyWith(
      leadPurchased: true,
      projectCategory: project.category,
    );
    _board.replace(
      project.copyWith(
        quotes: [for (final q in project.quotes!) q.id == quoteId ? bought : q],
      ),
    );
    return Ok(bought);
  }
}
