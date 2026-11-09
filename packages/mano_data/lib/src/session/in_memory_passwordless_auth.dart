import 'package:mano_domain/mano_domain.dart';

/// A phone sign-in for tests and offline builds; the code is always [code].
final class InMemoryPasswordlessAuth implements PasswordlessAuth {
  InMemoryPasswordlessAuth({
    required this.onVerified,
    this.code = '123456',
    this.maxAttempts = 3,
  });

  final Session Function() onVerified;
  final String code;
  final int maxAttempts;

  String? lastRole;
  int sends = 0;
  int _wrong = 0;

  @override
  Future<Result<OtpChallenge, AuthFailure>> sendCode(
    String phone, {
    required String role,
  }) async {
    lastRole = role;
    sends++;
    _wrong = 0;
    return Ok(
      OtpChallenge(
        deviceId: 'dev-$sends',
        preAuthSessionId: 'pre',
        phone: phone,
      ),
    );
  }

  @override
  Future<Result<OtpChallenge, AuthFailure>> resend(
    OtpChallenge challenge,
  ) async {
    sends++;
    return Ok(challenge);
  }

  @override
  Future<Result<Session, AuthFailure>> verify(
    OtpChallenge challenge,
    String code,
  ) async {
    if (_wrong >= maxAttempts) return const Err(TooManyAttempts());
    if (code.trim() == this.code) return Ok(onVerified());
    _wrong++;
    return Err(InvalidCode(attemptsLeft: maxAttempts - _wrong));
  }
}

/// A scriptable [SocialAuth]; cancels unless told otherwise.
final class InMemorySocialAuth implements SocialAuth {
  InMemorySocialAuth({this.onSignIn});

  final Result<Session, AuthFailure> Function()? onSignIn;

  SocialProvider? lastProvider;
  String? lastRole;

  @override
  Future<Result<Session, AuthFailure>> signIn(
    SocialProvider provider, {
    required String role,
  }) async {
    lastProvider = provider;
    lastRole = role;
    return onSignIn?.call() ?? const Err(SignInCancelled());
  }
}
