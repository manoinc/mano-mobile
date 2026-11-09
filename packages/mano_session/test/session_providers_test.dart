import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';

ProviderContainer _with(ManoConfig config) => ProviderContainer.test(
  overrides: [manoConfigProvider.overrideWithValue(config)],
);

void main() {
  const offline = ManoConfig(
    gatewayGraphQlUrl: 'http://gw/graphql',
    appRole: ManoRole.requester,
  );

  test(
    'without an auth domain, phone sign-in reports AuthUnavailable',
    () async {
      final c = _with(offline);

      final result = await c
          .read(passwordlessAuthProvider)
          .sendCode('+573001234567', role: ManoRole.requester);

      expect(
        (result as Err<OtpChallenge, AuthFailure>).failure,
        isA<AuthUnavailable>(),
      );
    },
  );

  test(
    'without an auth domain, social sign-in reports AuthUnavailable',
    () async {
      final c = _with(offline);

      final result = await c
          .read(socialAuthProvider)
          .signIn(SocialProvider.google, role: ManoRole.requester);

      expect(
        (result as Err<Session, AuthFailure>).failure,
        isA<AuthUnavailable>(),
      );
    },
  );

  test('without a Google client ID, Google reports AuthUnavailable', () async {
    final c = _with(
      const ManoConfig(
        gatewayGraphQlUrl: 'http://gw/graphql',
        appRole: ManoRole.requester,
        authApiDomain: 'http://auth.test',
      ),
    );

    final result = await c
        .read(socialAuthProvider)
        .signIn(SocialProvider.google, role: ManoRole.requester);

    expect(
      (result as Err<Session, AuthFailure>).failure,
      isA<AuthUnavailable>(),
    );
  });
}
