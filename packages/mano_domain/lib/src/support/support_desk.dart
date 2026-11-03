import '../result.dart';
import '../shared/data_failure.dart';
import 'support_ticket.dart';
import 'support_ticket_draft.dart';

/// Files support requests (PQRS) for either side.
abstract interface class SupportDesk {
  Future<Result<SupportTicket, DataFailure>> submit(SupportTicketDraft draft);
}
