/// What is wrong with an email or password, for the screen to word.
enum CredentialProblem { empty, malformedEmail, tooShort, needsLetterAndNumber }

// The same rules as SuperTokens' default email-password validators.
const int _passwordMinLength = 8;
final RegExp _emailShape = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
final RegExp _letter = RegExp('[A-Za-z]');
final RegExp _digit = RegExp('[0-9]');

CredentialProblem? validateEmail(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return CredentialProblem.empty;
  if (!_emailShape.hasMatch(trimmed)) return CredentialProblem.malformedEmail;
  return null;
}

CredentialProblem? validatePassword(String value) {
  if (value.isEmpty) return CredentialProblem.empty;
  if (value.length < _passwordMinLength) return CredentialProblem.tooShort;
  if (!_letter.hasMatch(value) || !_digit.hasMatch(value)) {
    return CredentialProblem.needsLetterAndNumber;
  }
  return null;
}
