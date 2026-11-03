import '../registration/registration_validation.dart';

final RegExp _separators = RegExp(r'[\s\-()]');
final RegExp _colombianMobile = RegExp(r'^3\d{9}$');

/// The ten digits of a Colombian mobile, without separators or +57.
String mobileDigits(String value) {
  final digits = value.replaceAll(_separators, '');
  return digits.startsWith('+57') ? digits.substring(3) : digits;
}

/// A Colombian mobile: ten digits starting with 3.
FieldProblem? validateMobilePhone(String value) {
  if (value.trim().isEmpty) return FieldProblem.empty;
  if (!_colombianMobile.hasMatch(mobileDigits(value))) {
    return FieldProblem.malformed;
  }
  return null;
}
