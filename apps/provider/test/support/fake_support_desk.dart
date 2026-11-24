import 'package:mano_session/mano_session.dart';

/// A [SupportDesk] holding a fixed set of tickets and threads; records what is sent.
class FakeSupportDesk implements SupportDesk {
  FakeSupportDesk({this.tickets = const [], this.threads = const {}});

  final List<SupportTicket> tickets;
  final Map<String, List<SupportMessage>> threads;
  final drafts = <SupportTicketDraft>[];
  final sent = <String>[];

  @override
  Future<Result<SupportTicket, DataFailure>> submit(
    SupportTicketDraft draft,
  ) async {
    drafts.add(draft);
    return Ok(tickets.first);
  }

  @override
  Future<Result<List<SupportTicket>, DataFailure>> myTickets() async =>
      Ok(tickets);

  @override
  Future<Result<List<SupportMessage>, DataFailure>> messages(
    String ticketId,
  ) async => Ok(threads[ticketId] ?? const []);

  @override
  Future<Result<SupportMessage, DataFailure>> send(
    String ticketId,
    String body,
  ) async {
    sent.add(body);
    final message = SupportMessage(
      id: 'm${sent.length}',
      fromStaff: false,
      body: body,
      sentAt: DateTime(2026, 11, 3),
    );
    threads[ticketId]?.add(message);
    return Ok(message);
  }
}

SupportTicket fakeTicket({
  String id = 't1',
  SupportTicketStatus status = SupportTicketStatus.filed,
}) => SupportTicket(
  id: id,
  number: 'MANO-20261102-0001',
  kind: SupportTicketKind.reclamo,
  subject: 'Cobro doble',
  description: 'Me cobraron dos veces el mismo lead.',
  status: status,
  createdAt: DateTime(2026, 11, 2, 9, 30),
);
