import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    theme: ManoTheme.light(),
    home: Scaffold(body: child),
  ),
);

ManoChatEntry _entry(
  String id,
  String text,
  DateTime at, {
  bool mine = false,
  ManoChatEntryStatus status = ManoChatEntryStatus.sent,
}) => ManoChatEntry(id: id, text: text, sentAt: at, mine: mine, status: status);

void main() {
  group('ManoChatThread', () {
    testWidgets('labels each day once and formats times', (tester) async {
      await _pump(
        tester,
        ManoChatThread(
          entries: [
            _entry('a', 'Hola', DateTime(2026, 10, 1, 9), mine: true),
            _entry('b', 'Qué tal', DateTime(2026, 10, 1, 10)),
            _entry('c', 'Buenos días', DateTime(2026, 10, 2, 8)),
          ],
          emptyMessage: 'Vacío',
          onRetry: (_) {},
        ),
      );

      expect(find.byType(ManoChatBubble), findsNWidgets(3));
      expect(find.text('1 oct'), findsOneWidget);
      expect(find.text('2 oct'), findsOneWidget);
      expect(find.text('9:00 a. m.'), findsOneWidget);
      final mine = tester.widget<ManoChatBubble>(
        find.widgetWithText(ManoChatBubble, 'Hola'),
      );
      expect(mine.mine, isTrue);
    });

    testWidgets('a pending entry reads "Enviando…"', (tester) async {
      await _pump(
        tester,
        ManoChatThread(
          entries: [
            _entry(
              'local-1',
              'Hola',
              DateTime(2026, 10, 1, 9),
              mine: true,
              status: ManoChatEntryStatus.pending,
            ),
          ],
          emptyMessage: 'Vacío',
          onRetry: (_) {},
        ),
      );

      expect(find.byKey(const Key('chat-item-pending')), findsOneWidget);
      expect(find.text('Enviando…'), findsOneWidget);
    });

    testWidgets('tapping a failed entry retries it by id', (tester) async {
      final retried = <String>[];
      await _pump(
        tester,
        ManoChatThread(
          entries: [
            _entry(
              'local-1',
              'Hola',
              DateTime(2026, 10, 1, 9),
              mine: true,
              status: ManoChatEntryStatus.failed,
            ),
          ],
          emptyMessage: 'Vacío',
          onRetry: retried.add,
        ),
      );

      expect(find.text('No se envió. Toca para reintentar.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('chat-item-failed')));
      expect(retried, ['local-1']);
    });

    testWidgets('no entries shows the empty message', (tester) async {
      await _pump(
        tester,
        ManoChatThread(
          entries: const [],
          emptyMessage: 'Escribe el primer mensaje',
          onRetry: (_) {},
        ),
      );

      expect(find.text('Escribe el primer mensaje'), findsOneWidget);
      expect(find.byType(ManoChatBubble), findsNothing);
    });
  });

  group('ManoChatHeader', () {
    testWidgets('shows the name, and a badge only when verified', (
      tester,
    ) async {
      await _pump(
        tester,
        const ManoChatHeader(
          name: 'Ana Gómez',
          photoUrl: null,
          online: true,
          verified: true,
        ),
      );
      expect(find.text('Ana Gómez'), findsOneWidget);
      expect(find.byIcon(Icons.verified), findsOneWidget);
      expect(find.byType(ManoAvatar), findsOneWidget);

      await _pump(
        tester,
        const ManoChatHeader(
          name: 'Luis',
          photoUrl: null,
          online: false,
          verified: false,
        ),
      );
      expect(find.byIcon(Icons.verified), findsNothing);
    });
  });
}
