import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Future<void> _pump(WidgetTester tester, ManoIllustratedStep step) =>
    tester.pumpWidget(MaterialApp(theme: ManoTheme.light(), home: step));

const _art = ColoredBox(key: Key('art'), color: ManoColors.sand);

Finder _headline(String start) => find.textContaining(start);

void main() {
  testWidgets('shows the illustration above the headline', (tester) async {
    await _pump(
      tester,
      ManoIllustratedStep(
        illustration: _art,
        headline: 'Toma la foto del frente de tu cédula',
        headlineEmphasis: 'foto del frente',
        primaryLabel: 'Tomar foto',
        onPrimary: () {},
      ),
    );

    final art = tester.getRect(find.byKey(const Key('art')));
    expect(art.top, 0, reason: 'the photo bleeds to the top edge');
    expect(
      art.bottom,
      lessThanOrEqualTo(tester.getRect(_headline('Toma la')).top),
    );
    final rich = tester.widget<Text>(_headline('Toma la'));
    final spans = (rich.textSpan! as TextSpan).children!.cast<TextSpan>();
    expect(
      spans.firstWhere((s) => s.text == 'foto del frente').style?.color,
      ManoColors.flame,
    );
  });

  testWidgets('the primary action fires', (tester) async {
    var taps = 0;
    await _pump(
      tester,
      ManoIllustratedStep(
        illustration: _art,
        headline: '¿Tomamos tu selfie?',
        primaryLabel: 'Tomar foto',
        onPrimary: () => taps++,
      ),
    );
    await tester.tap(find.text('Tomar foto'));
    expect(taps, 1);
  });

  testWidgets('back and the secondary action appear only when set', (
    tester,
  ) async {
    var back = 0;
    var help = 0;
    await _pump(
      tester,
      ManoIllustratedStep(
        illustration: _art,
        headline: '¿Tomamos tu selfie?',
        primaryLabel: 'Tomar foto',
        onPrimary: () {},
        onBack: () => back++,
        secondaryLabel: 'Ayuda',
        onSecondary: () => help++,
      ),
    );
    await tester.tap(find.byTooltip('Atrás'));
    await tester.tap(find.text('Ayuda'));
    expect((back, help), (1, 1));

    await _pump(
      tester,
      ManoIllustratedStep(
        illustration: _art,
        headline: '¿Tomamos tu selfie?',
        primaryLabel: 'Tomar foto',
        onPrimary: () {},
      ),
    );
    expect(find.byTooltip('Atrás'), findsNothing);
    expect(find.text('Ayuda'), findsNothing);
  });

  testWidgets('a notice sits above the action', (tester) async {
    await _pump(
      tester,
      ManoIllustratedStep(
        illustration: _art,
        headline: '¿Tomamos tu selfie?',
        primaryLabel: 'Tomar foto',
        onPrimary: () {},
        notice: const Text('Esa foto no sirve'),
      ),
    );
    expect(
      tester.getRect(find.text('Esa foto no sirve')).bottom,
      lessThanOrEqualTo(tester.getRect(find.text('Tomar foto')).top),
    );
  });

  testWidgets('busy holds back while the primary spins', (tester) async {
    var back = 0;
    await _pump(
      tester,
      ManoIllustratedStep(
        illustration: _art,
        headline: '¿Tomamos tu selfie?',
        primaryLabel: 'Tomar foto',
        onPrimary: () {},
        onBack: () => back++,
        busy: true,
      ),
    );
    await tester.tap(find.byTooltip('Atrás'), warnIfMissed: false);
    expect(back, 0);
  });
}
