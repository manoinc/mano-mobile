import '../registration/registration_validation.dart';
import 'country.dart';

final RegExp _separators = RegExp(r'[\s\-()]');
final RegExp _colombianMobile = RegExp(r'^3\d{9}$');

/// The ten digits of a Colombian mobile, without separators or +57.
String mobileDigits(String value) {
  final digits = value.replaceAll(_separators, '');
  return digits.startsWith('+57') ? digits.substring(3) : digits;
}

/// `+57 300 *** 4567`: dial code, the first three of ten digits, the last four; anything else as typed.
String maskedMobile(String value) {
  final trimmed = value.trim();
  final local = mobileDigits(trimmed);
  if (_colombianMobile.hasMatch(local)) {
    return '+57 ${local.substring(0, 3)} *** ${local.substring(6)}';
  }
  if (!trimmed.startsWith('+')) return trimmed;
  final e164 = trimmed.replaceAll(_separators, '');
  final dial = _dialCodeOf(e164);
  final rest = e164.substring(dial == null ? 1 : dial.length + 1);
  if (rest.length < 4) return trimmed;
  final last = rest.substring(rest.length - 4);
  if (dial == null) return '+*** $last';
  final first = rest.length >= 10 ? '${rest.substring(0, 3)} ' : '';
  return '+$dial $first*** $last';
}

// The longest supported dial code [e164] starts with.
String? _dialCodeOf(String e164) {
  String? found;
  for (final country in supportedCountries) {
    final dial = country.dialCode;
    if (e164.startsWith('+$dial') && dial.length > (found?.length ?? 0)) {
      found = dial;
    }
  }
  return found;
}

/// A Colombian mobile: ten digits starting with 3.
FieldProblem? validateMobilePhone(String value) {
  if (value.trim().isEmpty) return FieldProblem.empty;
  if (!_colombianMobile.hasMatch(mobileDigits(value))) {
    return FieldProblem.malformed;
  }
  return null;
}
