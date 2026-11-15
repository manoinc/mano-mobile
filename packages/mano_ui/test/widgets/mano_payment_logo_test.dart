import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('every logo gets the same box, so row titles line up', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ManoPaymentLogo(
              key: Key('wide'),
              logo: SizedBox(width: 300, height: 96),
            ),
            ManoPaymentLogo(
              key: Key('square'),
              logo: SizedBox(width: 96, height: 96),
            ),
            ManoPaymentLogo(key: Key('none')),
          ],
        ),
      ),
    );

    for (final key in ['wide', 'square', 'none']) {
      expect(tester.getSize(find.byKey(Key(key))), ManoPaymentLogo.box);
    }
  });

  testWidgets('a logo is scaled down whole and starts at the left edge', (
    tester,
  ) async {
    const logo = Key('logo');
    await tester.pumpWidget(
      _host(
        const ManoPaymentLogo(logo: SizedBox(key: logo, width: 96, height: 96)),
      ),
    );

    final frame = tester.getRect(find.byType(ManoPaymentLogo));
    final drawn = tester.getRect(find.byKey(logo));
    expect(drawn.height, closeTo(frame.height, 0.01));
    expect(drawn.width, closeTo(frame.height, 0.01));
    expect(drawn.left, frame.left);
  });

  testWidgets('without a logo it shows the fallback', (tester) async {
    await tester.pumpWidget(
      _host(
        const ManoPaymentLogo(fallback: Icon(Icons.account_balance_outlined)),
      ),
    );

    expect(find.byIcon(Icons.account_balance_outlined), findsOneWidget);
  });
}
