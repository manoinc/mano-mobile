import 'package:mano_domain/mano_domain.dart';

import '../gateway/gateway_json.dart';

// The billing wire format: D6 JSON to domain values and back.

/// The history line a coin purchase shows, shared with the mock.
String purchaseLabel(int coins) => 'Recarga de $coins coins';

/// The history line of a bought project lead, shared with the mock.
const leadSpendLabel = 'Contacto de proyecto';

CoinPack coinPackFromJson(Map<String, dynamic> json) => CoinPack(
  id: json['id'] as String,
  coins: json['coins'] as int,
  bonus: json['bonus'] as int? ?? 0,
  priceCop: ((json['price'] as Map<String, dynamic>)['amount'] as num).round(),
);

/// A `CoinMovement`: a purchase, a lead spend or a lead refund.
CoinTransaction coinMovementFromJson(Map<String, dynamic> json) {
  final coins = json['coins'] as int;
  final (kind, label) = switch (json['type']) {
    'LEAD_SPEND' => (CoinTransactionKind.leadSpend, leadSpendLabel),
    'LEAD_REFUND' => (CoinTransactionKind.refund, 'Reembolso de contacto'),
    _ => (CoinTransactionKind.purchase, purchaseLabel(coins)),
  };
  return CoinTransaction(
    id: json['id'] as String,
    kind: kind,
    amount: coins,
    label: label,
    at: dateTimeFromJson(json['createdAt']),
  );
}

LeadPricing leadPricingFromJson(Map<String, dynamic> json) => LeadPricing(
  defaultCoins: json['defaultCoins'] as int,
  prices: {
    for (final price in json['prices'] as List<dynamic>)
      ServiceCategories.normalize(
        (price as Map<String, dynamic>)['category'] as String,
      ): price['coins'] as int,
  },
);

Bank bankFromJson(Map<String, dynamic> json) =>
    Bank(code: json['code'] as String, name: json['name'] as String);

CheckoutTerm termFromJson(Map<String, dynamic> json) =>
    CheckoutTerm(label: json['label'] as String, url: json['url'] as String);

/// The next step of a `PaymentResult`, or a rejection when the charge failed.
Result<CoinPurchase, DataFailure> coinPurchaseFromJson(
  Map<String, dynamic> json,
) {
  final payment = json['payment'] as Map<String, dynamic>;
  final next = json['nextAction'] as Map<String, dynamic>;
  final id = payment['id'] as String;
  final coins = payment['coins'] as int? ?? 0;
  final status = payment['status'] as String;
  if (status == 'FAILED') {
    return Err(DataRejected(reason: payment['failureReason'] as String?));
  }
  final url = next['redirectUrl'] as String?;
  return Ok(switch (next['type']) {
    'AWAIT_APPROVAL' => AwaitingApproval(paymentId: id, coins: coins),
    'REDIRECT' when url != null && url.isNotEmpty => BankRedirect(
      paymentId: id,
      coins: coins,
      url: url,
    ),
    'NONE' when status == 'COMPLETED' => PurchaseCompleted(
      paymentId: id,
      coins: coins,
    ),
    _ => PurchasePending(paymentId: id, coins: coins),
  });
}

/// A valid [draft] as `buyCoinPack`'s variables.
Map<String, Object?> buyCoinPackVariables(CoinPurchaseDraft draft) => {
  'packId': draft.packId,
  'method': draft.method == CoinPurchaseMethod.pse
      ? _pseInput(
          draft.bankCode,
          draft.personType,
          draft.legalIdType,
          draft.cleanLegalId,
        )
      : _walletInput(draft.nequiPhone),
  'payerEmail': draft.payerEmail.trim(),
  'termsAccepted': draft.termsAccepted,
};

/// A valid [draft] as `payJob`'s variables.
Map<String, Object?> payJobVariables(JobPaymentDraft draft) => {
  'jobId': draft.jobId,
  'method': draft.method == JobPaymentMethod.pse
      ? _pseInput(
          draft.bankCode,
          draft.personType,
          draft.legalIdType,
          draft.cleanLegalId,
        )
      : _walletInput(draft.nequiPhone),
  'payerEmail': draft.payerEmail.trim(),
  'termsAccepted': draft.termsAccepted,
};

Map<String, Object?> _walletInput(String phone) => {
  'wallet': {'phone': phone},
};

Map<String, Object?> _pseInput(
  String bankCode,
  PsePersonType personType,
  LegalIdType legalIdType,
  String legalId,
) => {
  'pse': {
    'institutionCode': bankCode,
    'personType': switch (personType) {
      PsePersonType.natural => 'NATURAL',
      PsePersonType.juridical => 'JURIDICAL',
    },
    'legalIdType': legalIdTypeToJson(legalIdType),
    'legalId': legalId,
  },
};

/// A job's `PaymentResult`: the payment and what the payer does next.
JobPayment jobPaymentFromJson(Map<String, dynamic> json) {
  final payment = json['payment'] as Map<String, dynamic>;
  final next = json['nextAction'] as Map<String, dynamic>;
  final url = next['redirectUrl'] as String?;
  final hasUrl = url != null && url.isNotEmpty;
  return JobPayment(
    paymentId: payment['id'] as String,
    jobId: payment['jobId'] as String,
    amount: _pesos(payment['amount']),
    feeAmount: _pesos(payment['feeAmount']),
    status: switch ((payment['status'], next['type'])) {
      ('FAILED', _) => JobPaymentStatus.failed,
      ('COMPLETED', _) => JobPaymentStatus.completed,
      (_, 'AWAIT_APPROVAL') => JobPaymentStatus.awaitingApproval,
      (_, 'REDIRECT') when hasUrl => JobPaymentStatus.redirect,
      _ => JobPaymentStatus.pending,
    },
    redirectUrl: hasUrl ? url : null,
    failureReason: payment['failureReason'] as String?,
  );
}

int _pesos(Object? money) =>
    ((money! as Map<String, dynamic>)['amount'] as num).round();

/// `PayoutAccountInput`: exactly one destination, plus the holder.
Map<String, Object?> payoutAccountInput(
  PayoutDestination destination,
  AccountHolder holder,
) => {
  ...switch (destination) {
    NequiDestination(:final phone) => {
      'wallet': {'phone': phone},
    },
    BankDestination(
      :final bankCode,
      :final accountType,
      :final accountNumber,
    ) =>
      {
        'bank': {
          'bankCode': bankCode,
          'accountType': switch (accountType) {
            BankAccountType.savings => 'SAVINGS',
            BankAccountType.checking => 'CHECKING',
          },
          'accountNumber': accountNumber,
        },
      },
  },
  'holder': {
    'name': holder.name,
    'email': holder.email,
    'legalIdType': legalIdTypeToJson(holder.legalIdType),
    'legalId': holder.legalId,
  },
};

String legalIdTypeToJson(LegalIdType type) => type.name.toUpperCase();
