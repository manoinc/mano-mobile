import 'package:flutter_test/flutter_test.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

void main() {
  final now = DateTime(2026, 11, 2, 9, 30);
  const draft = SupportTicketDraft(
    kind: SupportTicketKind.reclamo,
    subject: 'Cobro doble',
    description: 'Me descontaron dos veces los coins del mismo lead.',
  );

  test('files a ticket with a radicado and FILED status', () async {
    final desk = MockSupportDesk(now: () => now);

    final ticket = (await desk.submit(draft)).valueOrNull!;

    expect(ticket.number, 'MANO-20261102-0001');
    expect(ticket.status, SupportTicketStatus.filed);
    expect(ticket.createdAt, now);
  });

  test('each ticket gets the next number', () async {
    final desk = MockSupportDesk(now: () => now);
    await desk.submit(draft);
    final second = (await desk.submit(draft)).valueOrNull!;
    expect(second.number, 'MANO-20261102-0002');
  });

  test('refuses an invalid draft', () async {
    final result = await MockSupportDesk().submit(const SupportTicketDraft());
    expect(result.failureOrNull, isA<DataRejected>());
  });
}
