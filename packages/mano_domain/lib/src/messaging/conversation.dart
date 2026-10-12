import '../shared/party.dart';

final class Conversation {
  const Conversation({
    required this.id,
    required this.participant,
    required this.participantRole,
    required this.lastMessage,
    required this.lastMessageAt,
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
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;

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
