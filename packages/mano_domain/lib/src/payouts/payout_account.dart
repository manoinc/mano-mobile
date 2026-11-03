// Shaped on mano-billing's RegisterPayoutAccount, ready for Wompi payouts.

import '../shared/legal_id.dart';

enum BankAccountType { savings, checking }

/// Where payouts land: a Nequi wallet or a bank account.
sealed class PayoutDestination {
  const PayoutDestination();

  /// The last four digits, for a masked "•••• 1234".
  String get lastDigits;
}

String _lastFour(String digits) =>
    digits.length <= 4 ? digits : digits.substring(digits.length - 4);

final class NequiDestination extends PayoutDestination {
  const NequiDestination({required this.phone});

  /// Ten digits, starting with 3.
  final String phone;

  @override
  String get lastDigits => _lastFour(phone);

  @override
  bool operator ==(Object other) =>
      other is NequiDestination && other.phone == phone;

  @override
  int get hashCode => phone.hashCode;
}

final class BankDestination extends PayoutDestination {
  const BankDestination({
    required this.bankCode,
    required this.accountType,
    required this.accountNumber,
  });

  final String bankCode;
  final BankAccountType accountType;

  /// Digits only.
  final String accountNumber;

  @override
  String get lastDigits => _lastFour(accountNumber);

  @override
  bool operator ==(Object other) =>
      other is BankDestination &&
      other.bankCode == bankCode &&
      other.accountType == accountType &&
      other.accountNumber == accountNumber;

  @override
  int get hashCode => Object.hash(bankCode, accountType, accountNumber);
}

/// Who owns the destination; payouts go only to the provider's own name.
final class AccountHolder {
  const AccountHolder({
    required this.name,
    required this.email,
    required this.legalIdType,
    required this.legalId,
  });

  final String name;

  /// Where the payout provider writes about the account.
  final String email;
  final LegalIdType legalIdType;
  final String legalId;

  @override
  bool operator ==(Object other) =>
      other is AccountHolder &&
      other.name == name &&
      other.email == email &&
      other.legalIdType == legalIdType &&
      other.legalId == legalId;

  @override
  int get hashCode => Object.hash(name, email, legalIdType, legalId);
}

/// The registered account a provider's earnings are paid into.
final class PayoutAccount {
  const PayoutAccount({
    required this.id,
    required this.destination,
    required this.holder,
  });

  final String id;
  final PayoutDestination destination;
  final AccountHolder holder;
}
