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
        offlineMarketplaceProvider.overrideWithValue(true),
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

Future<void> _answer(WidgetTester tester, String label, String value) async {
  await tester.enterText(_field(label), value);
  await tester.pump();
  await _tapText(tester, 'Continuar');
}

/// Answers every question up to the bio, leaving the bio on screen.
Future<void> _answerUpToBio(WidgetTester tester) async {
  await _tapText(tester, 'Crear cuenta profesional');
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

  testWidgets('each screen asks one question and Continuar waits for it', (
    tester,
  ) async {
    await _pump(tester);
    await _tapText(tester, 'Crear cuenta profesional');
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
    await _tapText(tester, 'Crear cuenta profesional');
    await _answer(tester, 'Nombre completo', 'Ana Gómez');

    final phone = find.descendant(
      of: _field('Celular'),
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(phone).focusNode.hasFocus, isTrue);
  });

  testWidgets('services need at least one chip', (tester) async {
    await _pump(tester);
    await _tapText(tester, 'Crear cuenta profesional');
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
    expect(find.text('Documento de identidad (frente)'), findsOneWidget);
  });

  testWidgets('documents Continuar waits for both ID sides', (tester) async {
    await _pump(tester);
    await _answerAll(tester);

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
    await _reachReview(tester);

    expect(find.text('Chapinero'), findsOneWidget);
    expect(find.text('Plomería, Electricidad'), findsOneWidget);
    await _tapText(tester, 'Enviar a revisión');

    final draft = onboarding.submitted.single;
    expect(draft.documentPaths, hasLength(2));
    expect(draft.categories, ['plumbing', 'electrical']);
    expect(draft.yearsExperience, 5);
    expect(draft.bio, 'Plomera con 5 años.');
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
