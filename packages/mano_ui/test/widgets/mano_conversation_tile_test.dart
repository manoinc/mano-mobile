import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
      theme: ManoTheme.light(),
      home: Scaffold(body: Center(child: child)),
    );

Widget _darkHost(Widget child) => MaterialApp(
      theme: ManoTheme.dark(),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('the conversation tile', () {
    testWidgets('shows the name, snippet and timestamp', (tester) async {
      await tester.pumpWidget(_host(
        ManoConversationTile(
          avatarUrl: 'https://example.com/a.png',
          online: false,
          verified: false,
          name: 'Camila Ríos',
          snippet: 'Nos vemos mañana a las 10',
          timestampLabel: '5m',
          unreadCount: 0,
          onTap: () {},
        ),
      ));

      expect(find.text('Camila Ríos'), findsOneWidget);
      expect(find.text('Nos vemos mañana a las 10'), findsOneWidget);
      expect(find.text('5m'), findsOneWidget);
    });

    testWidgets('calls onTap exactly once', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host(
        ManoConversationTile(
          avatarUrl: 'https://example.com/a.png',
          online: false,
          verified: false,
          name: 'Camila Ríos',
          snippet: 'Nos vemos mañana a las 10',
          timestampLabel: '5m',
          unreadCount: 0,
          onTap: () => taps++,
        ),
      ));

      await tester.tap(find.byType(ManoConversationTile));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('shows a verified mark only when verified', (tester) async {
      await tester.pumpWidget(_host(
        ManoConversationTile(
          avatarUrl: 'https://example.com/a.png',
          online: false,
          verified: true,
          name: 'Camila Ríos',
          snippet: 'Nos vemos mañana a las 10',
          timestampLabel: '5m',
          unreadCount: 0,
          onTap: () {},
        ),
      ));

      expect(find.byIcon(Icons.verified), findsOneWidget);
    });

    testWidgets('hides the verified mark when not verified', (tester) async {
      await tester.pumpWidget(_host(
        ManoConversationTile(
          avatarUrl: 'https://example.com/a.png',
          online: false,
          verified: false,
          name: 'Camila Ríos',
          snippet: 'Nos vemos mañana a las 10',
          timestampLabel: '5m',
          unreadCount: 0,
          onTap: () {},
        ),
      ));

      expect(find.byIcon(Icons.verified), findsNothing);
    });

    testWidgets('renders no unread badge when the count is zero', (tester) async {
      await tester.pumpWidget(_host(
        ManoConversationTile(
          avatarUrl: 'https://example.com/a.png',
          online: false,
          verified: false,
          name: 'Camila Ríos',
          snippet: 'Nos vemos mañana a las 10',
          timestampLabel: '5m',
          unreadCount: 0,
          onTap: () {},
        ),
      ));

      expect(find.text('0'), findsNothing);
      expect(find.byKey(const Key('mano-conversation-tile-unread-badge')), findsNothing);
    });

    testWidgets('renders an unread badge showing the count', (tester) async {
      await tester.pumpWidget(_host(
        ManoConversationTile(
          avatarUrl: 'https://example.com/a.png',
          online: false,
          verified: false,
          name: 'Camila Ríos',
          snippet: 'Nos vemos mañana a las 10',
          timestampLabel: '5m',
          unreadCount: 3,
          onTap: () {},
        ),
      ));

      expect(find.byKey(const Key('mano-conversation-tile-unread-badge')), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets(
      'renders the snippet in the dark-mode-appropriate color, not the hard-coded light one',
      (tester) async {
        await tester.pumpWidget(_darkHost(
          ManoConversationTile(
            avatarUrl: 'https://example.com/a.png',
            online: false,
            verified: false,
            name: 'Camila Ríos',
            snippet: 'Nos vemos mañana a las 10',
            timestampLabel: '5m',
            unreadCount: 0,
            onTap: () {},
          ),
        ));

        final snippet = tester.widget<Text>(
          find.text('Nos vemos mañana a las 10'),
        );
        final darkOnSurfaceVariant = ManoTheme.dark().colorScheme.onSurfaceVariant;

        expect(snippet.style?.color, isNot(ManoColors.muted));
        expect(snippet.style?.color, darkOnSurfaceVariant);
      },
    );
  });
}
