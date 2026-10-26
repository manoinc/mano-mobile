import '../shared/party.dart';

final class Conversation {
  const Conversation({
    required this.id,
    required this.participant,
    required this.participantRole,
    this.lastMessage = '',
    this.lastMessageAt,
    this.isOnline = false,
    this.isVerified = false,
    this.unreadCount = 0,
  });

  final String id;
  final Party participant;

  /// A `ManoRole` value: which side of the marketplace the participant is on.
  final String participantRole;
  final bool isOnline;
  final bool isVerified;

  /// Empty, with [lastMessageAt] null, until the first message.
  final String lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  /// Newest activity first; conversations without messages go last.
  static int newestFirst(Conversation a, Conversation b) =>
      switch ((a.lastMessageAt, b.lastMessageAt)) {
        (final x?, final y?) => y.compareTo(x),
        (null, null) => 0,
        (null, _) => 1,
        (_, null) => -1,
      };

  String get participantName => participant.displayName;
  String get participantPhotoUrl => participant.photoUrl;

  @override
  bool operator ==(Object other) =>
      other is Conversation &&
      other.id == id &&
      other.participant == participant &&
      other.participantRole == participantRole &&
      other.isOnline == isOnline &&
      other.isVerified == isVerified &&
      other.lastMessage == lastMessage &&
      other.lastMessageAt == lastMessageAt &&
      other.unreadCount == unreadCount;

  @override
  int get hashCode => Object.hash(
    id,
    participant,
    participantRole,
    isOnline,
    isVerified,
    lastMessage,
    lastMessageAt,
    unreadCount,
  );

  @override
  String toString() => 'Conversation($id, $participantName)';
}
