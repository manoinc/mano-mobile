import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

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
    expect(ticket.kind, SupportTicketKind.reclamo);
    expect(ticket.subject, 'Cobro doble');
    expect(ticket.createdAt, now);
  });

  test('each ticket gets the next number and lists newest first', () async {
    final desk = MockSupportDesk(now: () => now);
    await desk.submit(draft);
    final second = (await desk.submit(draft)).valueOrNull!;
    expect(second.number, 'MANO-20261102-0002');
    final mine = (await desk.myTickets()).valueOrNull!;
    expect(mine.map((t) => t.number), [
      'MANO-20261102-0002',
      'MANO-20261102-0001',
    ]);
  });

  test('refuses an invalid draft', () async {
    final result = await MockSupportDesk().submit(const SupportTicketDraft());
    expect(result.failureOrNull, isA<DataRejected>());
  });

  test('a thread starts empty, keeps my messages and staff replies', () async {
    final desk = MockSupportDesk(now: () => now);
    final id = (await desk.submit(draft)).valueOrNull!.id;
    expect((await desk.messages(id)).valueOrNull, isEmpty);

    await desk.send(id, ' Hola ');
    desk.reply(id, 'Buenas');

    final thread = (await desk.messages(id)).valueOrNull!;
    expect(thread.map((m) => (m.body, m.fromStaff)), [
      ('Hola', false),
      ('Buenas', true),
    ]);
  });

  test('send refuses blank, too long, unknown and closed', () async {
    final desk = MockSupportDesk(now: () => now);
    final id = (await desk.submit(draft)).valueOrNull!.id;
    expect((await desk.send(id, ' ')).failureOrNull, isA<DataRejected>());
    expect(
      (await desk.send(id, 'a' * 2001)).failureOrNull,
      isA<DataRejected>(),
    );
    expect(
      (await desk.send('nope', 'Hola')).failureOrNull,
      isA<DataNotFound>(),
    );
    desk.setStatus(id, SupportTicketStatus.closed);
    expect((await desk.send(id, 'Hola')).failureOrNull, isA<DataRejected>());
  });
}
