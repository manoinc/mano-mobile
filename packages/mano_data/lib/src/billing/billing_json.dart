import 'package:mano_domain/mano_domain.dart';

import '../gateway/gateway_json.dart';

// The billing wire format: D6 JSON to domain values and back.

/// The history line a coin purchase shows, shared with the mock.
String purchaseLabel(int coins) => 'Recarga de $coins coins';

CoinPack coinPackFromJson(Map<String, dynamic> json) => CoinPack(
  id: json['id'] as String,
  coins: json['coins'] as int,
  bonus: json['bonus'] as int? ?? 0,
  priceCop: ((json['price'] as Map<String, dynamic>)['amount'] as num).round(),
);

/// Only purchases exist on the gateway today (`CoinMovementType.PURCHASE`).
CoinTransaction coinMovementFromJson(Map<String, dynamic> json) {
  final coins = json['coins'] as int;
  return CoinTransaction(
    id: json['id'] as String,
    kind: CoinTransactionKind.purchase,
    amount: coins,
    label: purchaseLabel(coins),
    at: dateTimeFromJson(json['createdAt']),
  );
}

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
  'method': switch (draft.method) {
    CoinPurchaseMethod.pse => {
      'pse': {
        'institutionCode': draft.bankCode,
        'personType': switch (draft.personType) {
          PsePersonType.natural => 'NATURAL',
          PsePersonType.juridical => 'JURIDICAL',
        },
        'legalIdType': legalIdTypeToJson(draft.legalIdType),
        'legalId': draft.cleanLegalId,
      },
    },
    _ => {
      'wallet': {'phone': draft.nequiPhone},
    },
  },
  'payerEmail': draft.payerEmail.trim(),
  'termsAccepted': draft.termsAccepted,
};

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
