import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Future<void> pumpSheet(
  WidgetTester tester, {
  required Future<String?> Function(String email, String password) onSubmit,
}) => tester.pumpWidget(
  MaterialApp(
    theme: ManoTheme.light(),
    home: Scaffold(
      body: ManoCredentialsSheet(
        title: 'Inicia sesión',
        submitLabel: 'Entrar',
        onSubmit: onSubmit,
      ),
    ),
  ),
);

void main() {
  testWidgets('submits the typed email and password', (tester) async {
    String? email;
    String? password;
    await pumpSheet(
      tester,
      onSubmit: (e, p) async {
        email = e;
        password = p;
        return null;
      },
    );

    await tester.enterText(find.byKey(const Key('mano-credentials-email')), 'ana@mano.co');
    await tester.enterText(find.byKey(const Key('mano-credentials-password')), 'secret');
    await tester.pump();
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(email, 'ana@mano.co');
    expect(password, 'secret');
  });

  testWidgets('hides the password', (tester) async {
    await pumpSheet(tester, onSubmit: (_, _) async => null);

    final field = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('mano-credentials-password')),
        matching: find.byType(TextField),
      ),
    );
    expect(field.obscureText, isTrue);
  });

  testWidgets('cannot submit until both fields are filled', (tester) async {
    var calls = 0;
    await pumpSheet(tester, onSubmit: (_, _) async {
      calls++;
      return null;
    });

    await tester.enterText(find.byKey(const Key('mano-credentials-email')), 'ana@mano.co');
    await tester.pump();
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(calls, 0);
  });

  testWidgets('shows the returned error and stays open', (tester) async {
    final answer = Completer<String?>();
    await pumpSheet(tester, onSubmit: (_, _) => answer.future);

    await tester.enterText(find.byKey(const Key('mano-credentials-email')), 'ana@mano.co');
    await tester.enterText(find.byKey(const Key('mano-credentials-password')), 'nope');
    await tester.pump();
    await tester.tap(find.text('Entrar'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    answer.complete('Correo o contraseña incorrectos.');
    await tester.pumpAndSettle();

    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
