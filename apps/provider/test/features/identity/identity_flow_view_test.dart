import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_provider/features/identity/identity_flow_view.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/fake_capture_camera.dart';
import '../../support/fake_identity.dart';

Future<FakeCaptureCamera> _pump(
  WidgetTester tester, {
  FakeIdentityVerification? port,
  FakeCaptureCamera? camera,
  VoidCallback? onDone,
  VoidCallback? onLater,
}) async {
  final cam = camera ?? FakeCaptureCamera();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        identityVerificationProvider.overrideWithValue(
          port ?? FakeIdentityVerification(),
        ),
        fakeCamera(cam),
      ],
      child: MaterialApp(
        theme: ManoTheme.light(),
        home: IdentityFlowView(onDone: onDone ?? () {}, onLater: onLater),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return cam;
}

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

Future<void> _tapTip(WidgetTester tester, String tooltip) async {
  await tester.tap(find.byTooltip(tooltip));
  await tester.pumpAndSettle();
}

/// Tomar foto, the shutter, then Usar foto.
Future<void> _shoot(WidgetTester tester) async {
  await _tap(tester, 'Tomar foto');
  await _tapTip(tester, 'Capturar');
  await _tap(tester, 'Usar foto');
}

Future<void> _photograph(WidgetTester tester) async {
  await _tap(tester, 'Continuar');
  await _shoot(tester);
  await _tap(tester, 'Continuar');
  await _shoot(tester);
  await _shoot(tester);
}

const _front = 'Toma la foto del frente de tu cédula';
const _backTips = 'Ahora necesitamos una foto del reverso de tu cédula';
const _back = 'Voltea tu cédula para tomar una foto de la parte de atrás';
const _selfie = '¿Tomamos tu selfie?';

Finder _art(String name) => find.image(AssetImage('assets/identity/$name.jpg'));

