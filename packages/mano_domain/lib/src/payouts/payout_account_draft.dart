import '../shared/colombian_mobile.dart';
import 'colombian_banks.dart';
import 'payout_account.dart';

enum PayoutMethod { nequi, bank }

/// The questions of the payout flow, in order; Nequi skips [bank].
enum PayoutAccountStep { method, bank, destination, holder }

/// What is wrong with a [PayoutAccountDraft]; the screen words it in Spanish.
enum PayoutAccountProblem {
  noMethod(PayoutAccountStep.method),
  noBank(PayoutAccountStep.bank),
  invalidPhone(PayoutAccountStep.destination),
  noAccountType(PayoutAccountStep.destination),
  invalidAccountNumber(PayoutAccountStep.destination),
  emptyHolderName(PayoutAccountStep.holder),
  invalidLegalId(PayoutAccountStep.holder);

  const PayoutAccountProblem(this.step);

  /// The question that fixes it.
  final PayoutAccountStep step;
}

final _separators = RegExp(r'[\s.\-]');

/// A payout account being entered, before it is registered.
final class PayoutAccountDraft {
  const PayoutAccountDraft({
    this.method,
    this.phone = '',
    this.bankCode = '',
    this.accountType,
    this.accountNumber = '',
    this.holderName = '',
    this.legalIdType = LegalIdType.cc,
    this.legalId = '',
  });

  final PayoutMethod? method;
  final String phone;
  final String bankCode;
  final BankAccountType? accountType;
  final String accountNumber;
  final String holderName;
  final LegalIdType legalIdType;
  final String legalId;

  String get _accountDigits => accountNumber.replaceAll(_separators, '');
  String get _legalIdClean => legalId.replaceAll(_separators, '').toUpperCase();

  Set<PayoutAccountProblem> get problems => {
    if (method == null) PayoutAccountProblem.noMethod,
    if (method == PayoutMethod.nequi && normalizeColombianMobile(phone) == null)
      PayoutAccountProblem.invalidPhone,
    if (method == PayoutMethod.bank) ...{
      if (ColombianBanks.byCode(bankCode) == null) PayoutAccountProblem.noBank,
      if (accountType == null) PayoutAccountProblem.noAccountType,
      if (!RegExp(r'^\d{6,20}$').hasMatch(_accountDigits))
        PayoutAccountProblem.invalidAccountNumber,
    },
    if (holderName.trim().isEmpty) PayoutAccountProblem.emptyHolderName,
    if (!_legalIdPattern(legalIdType).hasMatch(_legalIdClean))
      PayoutAccountProblem.invalidLegalId,
  };

  bool get isValid => problems.isEmpty;

  /// Whether [step] has nothing left to fix.
  bool answers(PayoutAccountStep step) => problems.every((p) => p.step != step);

  /// Only meaningful while [isValid].
  PayoutDestination get destination => method == PayoutMethod.nequi
      ? NequiDestination(phone: normalizeColombianMobile(phone) ?? phone)
      : BankDestination(
          bankCode: bankCode,
          accountType: accountType ?? BankAccountType.savings,
          accountNumber: _accountDigits,
        );

  AccountHolder get holder => AccountHolder(
    name: holderName.trim(),
    legalIdType: legalIdType,
    legalId: _legalIdClean,
  );

  PayoutAccountDraft copyWith({
    PayoutMethod? method,
    String? phone,
    String? bankCode,
    BankAccountType? accountType,
    String? accountNumber,
    String? holderName,
    LegalIdType? legalIdType,
    String? legalId,
  }) => PayoutAccountDraft(
    method: method ?? this.method,
    phone: phone ?? this.phone,
    bankCode: bankCode ?? this.bankCode,
    accountType: accountType ?? this.accountType,
    accountNumber: accountNumber ?? this.accountNumber,
    holderName: holderName ?? this.holderName,
    legalIdType: legalIdType ?? this.legalIdType,
    legalId: legalId ?? this.legalId,
  );
}

// CC 6-10 digits, CE 6-12 alphanumeric, NIT 9-10 digits (with check digit), PP 5-12.
RegExp _legalIdPattern(LegalIdType type) => switch (type) {
  LegalIdType.cc => RegExp(r'^\d{6,10}$'),
  LegalIdType.ce => RegExp(r'^[A-Z0-9]{6,12}$'),
  LegalIdType.nit => RegExp(r'^\d{9,10}$'),
  LegalIdType.pp => RegExp(r'^[A-Z0-9]{5,12}$'),
};
