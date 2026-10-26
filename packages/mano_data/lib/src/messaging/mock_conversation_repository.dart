import 'package:mano_domain/mano_domain.dart';

final class MockConversationRepository implements ConversationRepository {
  MockConversationRepository() : _conversations = [..._fixtures] {
    _sort();
  }

  final List<Conversation> _conversations;

  static final List<Conversation> _fixtures = [
    Conversation(
      id: 'conv-1',
      participant: Party(
        id: 'party-1',
        displayName: 'Ana Gómez',
        photoUrl: 'https://randomuser.me/api/portraits/women/44.jpg',
      ),
      participantRole: ManoRole.provider,
      isOnline: true,
      isVerified: true,
      lastMessage: '¿Aún disponible para el jueves?',
      lastMessageAt: DateTime(2026, 9, 27, 14, 30),
      unreadCount: 0,
    ),
    Conversation(
      id: 'conv-2',
      participant: Party(
        id: 'party-2',
        displayName: 'Luis Martínez',
        photoUrl: 'https://randomuser.me/api/portraits/men/76.jpg',
      ),
      participantRole: ManoRole.provider,
      isOnline: false,
      isVerified: true,
      lastMessage: 'Perfecto, te veo mañana.',
      lastMessageAt: DateTime(2026, 9, 25, 18, 45),
      unreadCount: 2,
    ),
    Conversation(
      id: 'conv-3',
      participant: Party(
        id: 'party-3',
        displayName: 'María Rodríguez',
        photoUrl: 'https://randomuser.me/api/portraits/women/58.jpg',
      ),
      participantRole: ManoRole.provider,
      isOnline: true,
      isVerified: false,
      lastMessage: 'El precio te parece bien?',
      lastMessageAt: DateTime(2026, 9, 26, 10, 15),
      unreadCount: 0,
    ),
    Conversation(
      id: 'conv-4',
      participant: Party(
        id: 'party-4',
        displayName: 'Fernando López',
        photoUrl: 'https://randomuser.me/api/portraits/men/12.jpg',
      ),
      participantRole: ManoRole.requester,
      isOnline: false,
      isVerified: true,
      lastMessage: 'Listo, tomo nota de eso.',
      lastMessageAt: DateTime(2026, 9, 24, 16, 20),
      unreadCount: 5,
    ),
    Conversation(
      id: 'conv-5',
      participant: Party(
        id: 'party-5',
        displayName: 'Catalina Pérez',
        photoUrl: 'https://randomuser.me/api/portraits/women/33.jpg',
      ),
      participantRole: ManoRole.requester,
      isOnline: true,
      isVerified: false,
      lastMessage: 'Gracias por tu ayuda, muy profesional.',
      lastMessageAt: DateTime(2026, 9, 23, 9, 00),
      unreadCount: 1,
    ),
    Conversation(
      id: 'conv-6',
      participant: Party(
        id: 'party-6',
        displayName: 'Jorge Sánchez',
        photoUrl: 'https://randomuser.me/api/portraits/men/89.jpg',
      ),
      participantRole: ManoRole.requester,
      isOnline: false,
      isVerified: false,
      lastMessage: 'Cuándo puedo pasar por tu oficina?',
      lastMessageAt: DateTime(2026, 9, 20, 11, 30),
      unreadCount: 0,
    ),
  ];

  @override
  Future<List<Conversation>> conversations() async => List.of(_conversations);

  /// Offline the job's other side is unknown, so a job chat's participant is a blank professional.
  @override
  Future<Result<Conversation, DataFailure>> open({
    String? withWorkerId,
    String? jobId,
  }) async {
    if ((withWorkerId == null) == (jobId == null)) {
      return const Err(DataRejected(reason: 'give a worker or a job'));
    }
    final id = jobId != null ? 'conv-job-$jobId' : 'conv-with-$withWorkerId';
    final existing = _conversations.where((c) => c.id == id).firstOrNull;
    if (existing != null) return Ok(existing);
    final opened = Conversation(
      id: id,
      participant: Party(id: withWorkerId ?? '', displayName: '', photoUrl: ''),
      participantRole: ManoRole.provider,
    );
    _conversations.add(opened);
    _sort();
    return Ok(opened);
  }

  /// Called by [MockChatRepository] when a thread is opened.
  void markRead(String id) => _update(id, (c) => _copy(c, unreadCount: 0));

  /// Called by [MockChatRepository] when a message is sent or received.
  void recordMessage(String id, String body, DateTime at) {
    _update(id, (c) => _copy(c, lastMessage: body, lastMessageAt: at));
    _sort();
  }

  void _sort() => _conversations.sort(Conversation.newestFirst);

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
    participant: c.participant,
    participantRole: c.participantRole,
    isOnline: c.isOnline,
    isVerified: c.isVerified,
    lastMessage: lastMessage ?? c.lastMessage,
    lastMessageAt: lastMessageAt ?? c.lastMessageAt,
    unreadCount: unreadCount ?? c.unreadCount,
  );
}
