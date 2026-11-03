import '../session/credentials_validation.dart';
import '../shared/colombian_mobile.dart';
import '../shared/legal_id.dart';

/// How a coin pack is paid; cards need a tokenizer the app does not have yet.
enum CoinPurchaseMethod { nequi, pse }

enum PsePersonType { natural, juridical }

/// What is wrong with a [CoinPurchaseDraft]; the screen words it in Spanish.
enum CoinPurchaseProblem {
  noPack,
  noMethod,
  invalidPhone,
  noBank,
  invalidLegalId,
  invalidPayerEmail,
  termsNotAccepted,
}

/// A coin pack purchase being filled in, before it is sent.
final class CoinPurchaseDraft {
  const CoinPurchaseDraft({
    this.packId = '',
    this.method,
    this.phone = '',
    this.bankCode = '',
    this.personType = PsePersonType.natural,
    this.legalIdType = LegalIdType.cc,
    this.legalId = '',
    this.payerEmail = '',
    this.termsAccepted = false,
  });

  final String packId;
  final CoinPurchaseMethod? method;
  final String phone;

  /// A PSE institution code, from the server's list.
  final String bankCode;
  final PsePersonType personType;
  final LegalIdType legalIdType;
  final String legalId;
  final String payerEmail;
  final bool termsAccepted;

  /// Ten digits; only meaningful for a valid Nequi draft.
  String get nequiPhone => normalizeColombianMobile(phone) ?? phone;

  String get cleanLegalId => normalizeLegalId(legalId);

  Set<CoinPurchaseProblem> get problems => {
    if (packId.isEmpty) CoinPurchaseProblem.noPack,
    if (method == null) CoinPurchaseProblem.noMethod,
    if (method == CoinPurchaseMethod.nequi &&
        normalizeColombianMobile(phone) == null)
      CoinPurchaseProblem.invalidPhone,
    if (method == CoinPurchaseMethod.pse) ...{
      if (bankCode.isEmpty) CoinPurchaseProblem.noBank,
      if (!isValidLegalId(legalIdType, legalId))
        CoinPurchaseProblem.invalidLegalId,
    },
    if (validateEmail(payerEmail.trim()) != null)
      CoinPurchaseProblem.invalidPayerEmail,
    if (!termsAccepted) CoinPurchaseProblem.termsNotAccepted,
  };

  bool get isValid => problems.isEmpty;

  CoinPurchaseDraft copyWith({
    String? packId,
    CoinPurchaseMethod? method,
    String? phone,
    String? bankCode,
    PsePersonType? personType,
    LegalIdType? legalIdType,
    String? legalId,
    String? payerEmail,
    bool? termsAccepted,
  }) => CoinPurchaseDraft(
    packId: packId ?? this.packId,
    method: method ?? this.method,
    phone: phone ?? this.phone,
    bankCode: bankCode ?? this.bankCode,
    personType: personType ?? this.personType,
    legalIdType: legalIdType ?? this.legalIdType,
    legalId: legalId ?? this.legalId,
    payerEmail: payerEmail ?? this.payerEmail,
    termsAccepted: termsAccepted ?? this.termsAccepted,
  );
}
