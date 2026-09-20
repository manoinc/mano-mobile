/// What is wrong with one field, in terms a screen can word for itself.
///
/// English, like every other identifier in this package. The Spanish the user
/// reads is chosen by the screen, the same way [AuthFailure] is worded there.
enum FieldProblem { empty, tooShort, tooLong, invalidCharacters }

const int _nameMinLength = 2;
const int _nameMaxLength = 40;
const int _addressMinLength = 5;
const int _addressMaxLength = 120;

/// Letters, marks, spaces, apostrophes, hyphens and periods -- and nothing
/// else. Unicode-aware, so José and Muñoz are ordinary names rather than edge
/// cases.
final RegExp _nameShape = RegExp(r"^[\p{L}\p{M}'\-. ]+$", unicode: true);

FieldProblem? validateGivenName(String value) => _validateName(value);

FieldProblem? validateFamilyName(String value) => _validateName(value);

FieldProblem? _validateName(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return FieldProblem.empty;
  if (trimmed.length < _nameMinLength) return FieldProblem.tooShort;
  if (trimmed.length > _nameMaxLength) return FieldProblem.tooLong;
  if (!_nameShape.hasMatch(trimmed)) return FieldProblem.invalidCharacters;
  return null;
}

/// Length only. An address carries digits, `#`, commas and abbreviations in
/// combinations no pattern should be asked to predict.
FieldProblem? validateAddress(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return FieldProblem.empty;
  if (trimmed.length < _addressMinLength) return FieldProblem.tooShort;
  if (trimmed.length > _addressMaxLength) return FieldProblem.tooLong;
  return null;
}
