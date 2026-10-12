import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('Conversation', () {
    test('two conversations with different field values are unequal', () {
      final conv1 = Conversation(
        id: 'conv1',
        participant: Party(
          id: 'p-Juan',
          displayName: 'Juan',
          photoUrl: 'https://example.com/photo1.jpg',
        ),
        participantRole: ManoRole.provider,
        lastMessage: 'Hola, ¿cómo estás?',
        lastMessageAt: DateTime(2026, 1, 1, 10),
        isOnline: true,
        isVerified: true,
        unreadCount: 2,
      );
      final conv2 = Conversation(
        id: 'conv2',
        participant: Party(
          id: 'p-María',
          displayName: 'María',
          photoUrl: 'https://example.com/photo2.jpg',
        ),
        participantRole: ManoRole.provider,
        lastMessage: 'Perfecto, confirmado',
        lastMessageAt: DateTime(2026, 1, 1, 11),
        isOnline: false,
        isVerified: false,
        unreadCount: 0,
      );

      expect(conv1 == conv2, isFalse);
    });

    test('two conversations with identical field values are equal and share a hashCode', () {
      final lastMessageAt = DateTime(2026, 1, 1, 10);
      final conv1 = Conversation(
        id: 'conv1',
        participant: Party(
          id: 'p-Juan',
          displayName: 'Juan',
          photoUrl: 'https://example.com/photo1.jpg',
        ),
        participantRole: ManoRole.provider,
        lastMessage: 'Hola, ¿cómo estás?',
        lastMessageAt: lastMessageAt,
        isOnline: true,
        isVerified: true,
        unreadCount: 2,
      );
      final conv2 = Conversation(
        id: 'conv1',
        participant: Party(
          id: 'p-Juan',
          displayName: 'Juan',
          photoUrl: 'https://example.com/photo1.jpg',
        ),
        participantRole: ManoRole.provider,
        lastMessage: 'Hola, ¿cómo estás?',
        lastMessageAt: lastMessageAt,
        isOnline: true,
        isVerified: true,
        unreadCount: 2,
      );

      expect(conv1 == conv2, isTrue);
      expect(conv1.hashCode == conv2.hashCode, isTrue);
    });

    test('toString is non-empty and mentions the id', () {
      final conv = Conversation(
        id: 'conv1',
        participant: Party(
          id: 'p-Juan',
          displayName: 'Juan',
          photoUrl: 'https://example.com/photo1.jpg',
        ),
        participantRole: ManoRole.provider,
        lastMessage: 'Hola, ¿cómo estás?',
        lastMessageAt: DateTime(2026, 1, 1, 10),
      );

      expect(conv.toString(), isNotEmpty);
      expect(conv.toString(), contains('conv1'));
    });

    test('exposes the participant name, photo and role', () {
      final conv = Conversation(
        id: 'c',
        participant: const Party(
          id: 'p1',
          displayName: 'Ana',
          photoUrl: 'https://example.com/a.jpg',
        ),
        participantRole: ManoRole.provider,
        lastMessage: 'Hola',
        lastMessageAt: DateTime(2026, 1, 1),
      );

      expect(conv.participantName, 'Ana');
      expect(conv.participantPhotoUrl, 'https://example.com/a.jpg');
      expect(conv.participant.id, 'p1');
      expect(conv.participantRole, ManoRole.provider);
    });
  });
}
