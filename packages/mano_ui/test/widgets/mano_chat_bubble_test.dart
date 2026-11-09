import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

import '../support/tiny_png.dart';

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

    testWidgets('a short message keeps its time on the same line', (
      tester,
    ) async {
      await _pump(
        tester,
        const ManoChatBubble(text: 'Hola', timeLabel: '9:00', mine: true),
      );
      final text = tester.getRect(find.text('Hola', findRichText: true));
      final time = tester.getRect(find.byKey(const Key('chat-bubble-time')));
      expect(time.left, greaterThanOrEqualTo(text.left));
      expect(time.center.dy, closeTo(text.center.dy, 8));
      expect(
        tester.getSize(find.byKey(const Key('chat-bubble-body'))).height,
        lessThan(40),
      );
    });

    testWidgets('a long message drops its time below the text', (tester) async {
      await _pump(
        tester,
        ManoChatBubble(text: 'Hola ' * 40, timeLabel: '9:00', mine: true),
      );
      final text = tester.getRect(
        find.textContaining('Hola', findRichText: true),
      );
      final time = tester.getRect(find.byKey(const Key('chat-bubble-time')));
      expect(time.top, greaterThanOrEqualTo(text.bottom - 20));
      expect(time.right, closeTo(text.right, 1));
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

  group('ManoChatBubble with photos', () {
    testWidgets('draws each photo above the text', (tester) async {
      await _pump(
        tester,
        ManoChatBubble(
          text: 'Mira',
          mine: true,
          timeLabel: '9:00',
          photos: [tinyImage, tinyImage],
        ),
      );

      expect(find.byKey(const Key('chat-bubble-photo')), findsNWidgets(2));
      final photo = tester.getTopLeft(
        find.byKey(const Key('chat-bubble-photo')).first,
      );
      expect(photo.dy, lessThan(tester.getTopLeft(find.text('Mira')).dy));
    });

    testWidgets('photos alone draw no text bubble but keep the time', (
      tester,
    ) async {
      await _pump(
        tester,
        ManoChatBubble(
          text: '',
          mine: true,
          timeLabel: '9:00',
          receipt: ManoReceipt.read,
          photos: [tinyImage],
        ),
      );

      expect(find.byKey(const Key('chat-bubble-body')), findsNothing);
      expect(find.text('9:00'), findsOneWidget);
      expect(find.byKey(const Key('chat-receipt-read')), findsOneWidget);
    });

    testWidgets('tapping a photo reports its index', (tester) async {
      final tapped = <int>[];
      await _pump(
        tester,
        ManoChatBubble(
          text: '',
          mine: false,
          photos: [tinyImage, tinyImage],
          onPhotoTap: tapped.add,
        ),
      );

      await tester.tap(find.byKey(const Key('chat-bubble-photo')).last);
      expect(tapped, [1]);
    });

    testWidgets('an uploading photo shows progress, a failed one an alert', (
      tester,
    ) async {
      await _pump(
        tester,
        ManoChatBubble(
          text: '',
          mine: true,
          photos: [tinyImage],
          photoStatus: ManoPhotoStatus.uploading,
        ),
      );
      expect(find.byType(ManoLoader), findsOneWidget);

      await _pump(
        tester,
        ManoChatBubble(
          text: '',
          mine: true,
          photos: [tinyImage],
          photoStatus: ManoPhotoStatus.failed,
        ),
      );
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });
  });
}
