import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

void main() {
  testWidgets('a sheet opened inside a nested navigator covers the outer bottom bar', (tester) async {
    var barTaps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: ManoTheme.light(),
        home: Scaffold(
          body: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => showManoSheet<void>(
                    context: context,
                    builder: (_) => const SizedBox(height: 300, width: double.infinity, child: Text('hoja')),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
          bottomNavigationBar: SizedBox(
            height: 80,
            child: TextButton(onPressed: () => barTaps++, child: const Text('bar')),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('hoja'), findsOneWidget);

    await tester.tap(find.text('bar'), warnIfMissed: false);
    expect(barTaps, 0, reason: 'the sheet sits above the bar, not under it');
  });
}
