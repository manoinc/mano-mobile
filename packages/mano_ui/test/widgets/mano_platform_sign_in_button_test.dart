import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

const _google = Key('google-mark');
const _apple = Key('apple-mark');

Widget _host(
  TargetPlatform platform, {
  VoidCallback? onGoogle,
  VoidCallback? onApple,
}) => MaterialApp(
  theme: ManoTheme.light().copyWith(platform: platform),
  home: Scaffold(
    body: ManoPlatformSignInButton(
      googleMark: const SizedBox(key: _google),
      appleMark: const SizedBox(key: _apple),
      onGoogle: onGoogle,
      onApple: onApple,
    ),
  ),
);

void main() {
  testWidgets('offers Google on Android', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(TargetPlatform.android, onGoogle: () => taps++),
    );

    expect(find.text('Continuar con Google'), findsOneWidget);
    expect(find.byKey(_google), findsOneWidget);
    expect(find.byKey(_apple), findsNothing);

    await tester.tap(find.byType(ManoBrandButton));
    expect(taps, 1);
  });

  testWidgets('offers Apple on iOS', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(TargetPlatform.iOS, onApple: () => taps++));

    expect(find.text('Continuar con Apple'), findsOneWidget);
    expect(find.byKey(_apple), findsOneWidget);
    expect(find.byKey(_google), findsNothing);

    await tester.tap(find.byType(ManoBrandButton));
    expect(taps, 1);
  });
}
