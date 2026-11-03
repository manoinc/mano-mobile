import '../result.dart';
import '../shared/data_failure.dart';
import 'support_ticket.dart';

/// Where either app files a request to Mano support (gateway: `createSupportTicket`).
abstract interface class SupportDesk {
  Future<Result<SupportTicket, DataFailure>> file(SupportTicketDraft draft);
}
