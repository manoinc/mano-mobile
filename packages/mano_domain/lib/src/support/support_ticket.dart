/// Where a filed ticket stands; the gateway only answers FILED so far.
enum SupportTicketStatus { filed }

/// A filed support request and its radicado number.
final class SupportTicket {
  const SupportTicket({
    required this.number,
    required this.status,
    required this.createdAt,
  });

  /// The radicado, to quote when following up.
  final String number;
  final SupportTicketStatus status;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      other is SupportTicket &&
      other.number == number &&
      other.status == status &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(number, status, createdAt);

  @override
  String toString() => 'SupportTicket($number, $status)';
}
