import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  testWidgets('hands back what was typed on Enviar', (tester) async {
    (String, String)? sent;
    await tester.pumpWidget(
      _host(ManoSupportForm(onSubmit: (s, d) => sent = (s, d))),
    );

    await tester.enterText(find.byType(TextField).first, 'Cobro doble');
    await tester.enterText(
      find.byType(TextField).last,
      'Me cobraron dos veces.',
    );
    await tester.tap(find.text('Enviar'));

    expect(sent, ('Cobro doble', 'Me cobraron dos veces.'));
  });

  testWidgets('shows the errors it is given', (tester) async {
    await tester.pumpWidget(
      _host(
        ManoSupportForm(
          onSubmit: (_, _) {},
          subjectError: 'Escribe un asunto.',
          descriptionError: 'Cuéntanos qué pasó.',
        ),
      ),
    );

    expect(find.text('Escribe un asunto.'), findsOneWidget);
    expect(find.text('Cuéntanos qué pasó.'), findsOneWidget);
  });

  testWidgets('ignores Enviar while sending', (tester) async {
    var sent = 0;
    await tester.pumpWidget(
      _host(ManoSupportForm(onSubmit: (_, _) => sent++, sending: true)),
    );

    await tester.tap(find.byType(ManoPrimaryButton));
    expect(sent, 0);
  });
}
