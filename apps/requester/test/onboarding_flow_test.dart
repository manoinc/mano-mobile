import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_requester/features/home/guest_home_screen.dart';
import 'package:mano_requester/features/onboarding/onboarding_screen.dart';
import 'package:mano_requester/features/registration/registration_flow_screen.dart';
import 'package:mano_requester/root.dart';
import 'package:mano_requester/screens/home_screen.dart';
import 'package:mano_requester/screens/sign_in_screen.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

/// Pumps the real root with animations off.
///
/// Off is not only for speed: `ManoRoot._opened` is a static, so the first
/// test would otherwise play 1150ms of opening and the rest would not, making
/// the suite order-dependent.
Widget _app({SessionRepository? session}) => ProviderScope(
  overrides: [
    manoConfigProvider.overrideWithValue(
      const ManoConfig(gatewayGraphQlUrl: 'http://localhost:8082/graphql'),
    ),
    if (session != null)
      sessionRepositoryProvider.overrideWithValue(session),
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

final class _SignedInRepository implements SessionRepository {
  const _SignedInRepository();

  static final _session = Session(
    user: const AuthenticatedUser(
      subject: 'user-1',
      username: 'ana',
      roles: {ManoRole.requester},
    ),
    accessToken: 'access-1',
    expiresAt: DateTime.now().add(const Duration(minutes: 30)),
  );

  @override
  Future<Result<Session?, AuthFailure>> restore() async => Ok(_session);

  @override
  Future<Result<Session, AuthFailure>> signIn() async => Ok(_session);

  @override
  Future<Result<Session, AuthFailure>> refresh() async => Ok(_session);

  @override
  Future<void> signOut() async {}
}

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
      await _boot(tester, session: const _SignedInRepository());

      expect(find.byType(HomeScreen), findsOneWidget);
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

      expect(find.byType(GuestHomeScreen), findsOneWidget);
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

    testWidgets('a good name advances and the next step greets by it', (
      tester,
    ) async {
      await _boot(tester);
      await _toLastSlide(tester);
      await tester.tap(find.text('Registrarse'));
      await tester.pumpAndSettle();

      await _fillName(tester);

      expect(
        find.text('¡Un gusto conocerte, Ana! ¿Dónde vives?'),
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

      expect(find.byType(GuestHomeScreen), findsOneWidget);
      expect(find.byType(ManoDialogCard), findsNothing);
    });

    testWidgets('finishing raises the notifications sheet', (tester) async {
      await _boot(tester);
      await _toLastSlide(tester);
      await tester.tap(find.text('Registrarse'));
      await tester.pumpAndSettle();
      await _fillName(tester);

      await tester.enterText(find.byType(TextField).first, 'Calle 12 #3-45');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      expect(find.text('Activa las notificaciones'), findsOneWidget);
      expect(find.byType(ManoToggleRow), findsOneWidget);
    });

    testWidgets('accepting lands on the guest home and says thank you', (
      tester,
    ) async {
      await _boot(tester);
      await _toLastSlide(tester);
      await tester.tap(find.text('Registrarse'));
      await tester.pumpAndSettle();
      await _fillName(tester);
      await tester.enterText(find.byType(TextField).first, 'Calle 12 #3-45');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sí, notifícame'));
      await tester.pumpAndSettle();

      expect(find.byType(GuestHomeScreen), findsOneWidget);
      expect(find.text('¡Gracias por unirte a Mano!'), findsOneWidget);

      await tester.tap(find.text('¡Empecemos!'));
      await tester.pumpAndSettle();

      expect(find.byType(ManoDialogCard), findsNothing);
      expect(find.byType(GuestHomeScreen), findsOneWidget);
    });

    testWidgets('dismissing the sheet returns to the address step', (
      tester,
    ) async {
      await _boot(tester);
      await _toLastSlide(tester);
      await tester.tap(find.text('Registrarse'));
      await tester.pumpAndSettle();
      await _fillName(tester);
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
            manoConfigProvider.overrideWithValue(
              const ManoConfig(
                gatewayGraphQlUrl: 'http://localhost:8082/graphql',
              ),
            ),
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

    testWidgets('both form steps fit or scroll', (tester) async {
      await boot(tester);
      await _toLastSlide(tester);
      await tester.tap(find.text('Registrarse'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await _fillName(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the notifications sheet and the welcome fit', (tester) async {
      await boot(tester);
      await _toLastSlide(tester);
      await tester.tap(find.text('Registrarse'));
      await tester.pumpAndSettle();
      await _fillName(tester);
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
