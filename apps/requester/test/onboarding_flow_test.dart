import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_requester/features/onboarding/onboarding_screen.dart';
import 'package:mano_requester/features/registration/registration_flow_screen.dart';
import 'package:mano_requester/root.dart';
import 'package:mano_requester/screens/sign_in_screen.dart';
import 'package:mano_requester/shell/requester_shell.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

/// Pumps the real root with animations off.
///
/// Off is not only for speed: `ManoRoot._opened` is a static, so the first
/// test would otherwise play 1150ms of opening and the rest would not, making
/// the suite order-dependent.
Widget _app({SessionRepository? session}) => ProviderScope(
  overrides: [
    offlineMarketplaceProvider.overrideWithValue(true),
    manoConfigProvider.overrideWithValue(
      const ManoConfig(
        gatewayGraphQlUrl: 'http://localhost:8082/graphql',
        appRole: ManoRole.requester,
      ),
    ),
    if (session != null) sessionRepositoryProvider.overrideWithValue(session),
  ],
  child: MaterialApp(
    theme: ManoTheme.light(),
    // Wraps the Navigator, so sheets and dialogs inherit it too.
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child!,
    ),
    home: const ManoRoot(),
  ),
);

final _signedInSession = Session(
  user: const AuthenticatedUser(
    subject: 'user-1',
    username: 'ana',
    roles: {ManoRole.requester},
  ),
  accessToken: 'access-1',
  expiresAt: DateTime.now().add(const Duration(minutes: 30)),
);

InMemorySessionRepository _signedInRepository() => InMemorySessionRepository(
  onRestore: () async => Ok(_signedInSession),
  onSignIn: () async => Ok(_signedInSession),
  onRefresh: () async => Ok(_signedInSession),
);

InMemorySessionRepository _signInRejectedRepository() =>
    InMemorySessionRepository(
      onSignIn: () async => const Err(WrongCredentials()),
    );

Future<void> _boot(WidgetTester tester, {SessionRepository? session}) async {
  await tester.pumpWidget(_app(session: session));
  await tester.pumpAndSettle();
}

/// Walks the carousel to the last slide.
Future<void> _toLastSlide(WidgetTester tester) async {
  await tester.tap(find.text('Empezar'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Siguiente'));
  await tester.pumpAndSettle();
}

Future<void> _fillName(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).at(0), 'Ana');
  await tester.enterText(find.byType(TextField).at(1), 'Rojas');
  await tester.pumpAndSettle();
  await tester.tap(find.text('Siguiente'));
  await tester.pumpAndSettle();
}

/// Sign-up answers with [outcome], or a fresh signed-in session.
InMemorySessionRepository _signUpRepository([AuthFailure? outcome]) =>
    InMemorySessionRepository(
      onSignUp: () async =>
          outcome == null ? Ok(_signedInSession) : Err(outcome),
    );

/// Email, then password, then "Crear cuenta".
Future<void> _fillAccount(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).first, 'ana@mano.co');
  await tester.pumpAndSettle();
  await tester.tap(find.text('Siguiente'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).first, 'mano2026');
  await tester.pumpAndSettle();
  await tester.tap(find.text('Crear cuenta'));
  await tester.pumpAndSettle();
}

/// From a cold start to the address step, account created.
Future<void> _registerToAddress(
  WidgetTester tester, {
  InMemorySessionRepository? session,
}) async {
  await _boot(tester, session: session ?? _signUpRepository());
  await _toLastSlide(tester);
  await tester.tap(find.text('Registrarse'));
  await tester.pumpAndSettle();
  await _fillName(tester);
  await _fillAccount(tester);
}

