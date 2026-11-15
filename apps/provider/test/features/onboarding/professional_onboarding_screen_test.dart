import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_provider/features/identity/identity_flow_view.dart';
import 'package:mano_provider/features/onboarding/professional_onboarding_screen.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/fake_capture_camera.dart';
import '../../support/fake_media.dart';
import '../../support/fake_session_repository.dart';
import '../../support/pump_app.dart';

final class _FakeOnboarding implements ProviderOnboardingRepository {
  _FakeOnboarding([this.result = const Ok(VerificationStatus.pending)]);

  Result<VerificationStatus, DataFailure> result;
  final submitted = <WorkerProfileDraft>[];

  @override
  Future<VerificationStatus> status() async => VerificationStatus.notSubmitted;

  @override
  Future<Result<VerificationStatus, DataFailure>> submit(
    WorkerProfileDraft draft,
  ) async {
    submitted.add(draft);
    return result;
  }
}

// Single-subscription, so a link sent before anyone listens waits, like a launch link.
final class _Links implements InviteLinkSource {
  final controller = StreamController<Uri>();

  @override
  Stream<Uri> get links => controller.stream;
}

final class _Redeemer implements WorkerReferralRedeemer {
  final redeemed = <ReferralCode>[];

  @override
  Future<Result<void, ReferralRedemptionFailure>> redeem(
    ReferralCode code,
  ) async {
    redeemed.add(code);
    return const Ok(null);
  }
}

