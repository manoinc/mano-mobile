import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(16), child: child),
  ),
);

void main() {
  group('ManoOtpField', () {
    testWidgets('fills six boxes and reports the complete code', (
      tester,
    ) async {
      String? completed;
      final changes = <String>[];
      await tester.pumpWidget(
        _host(
          ManoOtpField(
            value: '',
            onChanged: changes.add,
            onCompleted: (code) => completed = code,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '12a3456');
      await tester.pump();

      expect(changes.last, '123456');
      expect(completed, '123456');
      for (final digit in ['1', '2', '3', '4', '5', '6']) {
        expect(find.text(digit), findsOneWidget);
      }
    });

    testWidgets('offers the SMS code to autofill', (tester) async {
      await tester.pumpWidget(_host(const ManoOtpField(value: '')));

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.autofillHints, contains(AutofillHints.oneTimeCode));
      expect(field.keyboardType, TextInputType.number);
    });

    testWidgets('clears when the value is reset from outside', (tester) async {
      await tester.pumpWidget(_host(const ManoOtpField(value: '123')));
      expect(find.text('3'), findsOneWidget);

      await tester.pumpWidget(_host(const ManoOtpField(value: '')));

      expect(find.text('3'), findsNothing);
    });

    testWidgets('shows the error under the boxes', (tester) async {
      await tester.pumpWidget(
        _host(
          const ManoOtpField(
            value: '',
            errorText: 'Ese código no es correcto.',
          ),
        ),
      );

      expect(find.text('Ese código no es correcto.'), findsOneWidget);
    });
  });

  group('ManoResendTimer', () {
    testWidgets('counts down, then offers to resend and restarts', (
      tester,
    ) async {
      var resent = 0;
      await tester.pumpWidget(
        _host(
          ManoResendTimer(
            wait: const Duration(seconds: 3),
            onResend: () => resent++,
          ),
        ),
      );

      expect(find.text('Reenviar código en 3 s'), findsOneWidget);
      await tester.tap(find.text('Reenviar código en 3 s'));
      expect(resent, 0);

      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Reenviar código'), findsOneWidget);

      await tester.tap(find.text('Reenviar código'));
      await tester.pump();
      expect(resent, 1);
      expect(find.text('Reenviar código en 3 s'), findsOneWidget);
    });
  });

  testWidgets('the credentials sheet can offer a second way', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        ManoCredentialsSheet(
          title: 'Inicia sesión',
          submitLabel: 'Entrar',
          onSubmit: (_, _) async => null,
          secondaryLabel: 'Crear cuenta con correo',
          onSecondary: () => taps++,
        ),
      ),
    );

    await tester.tap(find.text('Crear cuenta con correo'));
    expect(taps, 1);
  });
}
