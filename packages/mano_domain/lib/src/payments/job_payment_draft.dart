import '../session/credentials_validation.dart';
import '../shared/colombian_mobile.dart';
import '../shared/legal_id.dart';
import '../wallet/coin_purchase_draft.dart' show PsePersonType;

/// How a finished job is paid; cards wait on a tokenizer.
enum JobPaymentMethod { nequi, pse }

enum JobPaymentProblem {
  noMethod,
  invalidPhone,
  noBank,
  invalidLegalId,
  invalidPayerEmail,
  termsNotAccepted,
}

/// Paying a finished job, being filled in (gateway: `payJob`).
final class JobPaymentDraft {
  const JobPaymentDraft({
    required this.jobId,
    this.method,
    this.phone = '',
    this.bankCode = '',
    this.personType = PsePersonType.natural,
    this.legalIdType = LegalIdType.cc,
    this.legalId = '',
    this.payerEmail = '',
    this.termsAccepted = false,
  });

  final String jobId;
  final JobPaymentMethod? method;
  final String phone;
  final String bankCode;
  final PsePersonType personType;
  final LegalIdType legalIdType;
  final String legalId;
  final String payerEmail;
  final bool termsAccepted;

  String get nequiPhone => normalizeColombianMobile(phone) ?? phone;
  String get cleanLegalId => normalizeLegalId(legalId);

  Set<JobPaymentProblem> get problems => {
    if (method == null) JobPaymentProblem.noMethod,
    if (method == JobPaymentMethod.nequi &&
        normalizeColombianMobile(phone) == null)
      JobPaymentProblem.invalidPhone,
    if (method == JobPaymentMethod.pse) ...{
      if (bankCode.isEmpty) JobPaymentProblem.noBank,
      if (!isValidLegalId(legalIdType, legalId))
        JobPaymentProblem.invalidLegalId,
    },
    if (validateEmail(payerEmail.trim()) != null)
      JobPaymentProblem.invalidPayerEmail,
    if (!termsAccepted) JobPaymentProblem.termsNotAccepted,
  };

  bool get isValid => problems.isEmpty;

  JobPaymentDraft copyWith({
    JobPaymentMethod? method,
    String? phone,
    String? bankCode,
    PsePersonType? personType,
    LegalIdType? legalIdType,
    String? legalId,
    String? payerEmail,
    bool? termsAccepted,
  }) => JobPaymentDraft(
    jobId: jobId,
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
