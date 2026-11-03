import '../registration/registration_validation.dart';

final RegExp _spaces = RegExp(r'[\s\-]');
final RegExp _cardDigits = RegExp(r'^\d{13,19}$');
final RegExp _expiryShape = RegExp(r'^(\d{2})/(\d{2})$');

/// The card number without spaces or dashes.
String cardDigits(String number) => number.replaceAll(_spaces, '');

/// 13 to 19 digits passing the Luhn checksum.
FieldProblem? validateCardNumber(String number) {
  if (number.trim().isEmpty) return FieldProblem.empty;
  final digits = cardDigits(number);
  if (!_cardDigits.hasMatch(digits) || !_luhn(digits)) {
    return FieldProblem.malformed;
  }
  return null;
}

/// MM/AA, this month or later.
FieldProblem? validateCardExpiry(String expiry, {required DateTime now}) {
  if (expiry.trim().isEmpty) return FieldProblem.empty;
  final match = _expiryShape.firstMatch(expiry.trim());
  if (match == null) return FieldProblem.malformed;
  final month = int.parse(match.group(1)!);
  final year = 2000 + int.parse(match.group(2)!);
  if (month < 1 || month > 12) return FieldProblem.malformed;
  if (year < now.year || (year == now.year && month < now.month)) {
    return FieldProblem.expired;
  }
  return null;
}

/// The network a card number belongs to, as shown on a row.
String cardBrandOf(String number) {
  final digits = cardDigits(number);
  if (digits.startsWith('4')) return 'Visa';
  if (RegExp(r'^(5[1-5]|2[2-7])').hasMatch(digits)) return 'Mastercard';
  if (RegExp(r'^3[47]').hasMatch(digits)) return 'Amex';
  return 'Tarjeta';
}

bool _luhn(String digits) {
  var sum = 0;
  for (var i = 0; i < digits.length; i++) {
    var d = int.parse(digits[digits.length - 1 - i]);
    if (i.isOdd) {
      d *= 2;
      if (d > 9) d -= 9;
    }
    sum += d;
  }
  return sum % 10 == 0;
}
