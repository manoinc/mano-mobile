import '../media/media_attachment.dart';

/// How far one of my messages has travelled; theirs stay [sent].
enum MessageStatus { sent, delivered, read }

/// One message in a conversation, from the signed-in user's point of view.
final class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.body,
    required this.sentAt,
    required this.fromMe,
    this.status = MessageStatus.sent,
    this.media = const [],
  });

  final String id;
  final String conversationId;
  final String body;
  final DateTime sentAt;
  final bool fromMe;
  final MessageStatus status;

  /// Photos sent with the message, in order.
  final List<MediaAttachment> media;

  Message copyWith({MessageStatus? status}) => Message(
    id: id,
    conversationId: conversationId,
    body: body,
    sentAt: sentAt,
    fromMe: fromMe,
    status: status ?? this.status,
    media: media,
  );

  @override
  bool operator ==(Object other) =>
      other is Message &&
      other.id == id &&
      other.conversationId == conversationId &&
      other.body == body &&
      other.sentAt == sentAt &&
      other.fromMe == fromMe &&
      other.status == status &&
      _sameMedia(other.media, media);

  @override
  int get hashCode => Object.hash(
    id,
    conversationId,
    body,
    sentAt,
    fromMe,
    status,
    Object.hashAll(media),
  );

  @override
  String toString() => 'Message($id, fromMe: $fromMe)';
}

bool _sameMedia(List<MediaAttachment> a, List<MediaAttachment> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
