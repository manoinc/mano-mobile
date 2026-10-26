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

GatewayConversationRepository _repo(MockClientHandler handler) =>
    GatewayConversationRepository(
      GatewayTransport(_config, httpClient: MockClient(handler)),
      viewerId: () => 'me',
    );

http.Response _data(Object data) =>
    http.Response(jsonEncode({'data': data}), 200);

Map<String, Object?> _participant(
  String id,
  String role, {
  String name = '',
  String? photo,
}) => {'role': role, 'profileId': id, 'displayName': name, 'photoUrl': photo};

void main() {
  test('maps myConversations onto the other participant', () async {
    final repo = _repo((r) async {
      expect(jsonDecode(r.body)['query'], contains('myConversations'));
      return _data({
        'myConversations': [
          {
            'id': 'c1',
            'kind': 'DIRECT',
            'unreadCount': 3,
            'participants': [
              _participant('me', 'CLIENT'),
              _participant('w1', 'WORKER', name: 'Ana', photo: 'http://p/a'),
            ],
            'lastMessage': {
              'id': 'm1',
              'conversationId': 'c1',
              'sender': _participant('w1', 'WORKER'),
              'content': 'Hola',
              'sentAt': '2026-10-25T14:30:00Z',
              'readAt': null,
            },
          },
        ],
      });
    });

    expect(await repo.conversations(), [
      Conversation(
        id: 'c1',
        participant: const Party(
          id: 'w1',
          displayName: 'Ana',
          photoUrl: 'http://p/a',
        ),
        participantRole: ManoRole.provider,
        lastMessage: 'Hola',
        lastMessageAt: DateTime.utc(2026, 10, 25, 14, 30).toLocal(),
        unreadCount: 3,
      ),
    ]);
  });

  test(
    'a client participant is a requester; missing photo and message are empty',
    () async {
      final repo = _repo(
        (_) async => _data({
          'myConversations': [
            {
              'id': 'c2',
              'kind': 'DIRECT',
              'unreadCount': 0,
              'participants': [
                _participant('c9', 'CLIENT'),
                _participant('me', 'WORKER'),
              ],
              'lastMessage': null,
            },
          ],
        }),
      );

      final conversation = (await repo.conversations()).single;

      expect(
        conversation.participant,
        const Party(id: 'c9', displayName: '', photoUrl: ''),
      );
      expect(conversation.participantRole, ManoRole.requester);
      expect(conversation.lastMessage, '');
      expect(conversation.lastMessageAt, isNull);
    },
  );

  test('open posts openConversation with a job reference', () async {
    final repo = _repo((r) async {
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      expect(body['query'], contains('openConversation'));
      expect(body['variables'], {
        'reference': {'jobId': 'j1'},
      });
      return _data({
        'openConversation': {
          'id': 'c7',
          'unreadCount': 0,
          'participants': [
            _participant('me', 'CLIENT'),
            _participant('w1', 'WORKER'),
          ],
          'lastMessage': null,
        },
      });
    });

    final opened = (await repo.open(jobId: 'j1')).valueOrNull!;

    expect(opened.id, 'c7');
    expect(opened.participant.id, 'w1');
    expect(opened.participantRole, ManoRole.provider);
    expect(opened.lastMessageAt, isNull);
  });

  test('open with a worker sends withWorkerId', () async {
    final repo = _repo((r) async {
      expect((jsonDecode(r.body) as Map)['variables'], {
        'reference': {'withWorkerId': 'w1'},
      });
      return _data({
        'openConversation': {
          'id': 'c8',
          'unreadCount': 0,
          'participants': [_participant('w1', 'WORKER')],
          'lastMessage': null,
        },
      });
    });

    expect((await repo.open(withWorkerId: 'w1')).valueOrNull?.id, 'c8');
  });

  test('a refused open is a DataFailure', () async {
    final repo = _repo(
      (_) async => http.Response(
        jsonEncode({
          'errors': [
            {'message': 'PermissionDenied: not your job'},
          ],
        }),
        200,
      ),
    );

    expect(await repo.open(jobId: 'j1'), isA<Err<Conversation, DataFailure>>());
  });

  test('a gateway error surfaces as GatewayRejected', () async {
    final repo = _repo(
      (_) async => http.Response(
        jsonEncode({
          'errors': [
            {'message': 'authentication required'},
          ],
        }),
        200,
      ),
    );

    expect(repo.conversations(), throwsA(isA<GatewayRejected>()));
  });
}
