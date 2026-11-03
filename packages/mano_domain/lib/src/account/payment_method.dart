import '../registration/registration_validation.dart';
import '../shared/mobile_phone.dart';
import 'card_validation.dart';

enum PaymentKind { card, nequi, pse }

enum PaymentField { cardNumber, expiry, phone }

/// A saved way to pay, display data only: never a full card number.
final class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.kind,
    required this.label,
    required this.last4,
    this.isDefault = false,
  });

  final String id;
  final PaymentKind kind;

  /// The brand or wallet, e.g. Visa or Nequi.
  final String label;
  final String last4;
  final bool isDefault;

  PaymentMethod copyWith({bool? isDefault}) => PaymentMethod(
    id: id,
    kind: kind,
    label: label,
    last4: last4,
    isDefault: isDefault ?? this.isDefault,
  );

  @override
  bool operator ==(Object other) =>
      other is PaymentMethod &&
      other.id == id &&
      other.kind == kind &&
      other.label == label &&
      other.last4 == last4 &&
      other.isDefault == isDefault;

  @override
  int get hashCode => Object.hash(id, kind, label, last4, isDefault);
}

/// What the Solicitante typed to add a method; only [storedAs] is ever kept.
sealed class NewPaymentMethod {
  const NewPaymentMethod();

  Map<PaymentField, FieldProblem> problems(DateTime now);

  PaymentMethod storedAs(String id);
}

final class NewCard extends NewPaymentMethod {
  const NewCard({required this.number, required this.expiry});

  final String number;

  /// MM/AA.
  final String expiry;

  @override
  Map<PaymentField, FieldProblem> problems(DateTime now) => {
    PaymentField.cardNumber: ?validateCardNumber(number),
    PaymentField.expiry: ?validateCardExpiry(expiry, now: now),
  };

  @override
  PaymentMethod storedAs(String id) {
    final digits = cardDigits(number);
    return PaymentMethod(
      id: id,
      kind: PaymentKind.card,
      label: cardBrandOf(digits),
      last4: digits.substring(digits.length - 4),
    );
  }
}

final class NewNequi extends NewPaymentMethod {
  const NewNequi({required this.phone});

  final String phone;

  @override
  Map<PaymentField, FieldProblem> problems(DateTime now) => {
    PaymentField.phone: ?validateMobilePhone(phone),
  };

  @override
  PaymentMethod storedAs(String id) {
    final digits = mobileDigits(phone);
    return PaymentMethod(
      id: id,
      kind: PaymentKind.nequi,
      label: 'Nequi',
      last4: digits.substring(digits.length - 4),
    );
  }
}

/// Exactly one default, listed first: [defaultId], else the current one, else the first.
List<PaymentMethod> withOneDefaultMethod(
  List<PaymentMethod> methods, {
  String? defaultId,
}) {
  if (methods.isEmpty) return const [];
  final chosen =
      defaultId ??
      methods.where((m) => m.isDefault).firstOrNull?.id ??
      methods.first.id;
  final marked = [
    for (final m in methods) m.copyWith(isDefault: m.id == chosen),
  ];
  return [
    ...marked.where((m) => m.isDefault),
    ...marked.where((m) => !m.isDefault),
  ];
}
