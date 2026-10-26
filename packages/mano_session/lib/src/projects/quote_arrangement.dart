import 'package:mano_domain/mano_domain.dart';

/// How the requester compares quotes.
enum QuoteOrder { price, recency }

/// A project's quotes as the detail shows them: the pick pinned, discards apart.
({Quote? selected, List<Quote> active, List<Quote> discarded}) arrangeQuotes(
  List<Quote> quotes,
  QuoteOrder order,
) {
  int compare(Quote a, Quote b) => switch (order) {
    QuoteOrder.price => a.amountCop.compareTo(b.amountCop),
    QuoteOrder.recency => b.createdAt.compareTo(a.createdAt),
  };
  List<Quote> withStatus(QuoteStatus status) =>
      quotes.where((q) => q.status == status).toList()..sort(compare);

  return (
    selected: withStatus(QuoteStatus.selected).firstOrNull,
    active: withStatus(QuoteStatus.submitted),
    discarded: withStatus(QuoteStatus.discarded),
  );
}

/// What a project's quotes add up to, for its card.
extension ProjectQuotes on Project {
  /// The quotes still in play, discarded ones left out.
  List<Quote> get liveQuotes => [
    for (final q in quotes ?? const <Quote>[])
      if (q.status != QuoteStatus.discarded) q,
  ];

  int? get lowestQuoteCop => liveQuotes.isEmpty
      ? null
      : liveQuotes.map((q) => q.amountCop).reduce((a, b) => a < b ? a : b);

  Quote? get selectedQuote =>
      quotes?.where((q) => q.status == QuoteStatus.selected).firstOrNull;
}
