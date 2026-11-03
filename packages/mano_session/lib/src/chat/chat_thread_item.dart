import 'package:mano_domain/mano_domain.dart';

import '../media/photo_attachment.dart';
import 'photo_caption.dart';

/// One row of a chat thread as the UI draws it: confirmed, or still outgoing.
sealed class ChatThreadItem {
  const ChatThreadItem();

  String get body;
  DateTime get sentAt;
  bool get fromMe;
  bool get hasPhotos;

  /// The text to draw; empty when the photos speak for themselves.
  String get caption => visibleCaption(body, hasPhotos: hasPhotos);
}

final class ConfirmedChatItem extends ChatThreadItem {
  const ConfirmedChatItem(this.message);

  final Message message;

  @override
  String get body => message.body;

  @override
  DateTime get sentAt => message.sentAt;

  @override
  bool get fromMe => message.fromMe;

  /// Short-lived; draw them from the latest read, never keep them.
  List<String> get photoUrls => [
    for (final m in message.media)
      if (m.isImage) m.url,
  ];

  @override
  bool get hasPhotos => photoUrls.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is ConfirmedChatItem && other.message == message;

  @override
  int get hashCode => message.hashCode;
}

/// A message of mine the backend has not confirmed: pending, or [failed].
final class OutgoingChatItem extends ChatThreadItem {
  const OutgoingChatItem({
    required this.localId,
    required this.body,
    required this.sentAt,
    this.photos = const [],
    this.failed = false,
  });

  final String localId;

  @override
  final String body;

  @override
  final DateTime sentAt;

  /// Uploaded photos, drawn from their local bytes until confirmed.
  final List<PhotoAttachment> photos;

  final bool failed;

  @override
  bool get fromMe => true;

  @override
  bool get hasPhotos => photos.isNotEmpty;

  List<String> get mediaIds => [
    for (final p in photos)
      if (p.uploaded case final u?) u.id,
  ];

  OutgoingChatItem copyWith({bool? failed}) => OutgoingChatItem(
    localId: localId,
    body: body,
    sentAt: sentAt,
    photos: photos,
    failed: failed ?? this.failed,
  );

  @override
  bool operator ==(Object other) =>
      other is OutgoingChatItem &&
      other.localId == localId &&
      other.body == body &&
      other.sentAt == sentAt &&
      other.mediaIds.join(',') == mediaIds.join(',') &&
      other.failed == failed;

  @override
  int get hashCode =>
      Object.hash(localId, body, sentAt, Object.hashAll(mediaIds), failed);
}
