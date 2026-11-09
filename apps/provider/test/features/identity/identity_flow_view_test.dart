import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_provider/features/identity/identity_flow_view.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/fake_identity.dart';
import '../../support/fake_media.dart';

Future<FakeMediaPicker> _pump(
  WidgetTester tester, {
  FakeIdentityVerification? port,
  VoidCallback? onDone,
  VoidCallback? onLater,
}) async {
  final picker = FakeMediaPicker();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        identityVerificationProvider.overrideWithValue(
          port ?? FakeIdentityVerification(),
        ),
        mediaPickerProvider.overrideWithValue(picker),
      ],
      child: MaterialApp(
        theme: ManoTheme.light(),
        home: IdentityFlowView(onDone: onDone ?? () {}, onLater: onLater),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return picker;
}

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

Future<void> _photograph(WidgetTester tester) async {
  await _tap(tester, 'Continuar');
  for (var i = 0; i < 3; i++) {
    await _tap(tester, 'Tomar foto');
  }
}

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

  testWidgets('front, back and selfie each show their guide', (tester) async {
    final picker = await _pump(tester);
    await _tap(tester, 'Continuar');

    expect(find.text('Muestra el frente de tu cédula'), findsOneWidget);
    await _tap(tester, 'Tomar foto');
    expect(find.text('Muestra el reverso de tu cédula'), findsOneWidget);
    await _tap(tester, 'Tomar foto');
    expect(find.text('Mira a la cámara'), findsOneWidget);
    expect(
      tester.widget<ManoCaptureFrame>(find.byType(ManoCaptureFrame)).shape,
      ManoCaptureShape.face,
    );
    await _tap(tester, 'Tomar foto');

    expect(find.text('Revisa tus fotos'), findsOneWidget);
    expect(find.byType(ManoCaptureReviewRow), findsNWidgets(3));
    expect(picker.sources, everyElement(PhotoSource.camera));
  });

  testWidgets('Ayuda lists the common mistakes', (tester) async {
    await _pump(tester);
    await _tap(tester, 'Continuar');
    await _tap(tester, 'Ayuda');
    expect(find.text('Errores comunes'), findsOneWidget);
  });

  testWidgets('a retake from the review returns to the review', (tester) async {
    await _pump(tester);
    await _photograph(tester);

    await tester.tap(find.text('Repetir').at(1));
    await tester.pumpAndSettle();
    expect(find.text('Muestra el reverso de tu cédula'), findsOneWidget);
    await _tap(tester, 'Tomar foto');

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
    expect(find.text('Muestra el frente de tu cédula'), findsOneWidget);
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
    await tester.tap(find.byTooltip('Atrás'));
    await tester.pumpAndSettle();
    expect(find.byType(ManoTipList), findsOneWidget);
  });
}
