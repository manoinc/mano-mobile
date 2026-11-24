import 'support_ticket_draft.dart';

/// Where a ticket stands; a closed one takes no more messages.
enum SupportTicketStatus {
  filed,
  inProgress,
  resolved,
  closed;

  bool get acceptsMessages => this != closed;
}

/// A filed support request and its radicado number.
final class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.number,
    required this.kind,
    required this.subject,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  final String id;

  /// The radicado, to quote when following up.
  final String number;
  final SupportTicketKind kind;
  final String subject;
  final String description;
  final SupportTicketStatus status;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      other is SupportTicket &&
      other.id == id &&
      other.number == number &&
      other.kind == kind &&
      other.subject == subject &&
      other.description == description &&
      other.status == status &&
      other.createdAt == createdAt;

  @override
  int get hashCode =>
      Object.hash(id, number, kind, subject, description, status, createdAt);

  @override
  String toString() => 'SupportTicket($number, $status)';
}
