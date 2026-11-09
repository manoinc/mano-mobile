import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'supertokens_social_auth.dart';

/// Google's native sheet, asking for an id token issued to mano-auth's server client.
final class GoogleIdTokenSource implements IdTokenSource {
  GoogleIdTokenSource({required this.serverClientId});

  final String serverClientId;

  Future<void>? _initialized;

  @override
  Future<String?> idToken() async {
    final google = GoogleSignIn.instance;
    try {
      await (_initialized ??= google.initialize(
        serverClientId: serverClientId,
      ));
      if (!google.supportsAuthenticate()) {
        throw const IdTokenUnavailable('Google sign-in is not supported here');
      }
      final account = await google.authenticate();
      return account.authentication.idToken ??
          (throw const IdTokenUnavailable('Google returned no id token'));
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      throw IdTokenUnavailable('google ${error.code}: ${error.description}');
    }
  }
}

/// Apple's native sheet; only offered on iOS.
final class AppleIdTokenSource implements IdTokenSource {
  const AppleIdTokenSource();

  @override
  Future<String?> idToken() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [AppleIDAuthorizationScopes.fullName],
      );
      return credential.identityToken ??
          (throw const IdTokenUnavailable('Apple returned no id token'));
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) return null;
      throw IdTokenUnavailable('apple ${error.code}: ${error.message}');
    } on SignInWithAppleException catch (error) {
      throw IdTokenUnavailable('apple: $error');
    }
  }
}
