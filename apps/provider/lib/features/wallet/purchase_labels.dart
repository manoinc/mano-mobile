import 'package:mano_session/mano_session.dart';

// Coin purchase domain -> Spanish (Colombia) copy for the Recargar sheet.

String methodLabel(CoinPurchaseMethod method) => switch (method) {
  CoinPurchaseMethod.nequi => 'Nequi',
  CoinPurchaseMethod.pse => 'PSE',
};

String personTypeLabel(PsePersonType type) => switch (type) {
  PsePersonType.natural => 'Persona natural',
  PsePersonType.juridical => 'Persona jurídica',
};

String? purchasePhoneError(CoinPurchaseDraft draft) =>
    draft.phone.trim().isNotEmpty &&
        draft.problems.contains(CoinPurchaseProblem.invalidPhone)
    ? 'Un celular de 10 dígitos que empiece por 3.'
    : null;

String? purchaseLegalIdError(CoinPurchaseDraft draft) =>
    draft.legalId.trim().isNotEmpty &&
        draft.problems.contains(CoinPurchaseProblem.invalidLegalId)
    ? 'Revisa el número de documento.'
    : null;

String? payerEmailError(CoinPurchaseDraft draft) =>
    draft.payerEmail.trim().isNotEmpty &&
        draft.problems.contains(CoinPurchaseProblem.invalidPayerEmail)
    ? 'Revisa el correo.'
    : null;

/// Why a purchase failed, without the backend's wording.
String purchaseFailureMessage(DataFailure failure) => switch (failure) {
  DataRejected() => 'El pago fue rechazado. No te cobramos nada.',
  _ => failure.message,
};
