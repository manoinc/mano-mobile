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
    this.purchaseRefusal,
  });

  final List<Project> open;
  final List<Quote> quotes;
  final bool fails;
  final DataFailure refusal;

  /// Refuses lead purchases when set; otherwise the lead is bought.
  final DataFailure? purchaseRefusal;
  final List<String> purchased = [];

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
    return [
      for (final q in quotes)
        purchased.contains(q.id) ? q.copyWith(leadPurchased: true) : q,
    ];
  }

  @override
  Future<Result<Quote, DataFailure>> purchaseLead(String quoteId) async {
    if (purchaseRefusal case final refusal?) return Err(refusal);
    purchased.add(quoteId);
    return Ok(
      quotes.firstWhere((q) => q.id == quoteId).copyWith(leadPurchased: true),
    );
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
