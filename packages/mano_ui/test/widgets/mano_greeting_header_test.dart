import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('the greeting header', () {
    testWidgets('greets the given name', (tester) async {
      await tester.pumpWidget(_host(const ManoGreetingHeader(name: 'Jessica')));

      expect(find.text('Hola, Jessica'), findsOneWidget);
    });

    testWidgets('without a name it still says hello', (tester) async {
      await tester.pumpWidget(_host(const ManoGreetingHeader()));

      expect(find.text('Hola'), findsOneWidget);
    });
  });
}