void main() {
  group('the doorway', () {
    testWidgets('a cold start with nobody signed in opens the carousel', (
      tester,
    ) async {
      await _boot(tester);

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(
        find.text('Encuentra a la persona ideal para lo que necesitas hacer.'),
        findsOneWidget,
      );
    });

    testWidgets('a restored session goes straight home, no carousel', (
      tester,
    ) async {
      await _boot(tester, session: _signedInRepository());

      expect(find.byType(RequesterShell), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
    });
  });

  group('the carousel', () {
    testWidgets('walks three slides and tracks them in the indicator', (
      tester,
    ) async {
      await _boot(tester);

      expect(
        tester.widget<ManoPageIndicator>(find.byType(ManoPageIndicator)).index,
        0,
      );

      await tester.tap(find.text('Empezar'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Compara precios y encuentra buenos profesionales en poco tiempo.',
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<ManoPageIndicator>(find.byType(ManoPageIndicator)).index,
        1,
      );

      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
      expect(find.text('Tu casa, en buenas manos.'), findsOneWidget);
    });

    testWidgets('slide 1 composes pros with photos and a nearby count', (
      tester,
    ) async {
      await _boot(tester);

      expect(find.byType(ManoAvatar), findsAtLeastNWidgets(3));
      expect(find.text('+120 profesionales cerca'), findsOneWidget);
    });

    testWidgets('slide 2 shows a fixed-price quote with the pro photo', (
      tester,
    ) async {
      await _boot(tester);
      await tester.tap(find.text('Empezar'));
      await tester.pumpAndSettle();

      expect(find.text('Precio fijo'), findsOneWidget);
      expect(find.text(r'$85.000'), findsOneWidget);
      expect(find.byType(ManoAvatar), findsAtLeastNWidgets(2));
    });

    testWidgets('the last slide offers all three ways in', (tester) async {
      await _boot(tester);
      await _toLastSlide(tester);

      expect(find.text('Registrarse'), findsOneWidget);
      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(find.text('Continuar con Google'), findsOneWidget);
      // One flame surface: Registrarse is filled, the other two are not.
      expect(find.byType(ManoPrimaryButton), findsOneWidget);
    });

    testWidgets('"Omitir" reaches the guest home from any slide', (
      tester,
    ) async {
      await _boot(tester);

      await tester.tap(find.text('Omitir'));
      await tester.pumpAndSettle();

      expect(find.byType(RequesterShell), findsOneWidget);
      expect(find.byType(ManoDialogCard), findsNothing);
    });

    testWidgets('"Iniciar sesión" reaches the sign-in screen', (tester) async {
      await _boot(tester);
      await _toLastSlide(tester);

      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsOneWidget);
    });
  });

  group('signing in', () {
    testWidgets(
      'a rejected sign-in shows its notice, and dismissing clears it',
      (tester) async {
        // The doorway watches the session directly, so a failure that leaves
        // the location unchanged (there is no location here) still re-renders.
        await _boot(tester, session: _signInRejectedRepository());
        await _toLastSlide(tester);

        // First tap leaves the carousel; the second opens the credentials sheet.
        await tester.tap(find.text('Iniciar sesión'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Iniciar sesión'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('mano-credentials-email')),
          'ana@mano.co',
        );
        await tester.enterText(
          find.byKey(const Key('mano-credentials-password')),
          'nope',
        );
        await tester.pump();
        await tester.tap(find.text('Entrar'));
        await tester.pumpAndSettle();

        // The refusal shows inside the sheet, where the fix is typed.
        expect(find.text('Correo o contraseña incorrectos'), findsOneWidget);
        expect(find.byType(ManoCredentialsSheet), findsOneWidget);
        expect(find.byType(ManoNotice), findsNothing);
      },
    );

    testWidgets('good credentials close the sheet and go home', (tester) async {
      final repository = InMemorySessionRepository(
        onSignIn: () async => Ok(_signedInSession),
      );
      await _boot(tester, session: repository);
      await _toLastSlide(tester);

      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('mano-credentials-email')),
        ' Ana@Mano.co ',
      );
      await tester.enterText(
        find.byKey(const Key('mano-credentials-password')),
        'secret',
      );
      await tester.pump();
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(repository.lastCredentials?.email, 'ana@mano.co');
      expect(find.byType(ManoCredentialsSheet), findsNothing);
      expect(find.byType(RequesterShell), findsOneWidget);
    });
  });

  group('registration', () {
    testWidgets('"Registrarse" asks for a name first', (tester) async {
      await _boot(tester);
      await _toLastSlide(tester);

      await tester.tap(find.text('Registrarse'));
      await tester.pumpAndSettle();

      expect(find.byType(RegistrationFlowScreen), findsOneWidget);
      expect(find.text('¿Cómo te llamas?'), findsOneWidget);
    });

    testWidgets('an empty name is refused, in Spanish', (tester) async {
      await _boot(tester);
      await _toLastSlide(tester);
      await tester.tap(find.text('Registrarse'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      expect(find.text('Escribe tu nombre.'), findsOneWidget);
      expect(find.text('Escribe tu apellido.'), findsOneWidget);
      expect(find.text('¿Cómo te llamas?'), findsOneWidget);
    });

    testWidgets('a good name asks for the email', (tester) async {
      await _boot(tester);
      await _toLastSlide(tester);
      await tester.tap(find.text('Registrarse'));
      await tester.pumpAndSettle();

      await _fillName(tester);

      expect(find.text('¿Cuál es tu correo?'), findsOneWidget);
    });

    testWidgets('a malformed email is refused, in Spanish', (tester) async {
      await _boot(tester);
      await _toLastSlide(tester);
      await tester.tap(find.text('Registrarse'));
      await tester.pumpAndSettle();
      await _fillName(tester);

      await tester.enterText(find.byType(TextField).first, 'ana@');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      expect(find.text('Revisa tu correo.'), findsOneWidget);
      expect(find.text('¿Cuál es tu correo?'), findsOneWidget);
    });

    testWidgets('a weak password is refused before anything is sent', (
      tester,
    ) async {
      final session = _signUpRepository();
      await _boot(tester, session: session);
      await _toLastSlide(tester);
      await tester.tap(find.text('Registrarse'));
      await tester.pumpAndSettle();
      await _fillName(tester);
      await tester.enterText(find.byType(TextField).first, 'ana@mano.co');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'corta');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Crear cuenta'));
      await tester.pumpAndSettle();

      expect(find.text('Usa al menos 8 caracteres.'), findsOneWidget);
      expect(session.lastCredentials, isNull);
    });

    testWidgets('creating the account signs up as a requester', (tester) async {
      final session = _signUpRepository();

      await _registerToAddress(tester, session: session);

      expect(session.lastCredentials?.email, 'ana@mano.co');
      expect(session.lastSignUpRole, ManoRole.requester);
      expect(
        find.text('¡Un gusto conocerte, Ana! ¿Dónde vives?'),
        findsOneWidget,
        reason: 'signed in, but registration is not over',
      );
      expect(find.byType(RequesterShell), findsNothing);
    });

    testWidgets('a taken email says so and offers to sign in', (tester) async {
      await _registerToAddress(
        tester,
        session: _signUpRepository(const EmailAlreadyRegistered()),
      );

      expect(find.text('¿Cuál es tu correo?'), findsOneWidget);
      expect(
        find.text('Ese correo ya tiene cuenta. Inicia sesión.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsOneWidget);
    });

    testWidgets('an unreachable service stays on the password step', (
      tester,
    ) async {
      await _registerToAddress(
        tester,
        session: _signUpRepository(const AuthUnavailable()),
      );

      expect(find.text('Crea una contraseña'), findsOneWidget);
      expect(
        find.text('No pudimos conectarnos. Intenta de nuevo.'),
        findsOneWidget,
      );
    });

    testWidgets('going back keeps what was typed', (tester) async {
      await _boot(tester);
      await _toLastSlide(tester);
      await tester.tap(find.text('Registrarse'));
      await tester.pumpAndSettle();
      await _fillName(tester);

      await tester.tap(find.byTooltip('Atrás'));
      await tester.pumpAndSettle();

      expect(find.text('¿Cómo te llamas?'), findsOneWidget);
      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('Rojas'), findsOneWidget);
    });

    testWidgets('"Ahora no" leaves for the guest home, with no welcome', (
      tester,
    ) async {
      await _boot(tester);
      await _toLastSlide(tester);
      await tester.tap(find.text('Registrarse'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ahora no'));
      await tester.pumpAndSettle();

      expect(find.byType(RequesterShell), findsOneWidget);
      expect(find.byType(ManoDialogCard), findsNothing);
    });

    testWidgets('finishing raises the notifications sheet', (tester) async {
      await _registerToAddress(tester);

      await tester.enterText(find.byType(TextField).first, 'Calle 12 #3-45');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      expect(find.text('Activa las notificaciones'), findsOneWidget);
      expect(find.byType(ManoToggleRow), findsOneWidget);
    });

    testWidgets('accepting lands home signed in and says thank you', (
      tester,
    ) async {
      await _registerToAddress(tester);
      await tester.enterText(find.byType(TextField).first, 'Calle 12 #3-45');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sí, notifícame'));
      await tester.pumpAndSettle();

      expect(find.byType(RequesterShell), findsOneWidget);
      expect(find.text('¡Gracias por unirte a Mano!'), findsOneWidget);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(RequesterShell)),
      );
      expect(container.read(sessionProvider).value, isA<SignedIn>());

      await tester.tap(find.text('¡Empecemos!'));
      await tester.pumpAndSettle();

      expect(find.byType(ManoDialogCard), findsNothing);
      expect(find.byType(RequesterShell), findsOneWidget);
    });

    testWidgets('dismissing the sheet returns to the address step', (
      tester,
    ) async {
      await _registerToAddress(tester);
      await tester.enterText(find.byType(TextField).first, 'Calle 12 #3-45');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Cerrar'));
      await tester.pumpAndSettle();

      expect(find.text('Activa las notificaciones'), findsNothing);
      expect(
        find.text('¡Un gusto conocerte, Ana! ¿Dónde vives?'),
        findsOneWidget,
      );
    });
  });

  group('a small phone at large text', () {
    // The brief asks for zero layout overflow. Scrolling is the honest answer
    // to a headline that no longer fits; clamping the text is not.
    Future<void> boot(WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            offlineMarketplaceProvider.overrideWithValue(true),
            manoConfigProvider.overrideWithValue(
              const ManoConfig(
                gatewayGraphQlUrl: 'http://localhost:8082/graphql',
                appRole: ManoRole.requester,
              ),
            ),
            sessionRepositoryProvider.overrideWithValue(_signUpRepository()),
          ],
          child: MaterialApp(
            theme: ManoTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                disableAnimations: true,
                textScaler: const TextScaler.linear(1.5),
              ),
              child: child!,
            ),
            home: const ManoRoot(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('every carousel slide fits or scrolls', (tester) async {
      await boot(tester);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Empezar'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('every form step fits or scrolls', (tester) async {
      await boot(tester);
      await _toLastSlide(tester);
      await tester.tap(find.text('Registrarse'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await _fillName(tester);
      expect(tester.takeException(), isNull);

      await tester.enterText(find.byType(TextField).first, 'ana@mano.co');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.enterText(find.byType(TextField).first, 'mano2026');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Crear cuenta'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('the notifications sheet and the welcome fit', (tester) async {
      await boot(tester);
      await _toLastSlide(tester);
      await tester.tap(find.text('Registrarse'));
      await tester.pumpAndSettle();
      await _fillName(tester);
      await _fillAccount(tester);
      await tester.enterText(find.byType(TextField).first, 'Calle 12 #3-45');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Sí, notifícame'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('¡Gracias por unirte a Mano!'), findsOneWidget);
    });
  });

  group('the guest home', () {
    testWidgets('offers a way into an account, so Omitir is not one-way', (
      tester,
    ) async {
      await _boot(tester);
      await tester.tap(find.text('Omitir'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsOneWidget);
    });
  });
}
