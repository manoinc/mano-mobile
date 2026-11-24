import '../result.dart';
import '../shared/data_failure.dart';
import 'support_message.dart';
import 'support_ticket.dart';
import 'support_ticket_draft.dart';

/// Files support requests (PQRS) and talks them through with Mano's staff.
abstract interface class SupportDesk {
  Future<Result<SupportTicket, DataFailure>> submit(SupportTicketDraft draft);

  /// My tickets, newest first.
  Future<Result<List<SupportTicket>, DataFailure>> myTickets();

  /// A ticket's thread, oldest first.
  Future<Result<List<SupportMessage>, DataFailure>> messages(String ticketId);

  /// Adds my message to the thread; refused when blank, too long or closed.
  Future<Result<SupportMessage, DataFailure>> send(
    String ticketId,
    String body,
  );
}