ManoCaptureFrame _frame(WidgetTester tester) =>
    tester.widget<ManoCaptureFrame>(find.byType(ManoCaptureFrame));

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

  testWidgets('walks Nu\'s steps: front, back tips, back, selfie', (
    tester,
  ) async {
    final camera = await _pump(tester);
    await _tap(tester, 'Continuar');

    expect(find.text(_front), findsOneWidget);
    expect(_art('cedula'), findsOneWidget);
    await _shoot(tester);

    expect(find.text(_backTips), findsOneWidget);
    expect(find.byType(ManoTipList), findsOneWidget);
    await _tap(tester, 'Continuar');

    expect(find.text(_back), findsOneWidget);
    expect(_art('cedula'), findsOneWidget);
    await _shoot(tester);

    expect(find.text(_selfie), findsOneWidget);
    expect(_art('selfie'), findsOneWidget);
    await _shoot(tester);

    expect(find.text('Revisa tus fotos'), findsOneWidget);
    expect(find.byType(ManoCaptureReviewRow), findsNWidgets(3));
    expect(camera.opened, [
      CameraFacing.rear,
      CameraFacing.rear,
      CameraFacing.front,
    ], reason: 'the cédula on the back camera, the selfie on the front');
    expect(camera.closed, 3, reason: 'each capture releases the camera');
  });

  group('the camera', () {
    testWidgets('the cédula gets the card guide, its line and Ayuda', (
      tester,
    ) async {
      await _pump(tester);
      await _tap(tester, 'Continuar');
      await _tap(tester, 'Tomar foto');

      expect(_frame(tester).shape, ManoCaptureShape.card);
      expect(find.text('Muestra el frente de tu cédula'), findsOneWidget);
      expect(find.byKey(const Key('fake-preview')), findsOneWidget);

      await _tap(tester, 'Ayuda');
      expect(find.text('Errores comunes'), findsOneWidget);
    });

    testWidgets('the selfie gets the face guide and no Ayuda', (tester) async {
      await _pump(tester);
      await _photograph(tester);
      await tester.tap(find.text('Repetir').at(2));
      await tester.pumpAndSettle();
      await _tap(tester, 'Tomar foto');

      expect(_frame(tester).shape, ManoCaptureShape.face);
      expect(find.text('Mira a la cámara'), findsOneWidget);
      expect(find.text('Ayuda'), findsNothing);
    });

    testWidgets('Repetir goes back to the live camera; Usar foto sends', (
      tester,
    ) async {
      final camera = await _pump(tester);
      await _tap(tester, 'Continuar');
      await _tap(tester, 'Tomar foto');

      await _tapTip(tester, 'Capturar');
      expect(find.text('Usar foto'), findsOneWidget);
      expect(find.byKey(const Key('fake-preview')), findsNothing);

      await _tap(tester, 'Repetir');
      expect(find.byKey(const Key('fake-preview')), findsOneWidget);
      expect(find.text('Usar foto'), findsNothing);

      await _tapTip(tester, 'Capturar');
      await _tap(tester, 'Usar foto');

      expect(camera.shots, 2);
      expect(find.text(_backTips), findsOneWidget);
    });

    testWidgets('closing the camera keeps the step, with no photo', (
      tester,
    ) async {
      final camera = await _pump(tester);
      await _tap(tester, 'Continuar');
      await _tap(tester, 'Tomar foto');

      await _tapTip(tester, 'Cerrar');

      expect(find.text(_front), findsOneWidget);
      expect(camera.closed, 1);
    });

    testWidgets('a denied camera says so and opens the settings', (
      tester,
    ) async {
      final camera = await _pump(
        tester,
        camera: FakeCaptureCamera(denied: true),
      );
      await _tap(tester, 'Continuar');
      await _tap(tester, 'Tomar foto');

      expect(
        find.textContaining('Necesitamos acceso a tu cámara'),
        findsOneWidget,
      );
      expect(find.byTooltip('Capturar'), findsNothing);

      await _tap(tester, 'Abrir ajustes');
      expect(camera.settings, 1);
    });
  });

  testWidgets('a retake from the review returns to the review', (tester) async {
    await _pump(tester);
    await _photograph(tester);

    await tester.tap(find.text('Repetir').at(1));
    await tester.pumpAndSettle();
    expect(find.text(_back), findsOneWidget, reason: 'no tips on a retake');
    await _shoot(tester);

    expect(find.text('Revisa tus fotos'), findsOneWidget);
  });

  testWidgets('Enviar lands on pending and Continuar leaves', (tester) async {
    var done = 0;
    await _pump(tester, onDone: () => done++);
    await _photograph(tester);

    await _tap(tester, 'Enviar');
    expect(find.text('Estamos revisando tus documentos'), findsOneWidget);

    await _tap(tester, 'Continuar');
    expect(done, 1);
  });

  testWidgets('a refusal shows the reason and starts over', (tester) async {
    await _pump(
      tester,
      port: FakeIdentityVerification(
        const IdentityCheckRejected(reason: 'La foto del frente está borrosa.'),
      ),
    );
    expect(find.text('No pudimos verificar tu identidad'), findsOneWidget);
    expect(find.text('La foto del frente está borrosa.'), findsOneWidget);

    await _tap(tester, 'Intentar de nuevo');
    expect(find.text(_front), findsOneWidget);
  });

  testWidgets('an approved check says so with the badge', (tester) async {
    await _pump(
      tester,
      port: FakeIdentityVerification(const IdentityCheckApproved()),
    );
    expect(find.text('Tu identidad está verificada'), findsOneWidget);
    expect(find.byIcon(Icons.verified), findsOneWidget);
  });

  testWidgets('back from a capture returns to the step before', (tester) async {
    await _pump(tester);
    await _tap(tester, 'Continuar');
    await _tapTip(tester, 'Atrás');
    expect(find.byType(ManoTipList), findsOneWidget);
  });

  testWidgets('back from the back photo returns to its tips', (tester) async {
    await _pump(tester);
    await _tap(tester, 'Continuar');
    await _shoot(tester);
    await _tap(tester, 'Continuar');
    await _tapTip(tester, 'Atrás');
    expect(find.text(_backTips), findsOneWidget);
  });
}
