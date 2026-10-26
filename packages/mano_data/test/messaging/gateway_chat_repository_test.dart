import 'dart:async';
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

Map<String, dynamic> _body(http.Request r) =>
    jsonDecode(r.body) as Map<String, dynamic>;

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

Map<String, Object?> _message(
  String id, {
  String sender = 'w1',
  String content = 'Hola',
  String sentAt = '2026-10-25T14:30:00Z',
  String? readAt,
}) => {
  'id': id,
  'conversationId': 'c1',
  'sender': {
    'role': sender == 'me' ? 'CLIENT' : 'WORKER',
    'profileId': sender,
    'displayName': '',
    'photoUrl': null,
  },
  'content': content,
  'sentAt': sentAt,
  'readAt': readAt,
};

final class _Subscriptions {
  final controller = StreamController<Map<String, Object?>>();
  String? document;
  Map<String, Object?>? variables;

  Stream<Map<String, Object?>> subscribe(
    String document,
    Map<String, Object?> variables,
  ) {
    this.document = document;
    this.variables = variables;
    return controller.stream;
  }
}

GatewayChatRepository _repo(
  MockClientHandler handler, {
  _Subscriptions? subscriptions,
}) => GatewayChatRepository(
  GatewayTransport(_config, httpClient: MockClient(handler)),
  subscribe: (subscriptions ?? _Subscriptions()).subscribe,
  viewerId: () => 'me',
);

void main() {
  test('messages reads the first page and returns it oldest first', () async {
    final repo = _repo((r) async {
      expect(_body(r)['variables'], {'id': 'c1'});
      expect(_body(r)['query'], contains('messages(page: {first: 50})'));
      return _data({
        'conversation': {
          'messages': {
            'items': [
              _message('m2', sentAt: '2026-10-25T15:00:00Z'),
              _message(
                'm1',
                sender: 'me',
                content: 'Buenas',
                readAt: '2026-10-25T14:40:00Z',
              ),
            ],
          },
        },
      });
    });

    expect(await repo.messages('c1'), [
      Message(
        id: 'm1',
        conversationId: 'c1',
        body: 'Buenas',
        sentAt: DateTime.utc(2026, 10, 25, 14, 30).toLocal(),
        fromMe: true,
        status: MessageStatus.read,
      ),
      Message(
        id: 'm2',
        conversationId: 'c1',
        body: 'Hola',
        sentAt: DateTime.utc(2026, 10, 25, 15).toLocal(),
        fromMe: false,
        status: MessageStatus.delivered,
      ),
    ]);
  });

  test(
    'a sentAt with an offset arrives as the same instant in local time',
    () async {
      final repo = _repo(
        (_) async => _data({
          'conversation': {
            'messages': {
              'items': [_message('m1', sentAt: '2026-10-25T20:31:00-05:00')],
            },
          },
        }),
      );

      final sentAt = (await repo.messages('c1')).single.sentAt;

      expect(sentAt.isUtc, isFalse);
      expect(sentAt, DateTime.utc(2026, 10, 26, 1, 31).toLocal());
    },
  );

  test('a conversation without messages is an empty thread', () async {
    final repo = _repo(
      (_) async => _data({
        'conversation': {'messages': null},
      }),
    );

    expect(await repo.messages('c1'), isEmpty);
  });

  test('watch subscribes to messageAdded and maps each message', () async {
    final subscriptions = _Subscriptions();
    final repo = _repo(
      (_) async => fail('no HTTP'),
      subscriptions: subscriptions,
    );

    final next = repo.watch('c1').first;
    subscriptions.controller.add({'messageAdded': _message('m9')});

    expect(subscriptions.document, contains('messageAdded'));
    expect(subscriptions.variables, {'conversationId': 'c1'});
    expect((await next).id, 'm9');
  });

  test('send posts sendMessage and returns my message', () async {
    final repo = _repo((r) async {
      expect(_body(r)['variables'], {'id': 'c1', 'content': 'Hola'});
      return _data({'sendMessage': _message('m5', sender: 'me')});
    });

    final result = await repo.send('c1', 'Hola');

    final message = (result as Ok<Message, DataFailure>).value;
    expect(message.id, 'm5');
    expect(message.fromMe, isTrue);
    expect(message.status, MessageStatus.delivered);
  });

  test('a refused send is a DataFailure', () async {
    final repo = _repo((_) async => _error('PermissionDenied: not yours'));

    expect(await repo.send('c1', 'Hola'), isA<Err<Message, DataFailure>>());
  });

  test('markRead posts markConversationRead', () async {
    final repo = _repo((r) async {
      expect(_body(r)['query'], contains('markConversationRead'));
      expect(_body(r)['variables'], {'id': 'c1'});
      return _data({'markConversationRead': true});
    });

    expect((await repo.markRead('c1')).isOk, isTrue);
  });
}
