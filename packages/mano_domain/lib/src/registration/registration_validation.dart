/// What is wrong with one field, in terms a screen can word for itself.
///
/// English, like every other identifier in this package. The Spanish the user
/// reads is chosen by the screen, the same way [AuthFailure] is worded there.
enum FieldProblem {
  empty,
  tooShort,
  tooLong,
  invalidCharacters,
  malformed,
  expired,
}

const int _nameMinLength = 2;
const int _nameMaxLength = 40;
const int _fullNameMaxLength = 60;
const int _addressMinLength = 5;
const int _addressMaxLength = 120;

/// Letters, marks, spaces, apostrophes, hyphens and periods -- and nothing
/// else. Unicode-aware, so José and Muñoz are ordinary names rather than edge
/// cases.
final RegExp _nameShape = RegExp(r"^[\p{L}\p{M}'\-. ]+$", unicode: true);

FieldProblem? validateGivenName(String value) => _validateName(value);

FieldProblem? validateFamilyName(String value) => _validateName(value);

/// Given and family names together, as a profile shows them.
FieldProblem? validateFullName(String value) =>
    _validateName(value, maxLength: _fullNameMaxLength);

FieldProblem? _validateName(String value, {int maxLength = _nameMaxLength}) {
  final problem = validateLength(value, min: _nameMinLength, max: maxLength);
  if (problem != null) return problem;
  final trimmed = value.trim();
  if (!_nameShape.hasMatch(trimmed)) return FieldProblem.invalidCharacters;
  return null;
}

/// Length only. An address carries digits, `#`, commas and abbreviations in
/// combinations no pattern should be asked to predict.
FieldProblem? validateAddress(String value) =>
    validateLength(value, min: _addressMinLength, max: _addressMaxLength);

/// Length only, after trimming: empty, under [min] or over [max].
FieldProblem? validateLength(String value, {int min = 1, required int max}) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return FieldProblem.empty;
  if (trimmed.length < min) return FieldProblem.tooShort;
  if (trimmed.length > max) return FieldProblem.tooLong;
  return null;
}
