import 'package:http/http.dart' as http;
import 'package:mano_domain/mano_domain.dart';

import 'supertokens_fdi.dart';

/// The platform's sign-in sheet, reduced to the id token it hands back.
abstract interface class IdTokenSource {
  /// `null` when the person closes the sheet; throws [IdTokenUnavailable] when the platform fails.
  Future<String?> idToken();
}

/// The platform could not produce a token: misconfigured, offline, unsupported.
final class IdTokenUnavailable implements Exception {
  const IdTokenUnavailable(this.detail);

  final String detail;

  @override
  String toString() => 'IdTokenUnavailable($detail)';
}

/// [SocialAuth] over SuperTokens' thirdparty recipe, native id-token flow.
final class SupertokensSocialAuth implements SocialAuth {
  SupertokensSocialAuth(this._fdi, {required this.sources});

  final SuperTokensFdi _fdi;

  /// A provider without a source has no client in this build.
  final Map<SocialProvider, IdTokenSource> sources;

  @override
  Future<Result<Session, AuthFailure>> signIn(
    SocialProvider provider, {
    required String role,
  }) async {
    final source = sources[provider];
    if (source == null) {
      return Err(AuthUnavailable(detail: '${provider.name} not configured'));
    }

    final String? idToken;
    try {
      idToken = await source.idToken();
    } on IdTokenUnavailable catch (error) {
      return Err(AuthUnavailable(detail: error.detail));
    }
    if (idToken == null) return const Err(SignInCancelled());

    final http.Response response;
    try {
      response = await _fdi.post(
        'signinup',
        rid: 'thirdparty',
        body: {
          'thirdPartyId': provider.name,
          // mano-auth keys Apple's clients by app, because each bundle ID is its own audience.
          if (provider == SocialProvider.apple) 'clientType': role,
          'oAuthTokens': {'id_token': idToken},
          'role': role,
        },
      );
    } on Object catch (error) {
      return Err(SuperTokensFdi.unreachable(error));
    }
    return switch (SuperTokensFdi.okBody(response, 'signinup')) {
      Ok(:final value) when value['status'] == 'OK' => Ok(
        await _fdi.adopt(
          response,
          isNewAccount: value['createdNewRecipeUser'] == true,
        ),
      ),
      Ok(:final value) => Err(
        SignInRejected(reason: '${value['status']}: ${value['reason'] ?? ''}'),
      ),
      Err(:final failure) => Err(failure),
    };
  }
}
