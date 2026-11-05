import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../wallet/wallet_labels.dart';

// Domain → copy for the provider's Proyectos screens; mano_ui cannot see these types.

/// Quoting is free this round; it sits where the coin cost sits on Solicitudes.
const quoteCostLabel = 'Gratis';

String leadBudgetLabel(int? budgetCop) => budgetCop == null
    ? 'Sin presupuesto'
    : 'Presupuesto ${ManoFormat.cop(budgetCop)}';

ManoStatusTone quoteTone(Quote quote) => quote.status == QuoteStatus.selected
    ? ManoStatusTone.success
    : ManoStatusTone.neutral;

/// What a quote's own card says under its title; [prices] null while loading.
String myQuoteSubtitle(Quote quote, LeadPricing? prices) => switch (quote) {
  Quote(leadPurchased: true) => 'Contacto desbloqueado. Escríbele al cliente.',
  Quote(status: QuoteStatus.selected) when prices != null =>
    'El cliente te eligió. Compra su contacto por '
        '${leadCostLabel(prices, quote.projectCategory)}.',
  Quote(status: QuoteStatus.selected) =>
    'El cliente te eligió. Compra su contacto.',
  _ => 'Tu cotización ${ManoFormat.cop(quote.amountCop)}',
};

/// Under an awarded project's title: its category and the provider's price.
String awardedQuoteLine(Quote quote) => [
  if (quote.projectCategory.isNotEmpty)
    ServiceCategories.labelOf(quote.projectCategory),
  'Tu cotización ${ManoFormat.cop(quote.amountCop)}',
].join(' · ');

/// What the lead of a project in [category] costs.
String leadCostLabel(LeadPricing prices, String category) =>
    coinsLabel(prices.costFor(category));

/// A selected quote whose lead is still to buy.
bool canBuyLead(Quote quote) =>
    quote.status == QuoteStatus.selected && !quote.leadPurchased;

/// The failure of a quote, in the provider's words.
String quoteFailureMessage(DataFailure failure) {
  if (failure.isAlreadyQuoted) return 'Ya cotizaste este proyecto';
  if (failure.isClosedForQuotes) {
    return 'Este proyecto ya no recibe cotizaciones';
  }
  return failure.message;
}
