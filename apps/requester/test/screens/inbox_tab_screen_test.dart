import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_requester/screens/inbox_tab_screen.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

/// A fixed, in-memory conversation list covering read/unread and
/// online/verified combinations, so badge and field-mapping tests have
/// something to prove against.
final class _FakeConversationRepository implements ConversationRepository {
  _FakeConversationRepository(this._conversations);

  final List<Conversation> _conversations;
  var calls = 0;

  @override
  Future<List<Conversation>> conversations() async {
    calls++;
    return _conversations;
  }
}

final _fakeConversations = [
  Conversation(
    id: 'conv-1',
    participant: Party(
      id: 'party-0',
      displayName: 'Camila Ríos',
      photoUrl: 'https://example.com/camila.jpg',
    ),
    participantRole: ManoRole.provider,
    lastMessage: 'Nos vemos mañana a las 10',
    lastMessageAt: DateTime.now().subtract(const Duration(minutes: 5)),
    isOnline: true,
    isVerified: true,
    unreadCount: 3,
  ),
  Conversation(
    id: 'conv-2',
    participant: Party(
      id: 'party-1',
      displayName: 'Juan García',
      photoUrl: 'https://example.com/juan.jpg',
    ),
    participantRole: ManoRole.provider,
    lastMessage: 'Listo, quedó todo funcionando',
    lastMessageAt: DateTime.now().subtract(const Duration(hours: 2)),
    isOnline: false,
    isVerified: false,
    unreadCount: 0,
  ),
];

Future<_FakeConversationRepository> _host(
  WidgetTester tester, {
  List<Conversation>? conversations,
}) async {
  final repository = _FakeConversationRepository(
    conversations ?? _fakeConversations,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [conversationRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        theme: ManoTheme.light(),
        home: const InboxTabScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  testWidgets('renders every conversation name and snippet', (tester) async {
    await _host(tester);

    expect(find.text('Camila Ríos'), findsOneWidget);
    expect(find.text('Nos vemos mañana a las 10'), findsOneWidget);
    expect(find.text('Juan García'), findsOneWidget);
    expect(find.text('Listo, quedó todo funcionando'), findsOneWidget);
  });

  testWidgets('renders the relative timestamp label for each conversation', (
    tester,
  ) async {
    await _host(tester);

    // conv-1 is ~5 minutes old, conv-2 is ~2 hours old (see _fakeConversations).
    expect(find.text('5m'), findsOneWidget);
    expect(find.text('2h'), findsOneWidget);
  });

  testWidgets(
    'formats the relative timestamp at the minute/hour/day boundaries',
    (tester) async {
      final now = DateTime.now();
      await _host(
        tester,
        conversations: [
          Conversation(
            id: 'boundary-1',
            participant: Party(
              id: 'party-2',
              displayName: 'Recién',
              photoUrl: 'https://example.com/a.jpg',
            ),
            participantRole: ManoRole.provider,
            lastMessage: 'Hace segundos',
            // Under a minute rounds up to '1m', never '0m'.
            lastMessageAt: now.subtract(const Duration(seconds: 30)),
          ),
          Conversation(
            id: 'boundary-2',
            participant: Party(
              id: 'party-3',
              displayName: 'Hace una hora',
              photoUrl: 'https://example.com/b.jpg',
            ),
            participantRole: ManoRole.provider,
            lastMessage: 'Justo a la hora',
            // Exactly 60 minutes is no longer "under 1 hour".
            lastMessageAt: now.subtract(const Duration(minutes: 60)),
          ),
          Conversation(
            id: 'boundary-3',
            participant: Party(
              id: 'party-4',
              displayName: 'Hace un día',
              photoUrl: 'https://example.com/c.jpg',
            ),
            participantRole: ManoRole.provider,
            lastMessage: 'Justo el día',
            // Exactly 24 hours is no longer "under 24 hours".
            lastMessageAt: now.subtract(const Duration(hours: 24)),
          ),
        ],
      );

      expect(find.text('1m'), findsOneWidget);
      expect(find.text('1h'), findsOneWidget);
      expect(find.text('1d'), findsOneWidget);
    },
  );

  testWidgets(
    'shows an unread badge only for conversations with unread messages',
    (tester) async {
      await _host(tester);

      expect(
        find.byKey(const Key('mano-conversation-tile-unread-badge')),
        findsOneWidget,
      );
      expect(find.text('3'), findsOneWidget);
    },
  );

  testWidgets(
    'renders the empty-list fallback when there are no conversations',
    (tester) async {
      await _host(tester, conversations: []);

      expect(find.byType(ManoConversationTile), findsNothing);
      expect(find.text('Aún no tienes conversaciones.'), findsOneWidget);
    },
  );

  testWidgets('pulling down refetches the conversations', (tester) async {
    final repository = await _host(tester);
    expect(repository.calls, 1);

    await tester.fling(find.text('Camila Ríos'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(repository.calls, 2);
  });

  testWidgets('the empty list can be pulled to refresh too', (tester) async {
    final repository = await _host(tester, conversations: []);

    await tester.fling(
      find.text('Aún no tienes conversaciones.'),
      const Offset(0, 400),
      1000,
    );
    await tester.pumpAndSettle();

    expect(repository.calls, 2);
  });
}
