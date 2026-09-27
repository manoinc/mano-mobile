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
  participantName: 'Test Participant',
  participantPhotoUrl: 'https://example.com/photo.jpg',
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
  test('conversationsProvider resolves to the fake conversations list', () async {
    final container = containerWith(
      _FakeConversationRepository(
        onConversations: () async => [_conversation],
      ),
    );

    final conversations = await container.read(conversationsProvider.future);

    expect(conversations, [_conversation]);
  });

  test('conversationsProvider resolves to empty list when overridden', () async {
    final container = containerWith(
      _FakeConversationRepository(onConversations: () async => []),
    );

    final conversations = await container.read(conversationsProvider.future);

    expect(conversations, isEmpty);
  });
}
