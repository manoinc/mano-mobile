import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_provider/features/onboarding/professional_onboarding_screen.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

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

Future<void> _pump(
  WidgetTester tester, {
  ProviderOnboardingRepository? onboarding,
  SessionRepository? session,
  VoidCallback? onFinished,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        manoConfigProvider.overrideWithValue(testConfig),
        sessionRepositoryProvider.overrideWithValue(
          session ?? FakeSessionRepository(),
        ),
        providerOnboardingRepositoryProvider.overrideWithValue(
          onboarding ?? _FakeOnboarding(),
        ),
      ],
      child: MaterialApp(
        theme: ManoTheme.light(),
        home: ProfessionalOnboardingScreen(onFinished: onFinished ?? () {}),
      ),
    ),
  );
  await tester.pumpAndSettle();
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

Future<void> _fillProfile(WidgetTester tester) async {
  await tester.enterText(_field('Nombre para mostrar'), 'Ana Gómez');
  await tester.enterText(_field('Celular'), '300 123 4567');
  await tester.enterText(_field('Zona de cobertura'), 'Chapinero');
  await tester.pump();
}

Future<void> _attach(WidgetTester tester, int index) async {
  final button = find.text('Adjuntar').at(index);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _reachReview(WidgetTester tester) async {
  await _tapText(tester, 'Crear cuenta profesional');
  await _fillProfile(tester);
  await _tapText(tester, 'Continuar');
  await _attach(tester, 0);
  // The first row is now attached, so the remaining first is the back side.
  await _attach(tester, 0);
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
    expect(find.text('Crear cuenta profesional'), findsOneWidget);
    expect(find.text('Ya tengo cuenta'), findsOneWidget);
  });

  testWidgets('Ya tengo cuenta surfaces the sign-in failure', (tester) async {
    await _pump(
      tester,
      session: FakeSessionRepository(
        onSignIn: () async => const Err(AuthUnavailable()),
      ),
    );
    await _tapText(tester, 'Ya tengo cuenta');
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
      find.textContaining('No pudimos conectar con el servicio'),
      findsOneWidget,
    );
  });

  testWidgets('good credentials close the sheet and sign in', (tester) async {
    final repository = FakeSessionRepository(
      onSignIn: () async => Ok(fakeSession()),
    );
    await _pump(tester, session: repository);
    await _tapText(tester, 'Ya tengo cuenta');
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

  testWidgets('profile shows inline problems on a refused Continuar', (
    tester,
  ) async {
    await _pump(tester);
    await _tapText(tester, 'Crear cuenta profesional');
    expect(find.text('Tu perfil'), findsOneWidget);

    await _tapText(tester, 'Continuar');
    expect(find.text('Escribe tu nombre.'), findsOneWidget);
    expect(find.text('Escribe tu celular.'), findsOneWidget);
    expect(find.text('Escribe tu zona de cobertura.'), findsOneWidget);

    await tester.enterText(_field('Celular'), '123');
    await tester.pump();
    expect(
      find.text('Escribe un celular de 10 dígitos que empiece por 3.'),
      findsOneWidget,
    );
  });

  testWidgets('documents Continuar waits for both ID sides', (tester) async {
    await _pump(tester);
    await _tapText(tester, 'Crear cuenta profesional');
    await _fillProfile(tester);
    await _tapText(tester, 'Continuar');

    expect(find.text('Documento de identidad (frente)'), findsOneWidget);
    expect(find.text('Documento de identidad (reverso)'), findsOneWidget);
    expect(find.text('Certificados o soportes (opcional)'), findsOneWidget);
    expect(_primaryEnabled(tester), isFalse);

    await _attach(tester, 0);
    expect(_primaryEnabled(tester), isFalse);
    expect(find.text('Adjuntado'), findsOneWidget);
    await _attach(tester, 0);
    expect(_primaryEnabled(tester), isTrue);
  });

  testWidgets('back returns to the previous step with the data kept', (
    tester,
  ) async {
    await _pump(tester);
    await _tapText(tester, 'Crear cuenta profesional');
    await _fillProfile(tester);
    await _tapText(tester, 'Continuar');

    await tester.tap(find.byTooltip('Atrás'));
    await tester.pumpAndSettle();
    expect(find.text('Tu perfil'), findsOneWidget);
    expect(find.text('Ana Gómez'), findsOneWidget);
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
    await _reachReview(tester);

    expect(find.text('Chapinero'), findsOneWidget);
    await _tapText(tester, 'Enviar a revisión');

    expect(onboarding.submitted.single.documentPaths, hasLength(2));
    expect(find.text('Tu cuenta está en revisión'), findsOneWidget);
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
}
