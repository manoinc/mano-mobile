import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(body: child),
);

TextSpan _spanOf(WidgetTester tester, String fragment) {
  final rich = tester.widget<Text>(find.textContaining(fragment));
  return (rich.textSpan! as TextSpan).children!.cast<TextSpan>().firstWhere(
    (s) => s.text == fragment,
  );
}

void main() {
  group('ManoEmphasisText', () {
    testWidgets('reads as one sentence', (tester) async {
      await tester.pumpWidget(
        _host(
          const ManoEmphasisText(
            'Vamos a confirmar tu identidad',
            emphasis: 'confirmar tu identidad',
          ),
        ),
      );
      expect(find.text('Vamos a confirmar tu identidad'), findsOneWidget);
    });

    testWidgets('paints the fragment in the theme accent', (tester) async {
      await tester.pumpWidget(
        _host(
          const ManoEmphasisText(
            'Vamos a confirmar tu identidad',
            emphasis: 'confirmar tu identidad',
          ),
        ),
      );
      expect(
        _spanOf(tester, 'confirmar tu identidad').style?.color,
        ManoColors.flame,
      );
    });

    testWidgets('a missing fragment leaves the text plain', (tester) async {
      await tester.pumpWidget(
        _host(const ManoEmphasisText('Hola', emphasis: 'adiós')),
      );
      expect(find.text('Hola'), findsOneWidget);
    });
  });

  group('ManoTipList', () {
    testWidgets('lists each tip with its bold fragment', (tester) async {
      await tester.pumpWidget(
        _host(
          const ManoTipList(
            tips: [
              ManoTip(
                'Limpia el lente de tu cámara',
                emphasis: 'Limpia el lente',
              ),
              ManoTip('Usa una superficie oscura'),
            ],
          ),
        ),
      );
      expect(find.text('Limpia el lente de tu cámara'), findsOneWidget);
      expect(find.text('Usa una superficie oscura'), findsOneWidget);
      expect(
        _spanOf(tester, 'Limpia el lente').style?.fontWeight,
        FontWeight.w600,
      );
    });
  });

  group('ManoStepScaffold headline', () {
    testWidgets('highlights a fragment of the headline', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ManoTheme.light(),
          home: ManoStepScaffold(
            headline: 'Toma la foto del frente de tu cédula',
            headlineEmphasis: 'frente',
            primaryLabel: 'Tomar foto',
            onPrimary: () {},
            children: const [],
          ),
        ),
      );
      expect(find.text('Toma la foto del frente de tu cédula'), findsOneWidget);
      expect(_spanOf(tester, 'frente').style?.color, ManoColors.flame);
    });
  });
}
