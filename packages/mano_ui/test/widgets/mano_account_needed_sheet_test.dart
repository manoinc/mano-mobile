import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('says an account is needed and why', (tester) async {
    await tester.pumpWidget(
      _host(
        ManoAccountNeededSheet(
          message: 'Inicia sesión para aceptar solicitudes.',
          onSignIn: () {},
          onClose: () {},
        ),
      ),
    );

    expect(find.text('Necesitas una cuenta'), findsOneWidget);
    expect(find.text('Inicia sesión para aceptar solicitudes.'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  testWidgets('the one action signs in', (tester) async {
    var signedIn = 0;
    await tester.pumpWidget(
      _host(
        ManoAccountNeededSheet(
          message: 'Inicia sesión para escribir.',
          onSignIn: () => signedIn++,
          onClose: () {},
        ),
      ),
    );

    await tester.tap(find.text('Iniciar sesión'));

    expect(signedIn, 1);
  });
}
