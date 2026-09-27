import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('the address pill', () {
    testWidgets('renders the given address', (tester) async {
      await tester.pumpWidget(
        _host(ManoAddressPill(address: 'Calle 10 # 5-30', onTap: () {})),
      );

      expect(find.text('Calle 10 # 5-30'), findsOneWidget);
    });

    testWidgets('fires onTap once when tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          ManoAddressPill(address: 'Calle 10 # 5-30', onTap: () => taps++),
        ),
      );

      await tester.tap(find.byType(ManoAddressPill));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });
  });
}
