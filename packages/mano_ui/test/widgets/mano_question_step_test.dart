import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) =>
    MaterialApp(theme: ManoTheme.light(), home: child);

ManoQuestionStep _step({
  VoidCallback? onPrimary,
  VoidCallback? onBack,
  VoidCallback? onSkip,
  double progress = 0.25,
}) => ManoQuestionStep(
  title: '¿Cuál es tu nombre?',
  subtitle: 'Así te verán tus clientes.',
  progress: progress,
  primaryLabel: 'Continuar',
  onPrimary: onPrimary,
  onBack: onBack,
  onSkip: onSkip,
  child: const TextField(),
);

void main() {
  testWidgets('shows the question, its input and a progress bar', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_step()));
    expect(find.text('¿Cuál es tu nombre?'), findsOneWidget);
    expect(find.text('Así te verán tus clientes.'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, 0.25);
  });

  testWidgets('primary is shut until the answer is valid', (tester) async {
    await tester.pumpWidget(_host(_step()));
    expect(
      tester
          .widget<ManoPrimaryButton>(find.byType(ManoPrimaryButton))
          .onPressed,
      isNull,
    );
    var taps = 0;
    await tester.pumpWidget(_host(_step(onPrimary: () => taps++)));
    await tester.tap(find.text('Continuar'));
    expect(taps, 1);
  });

  testWidgets('back and skip appear only when given', (tester) async {
    await tester.pumpWidget(_host(_step()));
    expect(find.byTooltip('Atrás'), findsNothing);
    expect(find.text('Omitir'), findsNothing);

    var back = 0;
    var skip = 0;
    await tester.pumpWidget(
      _host(_step(onBack: () => back++, onSkip: () => skip++)),
    );
    await tester.tap(find.byTooltip('Atrás'));
    await tester.tap(find.text('Omitir'));
    expect([back, skip], [1, 1]);
  });
}
