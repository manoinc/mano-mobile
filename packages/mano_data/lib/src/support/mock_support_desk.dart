import 'package:mano_domain/mano_domain.dart';

/// In-memory [SupportDesk]: numbers tickets MANO-yyyymmdd-0001 upwards.
final class MockSupportDesk implements SupportDesk {
  MockSupportDesk({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final _tickets = <SupportTicket>[];
  final _threads = <String, List<SupportMessage>>{};

  @override
  Future<Result<SupportTicket, DataFailure>> submit(
    SupportTicketDraft draft,
  ) async {
    if (!draft.isValid) return Err(DataRejected(reason: '${draft.problems}'));
    final at = _now();
    final ticket = SupportTicket(
      id: 't${_tickets.length + 1}',
      number: 'MANO-${_date(at)}-${'${_tickets.length + 1}'.padLeft(4, '0')}',
      kind: draft.kind,
      subject: draft.subject.trim(),
      description: draft.description.trim(),
      status: SupportTicketStatus.filed,
      createdAt: at,
    );
    _tickets.add(ticket);
    _threads[ticket.id] = [];
    return Ok(ticket);
  }

  @override
  Future<Result<List<SupportTicket>, DataFailure>> myTickets() async =>
      Ok(_tickets.reversed.toList());

  @override
  Future<Result<List<SupportMessage>, DataFailure>> messages(
    String ticketId,
  ) async => switch (_threads[ticketId]) {
    final thread? => Ok(List.of(thread)),
    null => const Err(DataNotFound()),
  };

  @override
  Future<Result<SupportMessage, DataFailure>> send(
    String ticketId,
    String body,
  ) async {
    final index = _tickets.indexWhere((t) => t.id == ticketId);
    if (index < 0) return const Err(DataNotFound());
    if (!isValidSupportMessage(body) ||
        !_tickets[index].status.acceptsMessages) {
      return const Err(DataRejected());
    }
    return Ok(_add(ticketId, fromStaff: false, body: body.trim()));
  }

  /// Test hook: what a staff reply would add.
  SupportMessage reply(String ticketId, String body) =>
      _add(ticketId, fromStaff: true, body: body);

  /// Test hook: moves a ticket to [status].
  void setStatus(String ticketId, SupportTicketStatus status) {
    final i = _tickets.indexWhere((t) => t.id == ticketId);
    final t = _tickets[i];
    _tickets[i] = SupportTicket(
      id: t.id,
      number: t.number,
      kind: t.kind,
      subject: t.subject,
      description: t.description,
      status: status,
      createdAt: t.createdAt,
    );
  }

  SupportMessage _add(
    String ticketId, {
    required bool fromStaff,
    required String body,
  }) {
    final thread = _threads[ticketId]!;
    final message = SupportMessage(
      id: 'm${thread.length + 1}',
      fromStaff: fromStaff,
      body: body,
      sentAt: _now(),
    );
    thread.add(message);
    return message;
  }
}

String _date(DateTime d) =>
    '${d.year}${'${d.month}'.padLeft(2, '0')}${'${d.day}'.padLeft(2, '0')}';
