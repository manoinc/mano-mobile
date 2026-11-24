const int supportMessageMaxLength = 2000;

/// Whether [body] can be sent: non-empty once trimmed, within the limit.
bool isValidSupportMessage(String body) {
  final length = body.trim().length;
  return length > 0 && length <= supportMessageMaxLength;
}

/// One message in a ticket's thread; [fromStaff] marks Mano's replies.
final class SupportMessage {
  const SupportMessage({
    required this.id,
    required this.fromStaff,
    required this.body,
    required this.sentAt,
  });

  final String id;
  final bool fromStaff;
  final String body;
  final DateTime sentAt;

  @override
  bool operator ==(Object other) =>
      other is SupportMessage &&
      other.id == id &&
      other.fromStaff == fromStaff &&
      other.body == body &&
      other.sentAt == sentAt;

  @override
  int get hashCode => Object.hash(id, fromStaff, body, sentAt);

  @override
  String toString() => 'SupportMessage($id, staff: $fromStaff)';
}
