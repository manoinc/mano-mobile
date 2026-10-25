import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('shows the amount big and the helper under it', (tester) async {
    await tester.pumpWidget(
      _host(
        ManoAmountPad(
          amountLabel: r'$1.800.000',
          helperText: 'Puedes negociarlo después.',
          onDigit: (_) {},
          onBackspace: () {},
        ),
      ),
    );

    expect(find.text(r'$1.800.000'), findsOneWidget);
    expect(find.text('Puedes negociarlo después.'), findsOneWidget);
  });

  testWidgets('each key reports its digits, 000 included', (tester) async {
    final typed = <String>[];
    await tester.pumpWidget(
      _host(
        ManoAmountPad(
          amountLabel: r'$',
          onDigit: typed.add,
          onBackspace: () {},
        ),
      ),
    );

    for (final key in ['1', '5', '0', '000']) {
      await tester.tap(find.text(key));
    }

    expect(typed, ['1', '5', '0', '000']);
  });

  testWidgets('the erase key calls onBackspace', (tester) async {
    var erased = 0;
    await tester.pumpWidget(
      _host(
        ManoAmountPad(
          amountLabel: r'$5',
          onDigit: (_) {},
          onBackspace: () => erased++,
        ),
      ),
    );

    await tester.tap(find.byTooltip('Borrar'));

    expect(erased, 1);
  });

  testWidgets('fits a small phone at large text', (tester) async {
    tester.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: _host(
          SingleChildScrollView(
            child: ManoAmountPad(
              amountLabel: r'$999.999.999',
              onDigit: (_) {},
              onBackspace: () {},
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
