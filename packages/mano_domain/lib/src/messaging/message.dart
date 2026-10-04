/// One message in a conversation, from the signed-in user's point of view.
final class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.body,
    required this.sentAt,
    required this.fromMe,
  });

  final String id;
  final String conversationId;
  final String body;
  final DateTime sentAt;
  final bool fromMe;

  @override
  bool operator ==(Object other) =>
      other is Message &&
      other.id == id &&
      other.conversationId == conversationId &&
      other.body == body &&
      other.sentAt == sentAt &&
      other.fromMe == fromMe;

  @override
  int get hashCode => Object.hash(id, conversationId, body, sentAt, fromMe);

  @override
  String toString() => 'Message($id, fromMe: $fromMe)';
}
