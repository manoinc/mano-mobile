import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/fake_session_repository.dart';
import '../../support/pump_app.dart';

final class _FakeConversationRepository implements ConversationRepository {
  _FakeConversationRepository(this._conversations, {this.failing = false});

  final List<Conversation> _conversations;
  bool failing;
  var calls = 0;

  @override
  Future<List<Conversation>> conversations() async {
    calls++;
    if (failing) throw Exception('offline');
    return _conversations;
  }

  @override
  Future<Result<Conversation, DataFailure>> open({
    String? withWorkerId,
    String? jobId,
  }) => throw UnimplementedError();
}

final _now = DateTime.now();

final _conversations = [
  Conversation(
    id: 'conv-1',
    participant: Party(
      id: 'party-0',
      displayName: 'Camila Ríos',
      photoUrl: 'https://example.com/camila.jpg',
    ),
    participantRole: ManoRole.provider,
    lastMessage: '¿A qué hora llegas?',
    lastMessageAt: _now.subtract(const Duration(minutes: 5)),
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
    lastMessage: 'Gracias, quedó perfecto',
    lastMessageAt: _now.subtract(const Duration(hours: 2)),
  ),
];

Future<_FakeConversationRepository> _pump(
  WidgetTester tester, {
  List<Conversation>? conversations,
  bool failing = false,
}) async {
  final repo = _FakeConversationRepository(
    conversations ?? _conversations,
    failing: failing,
  );
  await pumpRouterAt(
    tester,
    '/inbox',
    session: FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
    overrides: [conversationRepositoryProvider.overrideWithValue(repo)],
  );
  return repo;
}

void main() {
  testWidgets('lists conversations with snippets and relative times', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Camila Ríos'), findsOneWidget);
    expect(find.text('¿A qué hora llegas?'), findsOneWidget);
    expect(find.text('5m'), findsOneWidget);
    expect(find.text('2h'), findsOneWidget);
  });

  testWidgets('an unnamed client with no messages yet reads by role', (
    tester,
  ) async {
    await _pump(
      tester,
      conversations: [
        const Conversation(
          id: 'conv-9',
          participant: Party(id: 'c9', displayName: '', photoUrl: ''),
          participantRole: ManoRole.requester,
        ),
      ],
    );

    expect(find.text('Cliente'), findsOneWidget);
    expect(find.text('Sin mensajes aún'), findsOneWidget);
    expect(find.textContaining(RegExp(r'^\d+[mhd]$')), findsNothing);
  });

  testWidgets('shows an unread badge only where there are unread messages', (
    tester,
  ) async {
    await _pump(tester);

    expect(
      find.byKey(const Key('mano-conversation-tile-unread-badge')),
      findsOneWidget,
    );
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('pulling down refetches the conversations', (tester) async {
    final repo = await _pump(tester);
    final before = repo.calls;

    await tester.fling(find.text('Camila Ríos'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(repo.calls, before + 1);
  });

  testWidgets('an empty inbox speaks to the professional', (tester) async {
    await _pump(tester, conversations: []);

    expect(find.byType(ManoConversationTile), findsNothing);
    expect(
      find.text('Aún no tienes conversaciones con clientes'),
      findsOneWidget,
    );
  });

  testWidgets('a failed load can be retried', (tester) async {
    final repo = await _pump(tester, failing: true);

    expect(find.text('No se pudo cargar tu bandeja.'), findsOneWidget);
    repo.failing = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Camila Ríos'), findsOneWidget);
  });

  testWidgets('tapping a conversation opens its chat', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Camila Ríos'));
    await tester.pumpAndSettle();

    expect(find.byType(ManoMessageComposer), findsOneWidget);
  });
}
