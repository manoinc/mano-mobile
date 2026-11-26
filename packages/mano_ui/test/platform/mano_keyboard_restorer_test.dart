import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpApp(WidgetTester tester, {required bool focused}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ManoKeyboardRestorer(
          child: Scaffold(body: TextField(autofocus: focused)),
        ),
      ),
    );
    await tester.pump();
    tester.testTextInput.log.clear();
  }

  // The notification shade: Android takes window focus, then gives it back.
  Future<List<String>> pullShade(WidgetTester tester) async {
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    return [for (final call in tester.testTextInput.log) call.method];
  }

  testWidgets(
    'reconnects the focused field to the keyboard when the window comes back',
    (tester) async {
      await pumpApp(tester, focused: true);

      expect(
        await pullShade(tester),
        containsAllInOrder([
          'TextInput.clearClient',
          'TextInput.setClient',
          'TextInput.show',
        ]),
      );
    },
  );

  testWidgets('leaves the keyboard alone when no field is focused', (
    tester,
  ) async {
    await pumpApp(tester, focused: false);

    expect(
      await pullShade(tester),
      isNot(
        containsAllInOrder([
          'TextInput.clearClient',
          'TextInput.setClient',
          'TextInput.show',
        ]),
      ),
    );
  });

  testWidgets('leaves the keyboard alone on iOS', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await pumpApp(tester, focused: true);

    expect(await pullShade(tester), isNot(contains('TextInput.setClient')));
    debugDefaultTargetPlatformOverride = null;
  });
}
