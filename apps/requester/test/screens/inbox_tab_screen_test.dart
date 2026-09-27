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
  const _FakeConversationRepository(this._conversations);

  final List<Conversation> _conversations;

  @override
  Future<List<Conversation>> conversations() async => _conversations;
}

final _fakeConversations = [
  Conversation(
    id: 'conv-1',
    participantName: 'Camila Ríos',
    participantPhotoUrl: 'https://example.com/camila.jpg',
    lastMessage: 'Nos vemos mañana a las 10',
    lastMessageAt: DateTime.now().subtract(const Duration(minutes: 5)),
    isOnline: true,
    isVerified: true,
    unreadCount: 3,
  ),
  Conversation(
    id: 'conv-2',
    participantName: 'Juan García',
    participantPhotoUrl: 'https://example.com/juan.jpg',
    lastMessage: 'Listo, quedó todo funcionando',
    lastMessageAt: DateTime.now().subtract(const Duration(hours: 2)),
    isOnline: false,
    isVerified: false,
    unreadCount: 0,
  ),
];

Future<void> _host(WidgetTester tester, {List<Conversation>? conversations}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        conversationRepositoryProvider.overrideWithValue(
          _FakeConversationRepository(conversations ?? _fakeConversations),
        ),
      ],
      child: MaterialApp(
        theme: ManoTheme.light(),
        home: const InboxTabScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders every conversation name and snippet', (tester) async {
    await _host(tester);

    expect(find.text('Camila Ríos'), findsOneWidget);
    expect(find.text('Nos vemos mañana a las 10'), findsOneWidget);
    expect(find.text('Juan García'), findsOneWidget);
    expect(find.text('Listo, quedó todo funcionando'), findsOneWidget);
  });

  testWidgets('shows an unread badge only for conversations with unread messages', (
    tester,
  ) async {
    await _host(tester);

    expect(
      find.byKey(const Key('mano-conversation-tile-unread-badge')),
      findsOneWidget,
    );
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('tapping a conversation tile shows the stub notice', (tester) async {
    await _host(tester);

    await tester.tap(find.byType(ManoConversationTile).first);
    await tester.pumpAndSettle();

    expect(find.text('Muy pronto'), findsOneWidget);
  });

  testWidgets('renders the empty-list fallback when there are no conversations', (
    tester,
  ) async {
    await _host(tester, conversations: []);

    expect(find.byType(ManoConversationTile), findsNothing);
    expect(find.text('Aún no tienes conversaciones.'), findsOneWidget);
  });
}
