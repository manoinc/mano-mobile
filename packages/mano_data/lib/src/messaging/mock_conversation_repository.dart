import 'package:mano_domain/mano_domain.dart';

final class MockConversationRepository implements ConversationRepository {
  MockConversationRepository() : _conversations = [..._fixtures];

  final List<Conversation> _conversations;

  static final List<Conversation> _fixtures = [
    Conversation(
      id: 'conv-1',
      participantName: 'Ana Gómez',
      participantPhotoUrl: 'https://randomuser.me/api/portraits/women/44.jpg',
      isOnline: true,
      isVerified: true,
      lastMessage: '¿Aún disponible para el jueves?',
      lastMessageAt: DateTime(2026, 9, 27, 14, 30),
      unreadCount: 0,
    ),
    Conversation(
      id: 'conv-2',
      participantName: 'Luis Martínez',
      participantPhotoUrl: 'https://randomuser.me/api/portraits/men/76.jpg',
      isOnline: false,
      isVerified: true,
      lastMessage: 'Perfecto, te veo mañana.',
      lastMessageAt: DateTime(2026, 9, 25, 18, 45),
      unreadCount: 2,
    ),
    Conversation(
      id: 'conv-3',
      participantName: 'María Rodríguez',
      participantPhotoUrl: 'https://randomuser.me/api/portraits/women/58.jpg',
      isOnline: true,
      isVerified: false,
      lastMessage: 'El precio te parece bien?',
      lastMessageAt: DateTime(2026, 9, 26, 10, 15),
      unreadCount: 0,
    ),
    Conversation(
      id: 'conv-4',
      participantName: 'Fernando López',
      participantPhotoUrl: 'https://randomuser.me/api/portraits/men/12.jpg',
      isOnline: false,
      isVerified: true,
      lastMessage: 'Listo, tomo nota de eso.',
      lastMessageAt: DateTime(2026, 9, 24, 16, 20),
      unreadCount: 5,
    ),
    Conversation(
      id: 'conv-5',
      participantName: 'Catalina Pérez',
      participantPhotoUrl: 'https://randomuser.me/api/portraits/women/33.jpg',
      isOnline: true,
      isVerified: false,
      lastMessage: 'Gracias por tu ayuda, muy profesional.',
      lastMessageAt: DateTime(2026, 9, 23, 9, 00),
      unreadCount: 1,
    ),
    Conversation(
      id: 'conv-6',
      participantName: 'Jorge Sánchez',
      participantPhotoUrl: 'https://randomuser.me/api/portraits/men/89.jpg',
      isOnline: false,
      isVerified: false,
      lastMessage: 'Cuándo puedo pasar por tu oficina?',
      lastMessageAt: DateTime(2026, 9, 20, 11, 30),
      unreadCount: 0,
    ),
  ];

  @override
  Future<List<Conversation>> conversations() async => List.of(_conversations);

  /// Called by [MockChatRepository] when a thread is opened.
  void markRead(String id) => _update(id, (c) => _copy(c, unreadCount: 0));

  /// Called by [MockChatRepository] when a message is sent or received.
  void recordMessage(String id, String body, DateTime at) =>
      _update(id, (c) => _copy(c, lastMessage: body, lastMessageAt: at));

  void _update(String id, Conversation Function(Conversation) change) {
    final index = _conversations.indexWhere((c) => c.id == id);
    if (index >= 0) _conversations[index] = change(_conversations[index]);
  }

  static Conversation _copy(
    Conversation c, {
    int? unreadCount,
    String? lastMessage,
    DateTime? lastMessageAt,
  }) => Conversation(
    id: c.id,
    participantName: c.participantName,
    participantPhotoUrl: c.participantPhotoUrl,
    isOnline: c.isOnline,
    isVerified: c.isVerified,
    lastMessage: lastMessage ?? c.lastMessage,
    lastMessageAt: lastMessageAt ?? c.lastMessageAt,
    unreadCount: unreadCount ?? c.unreadCount,
  );
}
