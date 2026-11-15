import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_provider/features/identity/identity_flow_view.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/fake_identity.dart';

Future<FakeIdentityVerification> _pump(
  WidgetTester tester, {
  FakeIdentityVerification? port,
  VoidCallback? onDone,
  VoidCallback? onLater,
}) async {
  final identity = port ?? FakeIdentityVerification();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [identityVerificationProvider.overrideWithValue(identity)],
      child: MaterialApp(
        theme: ManoTheme.light(),
        home: IdentityFlowView(onDone: onDone ?? () {}, onLater: onLater),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return identity;
}

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

/// From the intro to the selfie brief.
Future<void> _toSelfie(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await _tap(tester, 'Continuar');
  }
}

const _front = 'Toma la foto del frente de tu cédula';
const _back =
    'Voltea tu identificación para tomar una foto de la parte de atrás';
const _selfie = '¿Tomamos tu selfie?';

Finder _art(String name) => find.image(AssetImage('assets/identity/$name.jpg'));

void main() {
  testWidgets('the intro says why, with tips, and highlights the point', (
    tester,
  ) async {
    await _pump(tester);
    expect(
      find.text('Vamos a tomar fotos de tu cédula para confirmar tu identidad'),
      findsOneWidget,
    );
    expect(find.byType(ManoTipList), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);
  });

  testWidgets('Ahora no appears only when the host allows it', (tester) async {
    var later = 0;
    await _pump(tester, onLater: () => later++);
    await _tap(tester, 'Ahora no');
    expect(later, 1);
  });

  testWidgets('walks Nu\'s briefs: front, back, selfie', (tester) async {
    final port = await _pump(tester);
    await _tap(tester, 'Continuar');

    expect(find.text(_front), findsOneWidget);
    expect(_art('cedula'), findsOneWidget);
    await _tap(tester, 'Continuar');

    expect(find.text(_back), findsOneWidget);
    expect(_art('cedula_back'), findsOneWidget);
    await _tap(tester, 'Continuar');

    expect(find.text(_selfie), findsOneWidget);
    expect(_art('selfie'), findsOneWidget);
    expect(find.text('Empezar'), findsOneWidget);
    expect(port.verifies, 0, reason: 'nothing reaches Didit until Empezar');
  });

  testWidgets('the back brief sets "Voltea tu identificación" in flame', (
    tester,
  ) async {
    await _pump(tester);
    await _tap(tester, 'Continuar');
    await _tap(tester, 'Continuar');

    final emphasis = tester.widget<ManoEmphasisText>(
      find.byType(ManoEmphasisText),
    );
    expect(emphasis.emphasis, 'Voltea tu identificación');
    expect(find.byTooltip('Atrás'), findsOneWidget);
  });

  testWidgets('Empezar runs the check and lands on pending', (tester) async {
    var done = 0;
    final port = await _pump(tester, onDone: () => done++);
    await _toSelfie(tester);

    await _tap(tester, 'Empezar');

    expect(port.verifies, 1);
    expect(find.text('Estamos revisando tus documentos'), findsOneWidget);
    await _tap(tester, 'Continuar');
    expect(done, 1);
  });

  testWidgets('closing Didit stays on the selfie brief', (tester) async {
    await _pump(
      tester,
      port: FakeIdentityVerification(
        const IdentityCheckNotStarted(),
        const Ok(IdentityCheckNotStarted()),
      ),
    );
    await _toSelfie(tester);

    await _tap(tester, 'Empezar');

    expect(find.text(_selfie), findsOneWidget);
  });

  testWidgets('a failure shows on the brief', (tester) async {
    await _pump(
      tester,
      port: FakeIdentityVerification(
        const IdentityCheckNotStarted(),
        const Err(DataUnavailable()),
      ),
    );
    await _toSelfie(tester);

    await _tap(tester, 'Empezar');

    expect(find.text(const DataUnavailable().message), findsOneWidget);
  });

  testWidgets('a retryable refusal shows the reason and walks again', (
    tester,
  ) async {
    await _pump(
      tester,
      port: FakeIdentityVerification(
        const IdentityCheckRejected(
          reason: 'No pudimos leer tu cédula.',
          canRetry: true,
        ),
      ),
    );
    expect(find.text('No pudimos verificar tu identidad'), findsOneWidget);
    expect(find.text('No pudimos leer tu cédula.'), findsOneWidget);

    await _tap(tester, 'Intentar de nuevo');
    expect(find.text(_front), findsOneWidget);
  });

  testWidgets('a final refusal offers no retry', (tester) async {
    var done = 0;
    await _pump(
      tester,
      onDone: () => done++,
      port: FakeIdentityVerification(
        const IdentityCheckRejected(reason: 'No.', canRetry: false),
      ),
    );
    expect(find.text('Intentar de nuevo'), findsNothing);
    await _tap(tester, 'Continuar');
    expect(done, 1);
  });

  testWidgets('an approved check says so with the badge', (tester) async {
    await _pump(
      tester,
      port: FakeIdentityVerification(const IdentityCheckApproved()),
    );
    expect(find.text('Tu identidad está verificada'), findsOneWidget);
    expect(find.byIcon(Icons.verified), findsOneWidget);
  });

  testWidgets('back from the front brief returns to the intro', (tester) async {
    await _pump(tester);
    await _tap(tester, 'Continuar');
    await tester.tap(find.byTooltip('Atrás'));
    await tester.pumpAndSettle();
    expect(find.byType(ManoTipList), findsOneWidget);
  });
}
