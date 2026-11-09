/// The ten-digit Colombian mobile number in [value], or null if it is not one.
String? normalizeColombianMobile(String value) {
  var digits = value.replaceAll(RegExp(r'[\s\-()]'), '');
  if (digits.startsWith('+57')) digits = digits.substring(3);
  return RegExp(r'^3\d{9}$').hasMatch(digits) ? digits : null;
}

/// [value] as `+57` and ten digits, or null if it is not a Colombian mobile.
String? colombianE164(String value) {
  final digits = normalizeColombianMobile(value);
  return digits == null ? null : '+57$digits';
}
