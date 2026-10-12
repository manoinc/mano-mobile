import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Future<void> _pump(WidgetTester tester, ManoReceipt receipt) =>
    tester.pumpWidget(
      MaterialApp(
        home: Center(child: ManoReceiptMark(receipt: receipt)),
      ),
    );

CustomPainter _painter(WidgetTester tester, ManoReceipt receipt) => tester
    .widget<CustomPaint>(
      find.descendant(
        of: find.byKey(Key('chat-receipt-${receipt.name}')),
        matching: find.byType(CustomPaint),
      ),
    )
    .painter!;

void main() {
  group('ManoReceiptMark', () {
    testWidgets('sent is a single circle wide', (tester) async {
      await _pump(tester, ManoReceipt.sent);
      final size = tester.getSize(find.byKey(const Key('chat-receipt-sent')));
      expect(size.width, size.height);
    });

    for (final receipt in [ManoReceipt.delivered, ManoReceipt.read]) {
      testWidgets('${receipt.name} is two overlapping circles', (tester) async {
        await _pump(tester, receipt);
        final size = tester.getSize(
          find.byKey(Key('chat-receipt-${receipt.name}')),
        );
        expect(size.width, greaterThan(size.height));
        expect(size.width, lessThan(size.height * 2));
      });
    }

    testWidgets('each state is announced in Spanish', (tester) async {
      const labels = {
        ManoReceipt.sent: 'Enviado',
        ManoReceipt.delivered: 'Entregado',
        ManoReceipt.read: 'Leído',
      };
      for (final entry in labels.entries) {
        await _pump(tester, entry.key);
        expect(find.bySemanticsLabel(entry.value), findsOneWidget);
      }
    });

    testWidgets('read paints differently from delivered', (tester) async {
      await _pump(tester, ManoReceipt.delivered);
      final delivered = _painter(tester, ManoReceipt.delivered);
      await _pump(tester, ManoReceipt.read);
      expect(
        _painter(tester, ManoReceipt.read).shouldRepaint(delivered),
        isTrue,
      );
    });
  });
}
