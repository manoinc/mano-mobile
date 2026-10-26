import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

// Domain → copy for the provider's Proyectos screens; mano_ui cannot see these types.

/// Quoting is free this round; it sits where the coin cost sits on Solicitudes.
const quoteCostLabel = 'Gratis';

String leadBudgetLabel(int? budgetCop) => budgetCop == null
    ? 'Sin presupuesto'
    : 'Presupuesto ${ManoFormat.cop(budgetCop)}';

ManoStatusTone quoteTone(Quote quote) => quote.status == QuoteStatus.selected
    ? ManoStatusTone.success
    : ManoStatusTone.neutral;

/// What a quote's own card says under its title.
String myQuoteSubtitle(Quote quote) => quote.status == QuoteStatus.selected
    ? 'El cliente te elegió. Pronto podrás contactarlo.'
    : 'Tu cotización ${ManoFormat.cop(quote.amountCop)}';

/// The failure of a quote, in the provider's words.
String quoteFailureMessage(DataFailure failure) {
  if (failure.isAlreadyQuoted) return 'Ya cotizaste este proyecto';
  if (failure.isClosedForQuotes) {
    return 'Este proyecto ya no recibe cotizaciones';
  }
  return failure.message;
}
