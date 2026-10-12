import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';

/// Tests the conversation providers with a fake repository and nothing else.

final class _FakeConversationRepository implements ConversationRepository {
  _FakeConversationRepository({this.onConversations});

  final Future<List<Conversation>> Function()? onConversations;

  @override
  Future<List<Conversation>> conversations() async =>
      onConversations?.call() ?? const [];
}

final _conversation = Conversation(
  id: 'test-conversation',
  participant: const Party(
    id: 'p1',
    displayName: 'Test Participant',
    photoUrl: 'https://example.com/photo.jpg',
  ),
  participantRole: ManoRole.provider,
  isOnline: true,
  isVerified: true,
  lastMessage: 'Test message',
  lastMessageAt: DateTime(2026, 9, 27, 14, 30),
  unreadCount: 0,
);

ProviderContainer containerWith(ConversationRepository repository) {
  final container = ProviderContainer.test(
    overrides: [conversationRepositoryProvider.overrideWithValue(repository)],
  );
  return container;
}

void main() {
  test(
    'conversationsProvider resolves to the fake conversations list',
    () async {
      final container = containerWith(
        _FakeConversationRepository(
          onConversations: () async => [_conversation],
        ),
      );

      final conversations = await container.read(conversationsProvider.future);

      expect(conversations, [_conversation]);
    },
  );

  test(
    'conversationsProvider resolves to empty list when overridden',
    () async {
      final container = containerWith(
        _FakeConversationRepository(onConversations: () async => []),
      );

      final conversations = await container.read(conversationsProvider.future);

      expect(conversations, isEmpty);
    },
  );

  Conversation at(String id, DateTime when) => Conversation(
    id: id,
    participant: Party(id: 'p-$id', displayName: id, photoUrl: ''),
    participantRole: ManoRole.provider,
    lastMessage: 'x',
    lastMessageAt: when,
  );

  test(
    'conversationsProvider sorts newest first whatever the adapter does',
    () async {
      final container = containerWith(
        _FakeConversationRepository(
          onConversations: () async => [
            at('old', DateTime(2026, 1, 1)),
            at('new', DateTime(2026, 3, 1)),
            at('mid', DateTime(2026, 2, 1)),
          ],
        ),
      );

      final conversations = await container.read(conversationsProvider.future);

      expect(conversations.map((c) => c.id), ['new', 'mid', 'old']);
    },
  );

  test('conversationProvider finds one conversation by id', () async {
    final container = containerWith(
      _FakeConversationRepository(onConversations: () async => [_conversation]),
    );
    await container.read(conversationsProvider.future);

    expect(
      container.read(conversationProvider('test-conversation')),
      _conversation,
    );
    expect(container.read(conversationProvider('missing')), isNull);
  });

  test('sending in an older thread moves it to the top of the inbox', () async {
    final container = ProviderContainer.test();
    container.listen(conversationsProvider, (_, _) {});
    final before = await container.read(conversationsProvider.future);
    final oldest = before.last.id;
    container.listen(chatThreadProvider(oldest), (_, _) {});
    await container.read(chatThreadProvider(oldest).future);

    await container.read(chatThreadProvider(oldest).notifier).send('Hola');
    final after = await container.read(conversationsProvider.future);

    expect(after.first.id, oldest);
    expect(after.first.lastMessage, 'Hola');
  });
}
