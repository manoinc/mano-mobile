import 'package:mano_domain/mano_domain.dart';

final class MockConversationRepository implements ConversationRepository {
  const MockConversationRepository();

  static final List<Conversation> _conversations = [
    Conversation(
      id: 'conv-1',
      participantName: 'Ana Gómez',
      participantPhotoUrl: 'https://i.pravatar.cc/150?u=ana-gomez',
      isOnline: true,
      isVerified: true,
      lastMessage: '¿Aún disponible para el jueves?',
      lastMessageAt: DateTime(2026, 9, 27, 14, 30),
      unreadCount: 0,
    ),
    Conversation(
      id: 'conv-2',
      participantName: 'Luis Martínez',
      participantPhotoUrl: 'https://i.pravatar.cc/150?u=luis-martinez',
      isOnline: false,
      isVerified: true,
      lastMessage: 'Perfecto, te veo mañana.',
      lastMessageAt: DateTime(2026, 9, 25, 18, 45),
      unreadCount: 2,
    ),
    Conversation(
      id: 'conv-3',
      participantName: 'María Rodríguez',
      participantPhotoUrl: 'https://i.pravatar.cc/150?u=maria-rodriguez',
      isOnline: true,
      isVerified: false,
      lastMessage: 'El precio te parece bien?',
      lastMessageAt: DateTime(2026, 9, 26, 10, 15),
      unreadCount: 0,
    ),
    Conversation(
      id: 'conv-4',
      participantName: 'Fernando López',
      participantPhotoUrl: 'https://i.pravatar.cc/150?u=fernando-lopez',
      isOnline: false,
      isVerified: true,
      lastMessage: 'Listo, tomo nota de eso.',
      lastMessageAt: DateTime(2026, 9, 24, 16, 20),
      unreadCount: 5,
    ),
    Conversation(
      id: 'conv-5',
      participantName: 'Catalina Pérez',
      participantPhotoUrl: 'https://i.pravatar.cc/150?u=catalina-perez',
      isOnline: true,
      isVerified: false,
      lastMessage: 'Gracias por tu ayuda, muy profesional.',
      lastMessageAt: DateTime(2026, 9, 23, 9, 00),
      unreadCount: 1,
    ),
    Conversation(
      id: 'conv-6',
      participantName: 'Jorge Sánchez',
      participantPhotoUrl: 'https://i.pravatar.cc/150?u=jorge-sanchez',
      isOnline: false,
      isVerified: false,
      lastMessage: 'Cuándo puedo pasar por tu oficina?',
      lastMessageAt: DateTime(2026, 9, 20, 11, 30),
      unreadCount: 0,
    ),
  ];

  @override
  Future<List<Conversation>> conversations() async => _conversations;
}
