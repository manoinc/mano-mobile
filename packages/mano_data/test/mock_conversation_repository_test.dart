import 'package:mano_data/src/messaging/mock_conversation_repository.dart';
import 'package:test/test.dart';

void main() {
  group('MockConversationRepository', () {
    late MockConversationRepository repository;

    setUp(() {
      repository = MockConversationRepository();
    });

    test('conversations() returns a non-empty list', () async {
      final conversations = await repository.conversations();
      expect(conversations, isNotEmpty);
    });

    test('every unreadCount is >= 0', () async {
      final conversations = await repository.conversations();

      for (final conversation in conversations) {
        expect(
          conversation.unreadCount >= 0,
          isTrue,
          reason: 'Conversation $conversation has negative unreadCount',
        );
      }
    });

    test('at least one conversation has unreadCount == 0 and at least one has unreadCount > 0', () async {
      final conversations = await repository.conversations();

      final hasZeroUnread = conversations.any((c) => c.unreadCount == 0);
      final hasPositiveUnread = conversations.any((c) => c.unreadCount > 0);

      expect(
        hasZeroUnread,
        isTrue,
        reason: 'No conversation with unreadCount == 0 found',
      );
      expect(
        hasPositiveUnread,
        isTrue,
        reason: 'No conversation with unreadCount > 0 found',
      );
    });

    test('conversations come newest first', () async {
      final conversations = await repository.conversations();
      final times = conversations.map((c) => c.lastMessageAt).toList();
      expect(times, [...times]..sort((a, b) => b.compareTo(a)));
    });

    test('recording a message moves that thread to the front', () async {
      final oldest = (await repository.conversations()).last;

      repository.recordMessage(oldest.id, 'Hola', DateTime(2027));

      final conversations = await repository.conversations();
      expect(conversations.first.id, oldest.id);
      expect(conversations.first.lastMessage, 'Hola');
    });

    test('every participant carries an id and a role', () async {
      for (final c in await repository.conversations()) {
        expect(c.participant.id, isNotEmpty);
        expect(c.participantRole, isNotEmpty);
      }
    });
  });
}
