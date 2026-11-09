import '../result.dart';
import 'auth_failure.dart';
import 'otp_challenge.dart';
import 'session.dart';

/// Sign in or up with a code texted to a phone; new accounts get [role].
abstract interface class PasswordlessAuth {
  /// [phone] in E.164; see `colombianE164`.
  Future<Result<OtpChallenge, AuthFailure>> sendCode(
    String phone, {
    required String role,
  });

  Future<Result<OtpChallenge, AuthFailure>> resend(OtpChallenge challenge);

  /// A wrong code is [InvalidCode]; an old one is [CodeExpired].
  Future<Result<Session, AuthFailure>> verify(
    OtpChallenge challenge,
    String code,
  );
}
