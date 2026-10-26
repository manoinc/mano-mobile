import 'package:mano_session/mano_session.dart';

import '../../support/fake_session_repository.dart';

/// A session with an account behind it, for actions guests can't take.
FakeSessionRepository signedIn() =>
    FakeSessionRepository(onRestore: () async => Ok(fakeSession()));

/// A leads port with fixed lists, refusing every quote with [refusal].
final class FakeLeads implements LeadRepository {
  FakeLeads({
    this.open = const [],
    this.quotes = const [],
    this.fails = false,
    this.refusal = const DataUnavailable(),
  });

  final List<Project> open;
  final List<Quote> quotes;
  final bool fails;
  final DataFailure refusal;

  @override
  Future<List<Project>> openProjects({String? category}) async {
    if (fails) throw StateError('offline');
    return [
      for (final p in open)
        if (category == null || p.category == category) p,
    ];
  }

  @override
  Future<Result<Quote, DataFailure>> submitQuote(
    String projectId, {
    required int amountCop,
    String? message,
  }) async => Err(refusal);

  @override
  Future<List<Quote>> myQuotes() async {
    if (fails) throw StateError('offline');
    return quotes;
  }
}

Project openProject({String id = 'project-9', int? budget}) => Project(
  id: id,
  category: ServiceCategories.painting,
  title: 'Pintar la fachada',
  description: 'Casa de dos pisos.',
  budgetCop: budget,
  status: ProjectStatus.open,
  createdAt: DateTime.now().subtract(const Duration(hours: 2)),
);
