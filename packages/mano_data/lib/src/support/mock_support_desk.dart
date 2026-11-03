import 'package:mano_domain/mano_domain.dart';

/// In-memory [SupportDesk] that numbers tickets `PQR-<year>-<sequence>`.
final class MockSupportDesk implements SupportDesk {
  MockSupportDesk({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  int _sequence = 0;

  @override
  Future<Result<SupportTicket, DataFailure>> file(
    SupportTicketDraft draft,
  ) async {
    if (draft.problems.isNotEmpty) {
      return Err(DataRejected(reason: '${draft.problems}'));
    }
    final at = _now();
    final sequence = ++_sequence;
    return Ok(
      SupportTicket(
        id: 'ticket-$sequence',
        ticketNumber: 'PQR-${at.year}-${'$sequence'.padLeft(5, '0')}',
        subject: draft.subject.trim(),
        description: draft.description.trim(),
        createdAt: at,
      ),
    );
  }
}
