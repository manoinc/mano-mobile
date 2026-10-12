import 'package:mano_domain/mano_domain.dart';

/// One row of a chat thread as the UI draws it: confirmed, or still outgoing.
sealed class ChatThreadItem {
  const ChatThreadItem();

  String get body;
  DateTime get sentAt;
  bool get fromMe;

  /// How far my message got; `null` for theirs and for unconfirmed ones.
  MessageStatus? get status;
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

  @override
  MessageStatus? get status => message.fromMe ? message.status : null;

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
    this.failed = false,
  });

  final String localId;

  @override
  final String body;

  @override
  final DateTime sentAt;

  final bool failed;

  @override
  bool get fromMe => true;

  @override
  MessageStatus? get status => null;

  OutgoingChatItem copyWith({bool? failed}) => OutgoingChatItem(
    localId: localId,
    body: body,
    sentAt: sentAt,
    failed: failed ?? this.failed,
  );

  @override
  bool operator ==(Object other) =>
      other is OutgoingChatItem &&
      other.localId == localId &&
      other.body == body &&
      other.sentAt == sentAt &&
      other.failed == failed;

  @override
  int get hashCode => Object.hash(localId, body, sentAt, failed);
}
