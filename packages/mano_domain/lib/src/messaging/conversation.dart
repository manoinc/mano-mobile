final class Conversation {
  const Conversation({
    required this.id,
    required this.participantName,
    required this.participantPhotoUrl,
    required this.lastMessage,
    required this.lastMessageAt,
    this.isOnline = false,
    this.isVerified = false,
    this.unreadCount = 0,
  });

  final String id;
  final String participantName;
  final String participantPhotoUrl;
  final bool isOnline;
  final bool isVerified;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;

  @override
  bool operator ==(Object other) =>
      other is Conversation &&
      other.id == id &&
      other.participantName == participantName &&
      other.participantPhotoUrl == participantPhotoUrl &&
      other.isOnline == isOnline &&
      other.isVerified == isVerified &&
      other.lastMessage == lastMessage &&
      other.lastMessageAt == lastMessageAt &&
      other.unreadCount == unreadCount;

  @override
  int get hashCode => Object.hash(
        id, participantName, participantPhotoUrl, isOnline, isVerified,
        lastMessage, lastMessageAt, unreadCount,
      );

  @override
  String toString() => 'Conversation($id, $participantName)';
}
