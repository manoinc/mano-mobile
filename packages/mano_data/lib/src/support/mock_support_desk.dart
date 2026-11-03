import 'package:mano_domain/mano_domain.dart';

/// In-memory [SupportDesk]: numbers tickets MANO-yyyymmdd-0001 upwards.
final class MockSupportDesk implements SupportDesk {
  MockSupportDesk({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  var _filed = 0;

  @override
  Future<Result<SupportTicket, DataFailure>> submit(
    SupportTicketDraft draft,
  ) async {
    if (!draft.isValid) return Err(DataRejected(reason: '${draft.problems}'));
    final at = _now();
    _filed++;
    return Ok(
      SupportTicket(
        number: 'MANO-${_date(at)}-${'$_filed'.padLeft(4, '0')}',
        status: SupportTicketStatus.filed,
        createdAt: at,
      ),
    );
  }
}

String _date(DateTime d) =>
    '${d.year}${'${d.month}'.padLeft(2, '0')}${'${d.day}'.padLeft(2, '0')}';
