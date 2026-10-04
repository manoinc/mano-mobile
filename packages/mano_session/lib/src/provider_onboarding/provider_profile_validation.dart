/// Why a profile field cannot be accepted yet.
enum ProfileProblem { empty, tooShort, invalid }

ProfileProblem? validateDisplayName(String value) {
  final name = value.trim();
  if (name.isEmpty) return ProfileProblem.empty;
  if (name.length < 2) return ProfileProblem.tooShort;
  return null;
}

ProfileProblem? validatePhone(String value) {
  if (value.trim().isEmpty) return ProfileProblem.empty;
  return normalizePhone(value) == null ? ProfileProblem.invalid : null;
}

ProfileProblem? validateWorkZone(String value) =>
    value.trim().isEmpty ? ProfileProblem.empty : null;

/// The ten-digit Colombian mobile number, or null if [value] is not one.
String? normalizePhone(String value) {
  var digits = value.replaceAll(RegExp(r'[\s\-()]'), '');
  if (digits.startsWith('+57')) digits = digits.substring(3);
  return RegExp(r'^3\d{9}$').hasMatch(digits) ? digits : null;
}