Future<void> _pump(
  WidgetTester tester, {
  InviteLinkSource? links,
  WorkerReferralRedeemer? redeemer,
  ProviderOnboardingRepository? onboarding,
  SessionRepository? session,
  MediaPicker? picker,
  VoidCallback? onFinished,
  VoidCallback? onVerifyIdentity,
  PasswordlessAuth? phone,
  SocialAuth? social,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        offlineMarketplaceProvider.overrideWithValue(true),
        manoConfigProvider.overrideWithValue(testConfig),
        sessionRepositoryProvider.overrideWithValue(
          session ??
              FakeSessionRepository(onSignUp: () async => Ok(fakeSession())),
        ),
        providerOnboardingRepositoryProvider.overrideWithValue(
          onboarding ?? _FakeOnboarding(),
        ),
        if (picker != null) mediaPickerProvider.overrideWithValue(picker),
        fakeCamera(FakeCaptureCamera()),
        if (phone != null) passwordlessAuthProvider.overrideWithValue(phone),
        if (social != null) socialAuthProvider.overrideWithValue(social),
        inviteLinkSourceProvider.overrideWithValue(
          links ?? const NoInviteLinks(),
        ),
        installReferrerSourceProvider.overrideWithValue(
          const NoInstallReferrer(),
        ),
        workerReferralRedeemerProvider.overrideWithValue(
          redeemer ?? _Redeemer(),
        ),
      ],
      child: MaterialApp(
        theme: ManoTheme.light(),
        home: ProfessionalOnboardingScreen(
          onFinished: onFinished ?? () {},
          onVerifyIdentity: onVerifyIdentity ?? () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Tomar foto, the shutter, then Usar foto.
Future<void> _shoot(WidgetTester tester) async {
  await _tapText(tester, 'Tomar foto');
  await tester.tap(find.byTooltip('Capturar'));
  await tester.pumpAndSettle();
  await _tapText(tester, 'Usar foto');
}

Finder _field(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(ManoTextField)),
  matching: find.byType(TextField),
);

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

Future<void> _tapTooltip(WidgetTester tester, String tooltip) async {
  await tester.ensureVisible(find.byTooltip(tooltip));
  await tester.tap(find.byTooltip(tooltip));
  await tester.pumpAndSettle();
}

/// Email sign-up is the fallback: Registrarse, the email pill, then "Crear cuenta con correo".
Future<void> _startEmailSignUp(WidgetTester tester) async {
  await _tapText(tester, 'Registrarse');
  await _tapTooltip(tester, 'Continuar con correo');
  await _tapText(tester, 'Crear cuenta con correo');
}

Future<void> _answer(WidgetTester tester, String label, String value) async {
  await tester.enterText(_field(label), value);
  await tester.pump();
  await _tapText(tester, 'Continuar');
}

/// From the welcome through email and password; the account is created.
Future<void> _createAccount(WidgetTester tester) async {
  await _startEmailSignUp(tester);
  await _answer(tester, 'Correo', 'pro@mano.co');
  await tester.enterText(_field('Contraseña'), 'mano2026');
  await tester.pump();
  await _tapText(tester, 'Crear cuenta');
}

/// Creates the account and puts the identity check off.
Future<void> _toName(WidgetTester tester) async {
  await _createAccount(tester);
  await _tapText(tester, 'Ahora no');
}

/// Answers every question up to the bio, leaving the bio on screen.
Future<void> _answerUpToBio(WidgetTester tester) async {
  await _toName(tester);
  await _answerFromName(tester);
}

/// Sends the three identity photos and leaves the pending check.
Future<void> _sendIdentity(WidgetTester tester) async {
  await _tapText(tester, 'Continuar');
  await _shoot(tester);
  await _tapText(tester, 'Continuar');
  await _shoot(tester);
  await _shoot(tester);
  await _tapText(tester, 'Enviar');
  await _tapText(tester, 'Continuar');
}

/// From the name question up to the bio.
Future<void> _answerFromName(WidgetTester tester) async {
  await _answer(tester, 'Nombre completo', 'Ana Gómez');
  await _answer(tester, 'Celular', '300 123 4567');
  await _answer(tester, 'Zona de cobertura', 'Chapinero');
  await _tapText(tester, 'Plomería');
  await _tapText(tester, 'Electricidad');
  await _tapText(tester, 'Continuar');
  await _answer(tester, 'Años de experiencia', '5');
}

Future<void> _answerAll(WidgetTester tester) async {
  await _answerUpToBio(tester);
  await _answer(tester, 'Descripción', 'Plomera con 5 años.');
}

Future<void> _attach(WidgetTester tester, int index) async {
  final button = find.text('Adjuntar').at(index);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _reachReview(WidgetTester tester) async {
  await _answerAll(tester);
  await _tapText(tester, 'Continuar');
}

bool _primaryEnabled(WidgetTester tester) =>
    tester
        .widget<ManoPrimaryButton>(find.byType(ManoPrimaryButton))
        .onPressed !=
    null;

void main() {
  testWidgets('welcome explains Mano Profesionales with both entries', (
    tester,
  ) async {
    await _pump(tester);
    // Both doors are filled flame, side by side, Wise style.
    expect(find.byType(ManoWelcomeActions), findsOneWidget);
    expect(
      find.widgetWithText(ManoPrimaryButton, 'Iniciar sesión'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(ManoPrimaryButton, 'Registrarse'),
      findsOneWidget,
    );
    expect(find.text('Continuar con Google'), findsOneWidget);
  });

  testWidgets('Registrarse opens the same phone screen', (tester) async {
    await _pump(tester);
    await _tapText(tester, 'Registrarse');

    expect(find.text('Inicia sesión o regístrate'), findsOneWidget);
  });

  testWidgets('Google failing on the welcome opens the phone screen', (
    tester,
  ) async {
    await _pump(
      tester,
      social: InMemorySocialAuth(
        onSignIn: () => const Err(AuthUnavailable(detail: 'no client')),
      ),
    );
    await _tapText(tester, 'Continuar con Google');

    expect(find.text('Inicia sesión o regístrate'), findsOneWidget);
    expect(
      find.text('No pudimos conectarnos. Intenta de nuevo.'),
      findsOneWidget,
    );
  });

  testWidgets('Iniciar sesión surfaces the sign-in failure', (tester) async {
    await _pump(
      tester,
      session: FakeSessionRepository(
        onSignIn: () async => const Err(AuthUnavailable()),
      ),
    );
    await _tapText(tester, 'Iniciar sesión');
    await _tapTooltip(tester, 'Continuar con correo');
    await tester.enterText(
      find.byKey(const Key('mano-credentials-email')),
      'pro@mano.co',
    );
    await tester.enterText(
      find.byKey(const Key('mano-credentials-password')),
      'secret',
    );
    await tester.pump();
    await _tapText(tester, 'Entrar');

    expect(find.byType(ManoCredentialsSheet), findsOneWidget);
    expect(
      find.text('No pudimos conectarnos. Intenta de nuevo.'),
      findsOneWidget,
    );
  });

  testWidgets('good credentials close the sheet and sign in', (tester) async {
    final repository = FakeSessionRepository(
      onSignIn: () async => Ok(fakeSession()),
    );
    await _pump(tester, session: repository);
    await _tapText(tester, 'Iniciar sesión');
    await _tapTooltip(tester, 'Continuar con correo');
    await tester.enterText(
      find.byKey(const Key('mano-credentials-email')),
      'pro@mano.co',
    );
    await tester.enterText(
      find.byKey(const Key('mano-credentials-password')),
      'secret',
    );
    await tester.pump();
    await _tapText(tester, 'Entrar');

    expect(repository.lastCredentials?.email, 'pro@mano.co');
    expect(find.byType(ManoCredentialsSheet), findsNothing);
  });

  group('the account steps', () {
    testWidgets('email sign-up asks for the email first', (tester) async {
      await _pump(tester);
      await _startEmailSignUp(tester);

      expect(find.text('¿Cuál es tu correo?'), findsOneWidget);
      expect(_primaryEnabled(tester), isFalse);
      await tester.enterText(_field('Correo'), 'pro@');
      await tester.pump();
      expect(_primaryEnabled(tester), isFalse);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(find.text('Revisa tu correo.'), findsOneWidget);
    });

    testWidgets('the password creates the account as a provider', (
      tester,
    ) async {
      final session = FakeSessionRepository(
        onSignUp: () async => Ok(fakeSession()),
      );
      await _pump(tester, session: session);

      await _createAccount(tester);

      expect(session.lastCredentials?.email, 'pro@mano.co');
      expect(session.lastSignUpRole, ManoRole.provider);
      expect(find.byType(IdentityFlowView), findsOneWidget);
      expect(find.byTooltip('Atrás'), findsNothing);
    });

    testWidgets('the identity photos lead on to the name', (tester) async {
      await _pump(tester, picker: FakeMediaPicker());
      await _createAccount(tester);

      await _tapText(tester, 'Continuar');
      await _shoot(tester);
      await _tapText(tester, 'Continuar');
      await _shoot(tester);
      await _shoot(tester);
      await _tapText(tester, 'Enviar');
      expect(find.text('Estamos revisando tus documentos'), findsOneWidget);
      await _tapText(tester, 'Continuar');

      expect(find.text('¿Cuál es tu nombre?'), findsOneWidget);
    });

    testWidgets('system back inside the identity photos steps back', (
      tester,
    ) async {
      await _pump(tester, picker: FakeMediaPicker());
      await _createAccount(tester);
      await _tapText(tester, 'Continuar');

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(ManoTipList), findsOneWidget);
    });

    testWidgets('a weak password keeps Crear cuenta shut', (tester) async {
      await _pump(tester);
      await _startEmailSignUp(tester);
      await _answer(tester, 'Correo', 'pro@mano.co');

      await tester.enterText(_field('Contraseña'), 'corta');
      await tester.pump();

      expect(_primaryEnabled(tester), isFalse);
    });

    testWidgets('a taken email says so and offers to sign in', (tester) async {
      await _pump(
        tester,
        session: FakeSessionRepository(
          onSignUp: () async => const Err(EmailAlreadyRegistered()),
        ),
      );

      await _createAccount(tester);

      expect(find.text('¿Cuál es tu correo?'), findsOneWidget);
      expect(
        find.text('Ese correo ya tiene cuenta. Inicia sesión.'),
        findsOneWidget,
      );
      await _tapText(tester, 'Iniciar sesión');
      expect(find.byType(ManoCredentialsSheet), findsOneWidget);
    });

    testWidgets('an unreachable service stays on the password', (tester) async {
      await _pump(
        tester,
        session: FakeSessionRepository(
          onSignUp: () async => const Err(AuthUnavailable()),
        ),
      );

      await _createAccount(tester);

      expect(find.text('Crea una contraseña'), findsOneWidget);
      expect(
        find.text('No pudimos conectarnos. Intenta de nuevo.'),
        findsOneWidget,
      );
    });
  });

  testWidgets('Iniciar sesión says when the details are wrong', (tester) async {
    await _pump(
      tester,
      session: FakeSessionRepository(
        onSignIn: () async => const Err(WrongCredentials()),
      ),
    );
    await _tapText(tester, 'Iniciar sesión');
    await _tapTooltip(tester, 'Continuar con correo');
    await tester.enterText(
      find.byKey(const Key('mano-credentials-email')),
      'pro@mano.co',
    );
    await tester.enterText(
      find.byKey(const Key('mano-credentials-password')),
      'nope',
    );
    await tester.pump();
    await _tapText(tester, 'Entrar');

    expect(find.text('Correo o contraseña incorrectos'), findsOneWidget);
  });

  testWidgets('each screen asks one question and Continuar waits for it', (
    tester,
  ) async {
    await _pump(tester);
    await _toName(tester);
    expect(find.text('¿Cuál es tu nombre?'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(_primaryEnabled(tester), isFalse);

    await tester.enterText(_field('Nombre completo'), 'Ana Gómez');
    await tester.pump();
    expect(_primaryEnabled(tester), isTrue);
    await _tapText(tester, 'Continuar');

    expect(find.text('¿Cuál es tu celular?'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(_field('Celular'), '123');
    await tester.pump();
    expect(_primaryEnabled(tester), isFalse);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(
      find.text('Escribe un celular de 10 dígitos que empiece por 3.'),
      findsOneWidget,
    );
  });

  testWidgets('the next question takes the keyboard on its own', (
    tester,
  ) async {
    await _pump(tester);
    await _toName(tester);
    await _answer(tester, 'Nombre completo', 'Ana Gómez');

    final phone = find.descendant(
      of: _field('Celular'),
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(phone).focusNode.hasFocus, isTrue);
  });

  testWidgets('services need at least one chip', (tester) async {
    await _pump(tester);
    await _toName(tester);
    await _answer(tester, 'Nombre completo', 'Ana Gómez');
    await _answer(tester, 'Celular', '3001234567');
    await _answer(tester, 'Zona de cobertura', 'Chapinero');

    expect(find.text('¿Qué servicios ofreces?'), findsOneWidget);
    expect(_primaryEnabled(tester), isFalse);
    await _tapText(tester, 'Plomería');
    expect(_primaryEnabled(tester), isTrue);
    await _tapText(tester, 'Plomería');
    expect(_primaryEnabled(tester), isFalse);
  });

  testWidgets('the bio is optional and can be skipped', (tester) async {
    await _pump(tester);
    await _answerUpToBio(tester);

    expect(find.text('Cuéntales algo sobre ti'), findsOneWidget);
    expect(_primaryEnabled(tester), isTrue);
    await _tapText(tester, 'Omitir');
    expect(find.text('Certificados o soportes (opcional)'), findsOneWidget);
  });

  testWidgets('documents are optional certificates; no cédula rows', (
    tester,
  ) async {
    await _pump(tester);
    await _answerAll(tester);

    expect(find.text('Certificados o soportes (opcional)'), findsOneWidget);
    expect(find.textContaining('Documento de identidad'), findsNothing);
    expect(_primaryEnabled(tester), isTrue);

    await _attach(tester, 0);
    expect(find.text('Adjuntado'), findsOneWidget);
  });

  testWidgets('back returns to the previous step with the data kept', (
    tester,
  ) async {
    await _pump(tester);
    await _answerUpToBio(tester);

    await tester.tap(find.byTooltip('Atrás'));
    await tester.pumpAndSettle();
    expect(find.text('¿Cuántos años de experiencia tienes?'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('submit lands on pending and Explorar la app finishes', (
    tester,
  ) async {
    final onboarding = _FakeOnboarding();
    var finished = false;
    await _pump(
      tester,
      onboarding: onboarding,
      onFinished: () => finished = true,
    );
    await _createAccount(tester);
    await _sendIdentity(tester);
    await _answerFromName(tester);
    await _answer(tester, 'Descripción', 'Plomera con 5 años.');
    await _tapText(tester, 'Continuar');

    expect(find.text('Chapinero'), findsOneWidget);
    expect(find.text('Plomería, Electricidad'), findsOneWidget);
    await _tapText(tester, 'Enviar a revisión');

    final draft = onboarding.submitted.single;
    expect(draft.documentPaths, isEmpty);
    expect(draft.categories, ['plumbing', 'electrical']);
    expect(draft.yearsExperience, 5);
    expect(draft.bio, 'Plomera con 5 años.');
    expect(find.text('Tu cuenta está en revisión'), findsOneWidget);
    await _tapText(tester, 'Explorar la app');
    expect(finished, isTrue);
  });

  testWidgets('with the identity check put off, pending says so', (
    tester,
  ) async {
    var verify = 0;
    var finished = false;
    await _pump(
      tester,
      onVerifyIdentity: () => verify++,
      onFinished: () => finished = true,
    );
    await _reachReview(tester);
    await _tapText(tester, 'Enviar a revisión');

    expect(find.text('Tu cuenta está en revisión'), findsNothing);
    expect(find.text('Falta verificar tu identidad'), findsOneWidget);
    await _tapText(tester, 'Verificar mi identidad');
    expect(verify, 1);

    await _tapText(tester, 'Explorar la app');
    expect(finished, isTrue);
  });

  testWidgets('a failed submit shows a notice and keeps the review', (
    tester,
  ) async {
    await _pump(
      tester,
      onboarding: _FakeOnboarding(const Err(DataUnavailable())),
    );
    await _reachReview(tester);
    await _tapText(tester, 'Enviar a revisión');

    expect(find.byType(ManoNotice), findsOneWidget);
    expect(find.text(const DataUnavailable().message), findsOneWidget);
    expect(find.text('Ana Gómez'), findsOneWidget);
    expect(find.text('Tu cuenta está en revisión'), findsNothing);
  });

  group('a colleague\'s code', () {
    testWidgets('from the invite link it shows on the review and is redeemed', (
      tester,
    ) async {
      final links = _Links();
      final redeemer = _Redeemer();
      await _pump(tester, links: links, redeemer: redeemer);
      links.controller.add(Uri.parse('https://manoapp.co/r/RP-bb2cde6b'));
      await _reachReview(tester);

      expect(find.text('Te invitó un colega'), findsOneWidget);
      expect(find.text('RP-bb2cde6b'), findsOneWidget);
      await _tapText(tester, 'Enviar a revisión');

      expect(redeemer.redeemed.single.value, 'RP-bb2cde6b');
      // The identity check was put off, so the pending screen asks for it.
      expect(find.text('Verificar mi identidad'), findsOneWidget);
    });

    testWidgets('can be typed on the review', (tester) async {
      final redeemer = _Redeemer();
      await _pump(tester, redeemer: redeemer);
      await _reachReview(tester);

      await _tapText(tester, '¿Te invitó un colega? Escribe su código');
      await tester.enterText(_field('Código'), 'nope');
      await _tapText(tester, 'Guardar código');
      expect(find.text('Revisa el código, se ve así: RP-1a2b3c4d.'), findsOne);

      await tester.enterText(_field('Código'), 'rp-0123ABCD');
      await _tapText(tester, 'Guardar código');
      expect(find.text('RP-0123abcd'), findsOneWidget);

      await _tapText(tester, 'Enviar a revisión');
      expect(redeemer.redeemed.single.value, 'RP-0123abcd');
    });

    testWidgets('without one, nothing is redeemed', (tester) async {
      final redeemer = _Redeemer();
      await _pump(tester, redeemer: redeemer);
      await _reachReview(tester);
      await _tapText(tester, 'Enviar a revisión');
      expect(redeemer.redeemed, isEmpty);
    });
  });

  group('phone sign-in', () {
    Session phoneSession({required bool isNew}) => Session(
      user: fakeSession().user,
      accessToken: 'access-1',
      expiresAt: fakeSession().expiresAt,
      isNewAccount: isNew,
    );

    Future<void> sendCode(WidgetTester tester) async {
      await tester.enterText(find.byType(TextField).first, '3001234567');
      await tester.pump();
      await _tapText(tester, 'Continuar');
    }

    testWidgets('Iniciar sesión opens the phone screen', (tester) async {
      await _pump(tester);
      await _tapText(tester, 'Iniciar sesión');

      expect(find.text('Inicia sesión o regístrate'), findsOneWidget);
      expect(find.text('Colombia (+57)'), findsOneWidget);
      expect(find.text('¿Problemas para entrar?'), findsOneWidget);
      expect(find.byTooltip('Continuar con correo'), findsOneWidget);
      expect(find.byTooltip('Continuar con Google'), findsOneWidget);
    });

    testWidgets('a new account goes to the identity check, then the name', (
      tester,
    ) async {
      final phone = InMemoryPasswordlessAuth(
        onVerified: () => phoneSession(isNew: true),
      );
      await _pump(tester, phone: phone);
      await _tapText(tester, 'Iniciar sesión');
      await sendCode(tester);

      expect(find.text('Confirma tu número'), findsOneWidget);
      expect(phone.lastRole, ManoRole.provider);
      await tester.enterText(find.byType(TextField).first, '123456');
      await tester.pumpAndSettle();

      expect(find.byType(ManoTipList), findsOneWidget);
      await _tapText(tester, 'Ahora no');
      expect(find.text('Nombre completo'), findsOneWidget);
    });

    testWidgets('a wrong code says so', (tester) async {
      await _pump(
        tester,
        phone: InMemoryPasswordlessAuth(onVerified: fakeSession),
      );
      await _tapText(tester, 'Iniciar sesión');
      await sendCode(tester);

      await tester.enterText(find.byType(TextField).first, '000000');
      await tester.pumpAndSettle();

      expect(
        find.text('Ese código no es correcto. Te quedan 2 intentos.'),
        findsOneWidget,
      );
    });

    testWidgets('Google failing says it cannot connect', (tester) async {
      await _pump(
        tester,
        social: InMemorySocialAuth(
          onSignIn: () => const Err(AuthUnavailable(detail: 'no client')),
        ),
      );
      await _tapText(tester, 'Iniciar sesión');
      await _tapTooltip(tester, 'Continuar con Google');

      expect(
        find.text('No pudimos conectarnos. Intenta de nuevo.'),
        findsOneWidget,
      );
    });

    testWidgets('trouble opens the email sheet as help', (tester) async {
      await _pump(tester);
      await _tapText(tester, 'Iniciar sesión');
      await _tapText(tester, '¿Problemas para entrar?');

      expect(find.byType(ManoCredentialsSheet), findsOneWidget);
      expect(find.text('¿No te llega el código?'), findsOneWidget);
    });

    testWidgets('email sign-up stays one tap away', (tester) async {
      await _pump(tester);
      await _tapText(tester, 'Iniciar sesión');
      await _tapTooltip(tester, 'Continuar con correo');
      await _tapText(tester, 'Crear cuenta con correo');

      expect(find.text('¿Cuál es tu correo?'), findsOneWidget);
    });
  });
}
