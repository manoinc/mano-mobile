import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    theme: ManoTheme.light(),
    home: Scaffold(body: child),
  ),
);

BorderRadius _radius(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find.byKey(const Key('chat-bubble-body')),
  );
  return (box.decoration as BoxDecoration).borderRadius! as BorderRadius;
}

void main() {
  group('ManoChatBubble', () {
    testWidgets('a lone bubble is rounded on every corner', (tester) async {
      await _pump(
        tester,
        const ManoChatBubble(text: 'Hola', timeLabel: '9:00', mine: true),
      );
      expect(_radius(tester), BorderRadius.circular(ManoRadius.lg));
    });

    testWidgets('mine tightens its right corners inside a group', (
      tester,
    ) async {
      await _pump(
        tester,
        const ManoChatBubble(
          text: 'Hola',
          mine: true,
          isFirstInGroup: false,
          isLastInGroup: false,
        ),
      );
      final radius = _radius(tester);
      expect(radius.topRight, const Radius.circular(ManoRadius.sm));
      expect(radius.bottomRight, const Radius.circular(ManoRadius.sm));
      expect(radius.topLeft, const Radius.circular(ManoRadius.lg));
    });

    testWidgets('theirs tightens its left corners, first keeps its top', (
      tester,
    ) async {
      await _pump(
        tester,
        const ManoChatBubble(text: 'Hola', mine: false, isLastInGroup: false),
      );
      final radius = _radius(tester);
      expect(radius.topLeft, const Radius.circular(ManoRadius.lg));
      expect(radius.bottomLeft, const Radius.circular(ManoRadius.sm));
      expect(radius.bottomRight, const Radius.circular(ManoRadius.lg));
    });

    testWidgets('no time label means no time is drawn', (tester) async {
      await _pump(tester, const ManoChatBubble(text: 'Hola', mine: true));
      expect(find.byKey(const Key('chat-bubble-time')), findsNothing);
    });

    testWidgets('each receipt draws its own icon', (tester) async {
      for (final receipt in ManoReceipt.values) {
        await _pump(
          tester,
          ManoChatBubble(
            text: 'Hola',
            timeLabel: '9:00',
            mine: true,
            receipt: receipt,
          ),
        );
        expect(find.byKey(Key('chat-receipt-${receipt.name}')), findsOneWidget);
      }
    });

    testWidgets('a receipt is announced in Spanish', (tester) async {
      await _pump(
        tester,
        const ManoChatBubble(
          text: 'Hola',
          timeLabel: '9:00',
          mine: true,
          receipt: ManoReceipt.read,
        ),
      );
      expect(find.bySemanticsLabel('Leído'), findsOneWidget);
    });

    testWidgets('theirs never shows a receipt', (tester) async {
      await _pump(
        tester,
        const ManoChatBubble(
          text: 'Hola',
          timeLabel: '9:00',
          mine: false,
          receipt: ManoReceipt.read,
        ),
      );
      expect(find.byKey(const Key('chat-receipt-read')), findsNothing);
    });
  });
}
