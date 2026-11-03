import 'package:mano_session/mano_session.dart';

// Payout domain -> Spanish (Colombia) copy.

String masked(String lastDigits) => '•••• $lastDigits';

String accountTypeLabel(BankAccountType type) => switch (type) {
  BankAccountType.savings => 'Ahorros',
  BankAccountType.checking => 'Corriente',
};

String legalIdTypeLabel(LegalIdType type) => switch (type) {
  LegalIdType.cc => 'CC',
  LegalIdType.ce => 'CE',
  LegalIdType.nit => 'NIT',
  LegalIdType.pp => 'PP',
};

/// "Nequi" or the bank's name.
String destinationTitle(PayoutDestination destination) => switch (destination) {
  NequiDestination() => 'Nequi',
  BankDestination(:final bankCode) =>
    ColombianBanks.byCode(bankCode)?.name ?? 'Banco',
};

/// "•••• 4567" or "Ahorros · •••• 1234".
String destinationDetail(PayoutDestination destination) =>
    switch (destination) {
      NequiDestination() => masked(destination.lastDigits),
      BankDestination(:final accountType) =>
        '${accountTypeLabel(accountType)} · ${masked(destination.lastDigits)}',
    };

/// One line for Perfil: "Bancolombia · •••• 1234".
String destinationLine(PayoutDestination destination) =>
    '${destinationTitle(destination)} · ${masked(destination.lastDigits)}';

/// "Andrés Castro · CC •••• 4050".
String holderLine(AccountHolder holder) {
  final id = holder.legalId;
  final last = id.length <= 4 ? id : id.substring(id.length - 4);
  return '${holder.name} · ${legalIdTypeLabel(holder.legalIdType)} '
      '${masked(last)}';
}

String? phoneError(PayoutAccountDraft draft) =>
    draft.phone.trim().isNotEmpty &&
        draft.problems.contains(PayoutAccountProblem.invalidPhone)
    ? 'Un celular de 10 dígitos que empiece por 3.'
    : null;

String? accountNumberError(PayoutAccountDraft draft) =>
    draft.accountNumber.trim().isNotEmpty &&
        draft.problems.contains(PayoutAccountProblem.invalidAccountNumber)
    ? 'Solo números, entre 6 y 20.'
    : null;

String? legalIdError(PayoutAccountDraft draft) =>
    draft.legalId.trim().isNotEmpty &&
        draft.problems.contains(PayoutAccountProblem.invalidLegalId)
    ? 'Revisa el número de documento.'
    : null;
