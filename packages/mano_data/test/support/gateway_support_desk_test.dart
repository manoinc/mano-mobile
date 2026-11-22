import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

const _config = ManoConfig(
  gatewayGraphQlUrl: 'http://gw/graphql',
  appRole: ManoRole.requester,
);

GatewaySupportDesk _desk(MockClientHandler handler) => GatewaySupportDesk(
  GatewayTransport(_config, httpClient: MockClient(handler)),
);

http.Response _data(Object data) =>
    http.Response(jsonEncode({'data': data}), 200);

http.Response _error(String message) => http.Response(
  jsonEncode({
    'errors': [
      {'message': message},
    ],
  }),
  200,
);

Map<String, Object?> _ticket({String status = 'IN_PROGRESS'}) => {
  'id': 't1',
  'ticketNumber': 'MANO-20261102-0001',
  'kind': 'RECLAMO',
  'subject': 'Cobro doble',
  'description': 'Me cobraron dos veces.',
  'status': status,
  'createdAt': '2026-11-02T09:30:00Z',
  'updatedAt': '2026-11-02T10:00:00Z',
  'resolvedAt': null,
};

final _parsed = SupportTicket(
  id: 't1',
  number: 'MANO-20261102-0001',
  kind: SupportTicketKind.reclamo,
  subject: 'Cobro doble',
  description: 'Me cobraron dos veces.',
  status: SupportTicketStatus.inProgress,
  createdAt: DateTime.utc(2026, 11, 2, 9, 30).toLocal(),
);

const _draft = SupportTicketDraft(
  kind: SupportTicketKind.reclamo,
  subject: ' Cobro doble ',
  description: 'Me cobraron dos veces.',
);

void main() {
  test('submit sends the trimmed draft and parses the ticket', () async {
    final desk = _desk((r) async {
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      expect(body['query'], contains('createSupportTicket'));
      expect(body['query'], contains(r'$input: SupportTicketInput!'));
      expect(body['variables'], {
        'input': {
          'kind': 'RECLAMO',
          'subject': 'Cobro doble',
          'description': 'Me cobraron dos veces.',
        },
      });
      return _data({'createSupportTicket': _ticket()});
    });
    expect((await desk.submit(_draft)).valueOrNull, _parsed);
  });

  test('submit refuses an invalid draft without calling', () async {
    final desk = _desk((r) async => fail('no call expected'));
    final result = await desk.submit(const SupportTicketDraft());
    expect(result.failureOrNull, isA<DataRejected>());
  });

  test('maps every kind and status', () async {
    final wires = [
      for (final k in ['PETICION', 'QUEJA', 'RECLAMO', 'SUGERENCIA'])
        for (final s in ['FILED', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'])
          {..._ticket(status: s), 'kind': k},
    ];
    final desk = _desk(
      (r) async => _data({
        'mySupportTickets': {'items': wires},
      }),
    );
    final tickets = (await desk.myTickets()).valueOrNull!;
    expect(
      tickets.map((t) => t.kind).toSet(),
      SupportTicketKind.values.toSet(),
    );
    expect(
      tickets.map((t) => t.status).toSet(),
      SupportTicketStatus.values.toSet(),
    );
    expect(tickets[1].status, SupportTicketStatus.inProgress);
    expect(tickets[4].kind, SupportTicketKind.queja);
  });

  test('myTickets pages the first 50 and parses items', () async {
    final desk = _desk((r) async {
      final query = jsonDecode(r.body)['query'] as String;
      expect(query, contains('mySupportTickets(page: {first: 50})'));
      return _data({
        'mySupportTickets': {
          'items': [_ticket()],
        },
      });
    });
    expect((await desk.myTickets()).valueOrNull, [_parsed]);
  });

  test('messages asks for the ticket and parses senders', () async {
    final desk = _desk((r) async {
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      expect(body['query'], contains('supportMessages'));
      expect(body['variables'], {'ticketId': 't1'});
      return _data({
        'supportMessages': {
          'items': [
            {
              'id': 'm1',
              'senderIsStaff': true,
              'body': 'Hola',
              'createdAt': '2026-11-02T11:00:00Z',
            },
          ],
        },
      });
    });
    expect((await desk.messages('t1')).valueOrNull, [
      SupportMessage(
        id: 'm1',
        fromStaff: true,
        body: 'Hola',
        sentAt: DateTime.utc(2026, 11, 2, 11).toLocal(),
      ),
    ]);
  });

  test('send posts the trimmed body', () async {
    final desk = _desk((r) async {
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      expect(body['query'], contains('sendSupportMessage'));
      expect(body['variables'], {'ticketId': 't1', 'body': 'Gracias'});
      return _data({
        'sendSupportMessage': {
          'id': 'm2',
          'senderIsStaff': false,
          'body': 'Gracias',
          'createdAt': '2026-11-02T12:00:00Z',
        },
      });
    });
    final sent = (await desk.send('t1', ' Gracias ')).valueOrNull!;
    expect(sent.fromStaff, isFalse);
    expect(sent.body, 'Gracias');
  });

  test('send refuses a blank body without calling', () async {
    final desk = _desk((r) async => fail('no call expected'));
    expect((await desk.send('t1', '  ')).failureOrNull, isA<DataRejected>());
  });

  test('a closed ticket refusal becomes DataRejected', () async {
    final desk = _desk(
      (r) async => _error('FailedPrecondition: ticket is closed'),
    );
    expect((await desk.send('t1', 'Hola')).failureOrNull, isA<DataRejected>());
  });

  test('NotFound and an outage map to their failures', () async {
    final missing = _desk((r) async => _error('NotFound: ticket'));
    expect((await missing.messages('x')).failureOrNull, isA<DataNotFound>());
    final down = _desk((r) async => http.Response('', 503));
    expect((await down.myTickets()).failureOrNull, isA<DataUnavailable>());
  });
}
