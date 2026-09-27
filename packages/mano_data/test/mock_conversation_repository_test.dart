import 'package:mano_data/src/messaging/mock_conversation_repository.dart';
import 'package:test/test.dart';

void main() {
  group('MockConversationRepository', () {
    late MockConversationRepository repository;

    setUp(() {
      repository = const MockConversationRepository();
    });

    test('conversations() returns a non-empty list', () async {
      final conversations = await repository.conversations();
      expect(conversations, isNotEmpty);
    });

    test('every unreadCount is >= 0', () async {
      final conversations = await repository.conversations();

      for (final conversation in conversations) {
        expect(conversation.unreadCount >= 0, isTrue,
            reason: 'Conversation $conversation has negative unreadCount');
      }
    });

    test('at least one conversation has unreadCount == 0 and at least one has unreadCount > 0',
        () async {
      final conversations = await repository.conversations();

      final hasZeroUnread = conversations.any((c) => c.unreadCount == 0);
      final hasPositiveUnread = conversations.any((c) => c.unreadCount > 0);

      expect(hasZeroUnread, isTrue, reason: 'No conversation with unreadCount == 0 found');
      expect(hasPositiveUnread, isTrue, reason: 'No conversation with unreadCount > 0 found');
    });
  });
}
