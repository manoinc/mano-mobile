import 'package:mano_domain/mano_domain.dart';

/// What a person reads for each [AuthFailure]: one wording for both apps.
///
/// `AuthFailure.message` stays English for logs; the Spanish lives here,
/// exhaustive, so a new failure fails to compile instead of reaching a user.
String authFailureCopy(AuthFailure failure) => switch (failure) {
  WrongCredentials() => 'Correo o contraseña incorrectos',
  EmailAlreadyRegistered() => 'Ese correo ya tiene cuenta. Inicia sesión.',
  AuthUnavailable() => 'No pudimos conectarnos. Intenta de nuevo.',
  SignInCancelled() => 'Cancelaste el inicio de sesión.',
  SessionExpired() => 'Tu sesión venció. Vuelve a iniciar sesión.',
  SignInRejected() => 'No pudimos aceptar esos datos. Revísalos.',
  InvalidCode(:final attemptsLeft) =>
    attemptsLeft == null
        ? 'Ese código no es correcto.'
        : 'Ese código no es correcto. Te quedan $attemptsLeft intentos.',
  CodeExpired() => 'Ese código venció. Pide uno nuevo.',
  TooManyAttempts() => 'Demasiados intentos. Espera un momento.',
};

/// The inline error under an email or password field.
String credentialProblemCopy(CredentialProblem problem) => switch (problem) {
  CredentialProblem.empty => 'Completa este campo.',
  CredentialProblem.malformedEmail => 'Revisa tu correo.',
  CredentialProblem.tooShort => 'Usa al menos 8 caracteres.',
  CredentialProblem.needsLetterAndNumber => 'Usa letras y números.',
};

/// The inline error under a phone number that `phoneE164` refuses in [country].
String phoneNumberProblemCopy(Country country) => country == Country.colombia
    ? 'Escribe un celular colombiano: 10 dígitos que empiezan por 3.'
    : 'Revisa el número: entre 6 y 12 dígitos, sin el +${country.dialCode}.';
