import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';

void main() {
  test('each failure has its Spanish copy, shared by both apps', () {
    expect(
      authFailureCopy(const WrongCredentials()),
      'Correo o contraseña incorrectos',
    );
    expect(
      authFailureCopy(const EmailAlreadyRegistered()),
      'Ese correo ya tiene cuenta. Inicia sesión.',
    );
    expect(
      authFailureCopy(const AuthUnavailable(detail: 'socket')),
      'No pudimos conectarnos. Intenta de nuevo.',
    );
    expect(
      authFailureCopy(const SignInCancelled()),
      'Cancelaste el inicio de sesión.',
    );
    expect(
      authFailureCopy(const SessionExpired()),
      'Tu sesión venció. Vuelve a iniciar sesión.',
    );
    expect(authFailureCopy(const SignInRejected()), isNotEmpty);
  });

  test('a wrong code says how many tries are left, when known', () {
    expect(
      authFailureCopy(const InvalidCode(attemptsLeft: 2)),
      'Ese código no es correcto. Te quedan 2 intentos.',
    );
    expect(authFailureCopy(const InvalidCode()), 'Ese código no es correcto.');
    expect(authFailureCopy(const CodeExpired()), isNotEmpty);
    expect(authFailureCopy(const TooManyAttempts()), isNotEmpty);
  });

  test('credential problems are worded for the field they are on', () {
    expect(credentialProblemCopy(CredentialProblem.empty), isNotEmpty);
    expect(
      credentialProblemCopy(CredentialProblem.malformedEmail),
      'Revisa tu correo.',
    );
    expect(
      credentialProblemCopy(CredentialProblem.tooShort),
      'Usa al menos 8 caracteres.',
    );
    expect(
      credentialProblemCopy(CredentialProblem.needsLetterAndNumber),
      'Usa letras y números.',
    );
  });

  test('a phone that is not a Colombian mobile says what is expected', () {
    expect(phoneNumberProblemCopy, contains('10 dígitos'));
  });
}
