import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  late TextEditingController controller;

  setUp(() => controller = TextEditingController());
  tearDown(() => controller.dispose());

  testWidgets('shows its label above the field, always', (tester) async {
    // Not a floating label: the question stays readable while typing.
    await tester.pumpWidget(
      _host(ManoTextField(label: 'Nombre', controller: controller)),
    );

    expect(find.text('Nombre'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Ana');
    await tester.pump();

    expect(find.text('Nombre'), findsOneWidget);
  });

  testWidgets('reports what was typed', (tester) async {
    String? seen;
    await tester.pumpWidget(
      _host(
        ManoTextField(
          label: 'Nombre',
          controller: controller,
          onChanged: (value) => seen = value,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Ana');

    expect(seen, 'Ana');
    expect(controller.text, 'Ana');
  });

  testWidgets('shows a hint until something is wrong', (tester) async {
    await tester.pumpWidget(
      _host(
        ManoTextField(
          label: 'Nombre',
          controller: controller,
          helperText: 'Como aparece en tu cédula',
        ),
      ),
    );

    expect(find.text('Como aparece en tu cédula'), findsOneWidget);

    await tester.pumpWidget(
      _host(
        ManoTextField(
          label: 'Nombre',
          controller: controller,
          helperText: 'Como aparece en tu cédula',
          errorText: 'Escribe tu nombre',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Escribe tu nombre'), findsOneWidget);
    expect(find.text('Como aparece en tu cédula'), findsNothing);
  });

  testWidgets('marks the focused rule with the brand colour', (tester) async {
    await tester.pumpWidget(
      _host(ManoTextField(label: 'Nombre', controller: controller)),
    );

    final decoration = tester
        .widget<TextField>(find.byType(TextField))
        .decoration!;

    expect(decoration.focusedBorder, isA<UnderlineInputBorder>());
    expect(
      (decoration.focusedBorder! as UnderlineInputBorder).borderSide.color,
      ManoColors.flame,
    );
  });

  testWidgets('hands focus to the next field', (tester) async {
    // Nombre -> Apellido on the keyboard's Next key is the most-noticed detail
    // in a two-field form.
    final second = FocusNode();
    final secondController = TextEditingController();
    addTearDown(second.dispose);
    addTearDown(secondController.dispose);

    await tester.pumpWidget(
      _host(
        Column(
          children: [
            ManoTextField(
              label: 'Nombre',
              controller: controller,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => second.requestFocus(),
            ),
            ManoTextField(
              label: 'Apellido',
              controller: secondController,
              focusNode: second,
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.byType(TextField).first);
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();

    expect(second.hasFocus, isTrue);
  });

  testWidgets('refuses input when disabled', (tester) async {
    await tester.pumpWidget(
      _host(
        ManoTextField(
          label: 'Nombre',
          controller: controller,
          enabled: false,
        ),
      ),
    );

    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
  });

  testWidgets('survives a small phone at large text without overflowing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ManoTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: Scaffold(
            body: ManoTextField(
              label: 'Dirección',
              controller: controller,
              helperText: 'Calle, número y barrio',
              errorText: 'Escribe una dirección completa',
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
