import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

void main() {
  testWidgets('opening a sheet clears a lingering snackbar so it cannot cover the sheet', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ManoTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                TextButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Hecho'), duration: Duration(minutes: 1)),
                  ),
                  child: const Text('toast'),
                ),
                TextButton(
                  onPressed: () => showManoSheet<void>(
                    context: context,
                    builder: (_) => const SizedBox(height: 200, child: Text('hoja')),
                  ),
                  child: const Text('sheet'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('toast'));
    await tester.pumpAndSettle();
    expect(find.text('Hecho'), findsOneWidget);

    await tester.tap(find.text('sheet'));
    await tester.pumpAndSettle();
    expect(find.text('hoja'), findsOneWidget);
    expect(find.text('Hecho'), findsNothing);
  });
}
