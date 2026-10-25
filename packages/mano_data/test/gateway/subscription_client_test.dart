import 'dart:async';
import 'dart:convert';

import 'package:mano_data/mano_data.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

const _url = 'ws://gw/subscription';
const _doc = 'subscription { ping }';

/// One in-memory socket: what the client sent, and a way to answer.
final class _Socket {
  _Socket(this.uri) {
    controller.local.stream.listen(
      (raw) => sent.add(jsonDecode(raw as String) as Map<String, dynamic>),
      onDone: () => closedByClient = true,
    );
  }

  final Uri uri;
  final controller = StreamChannelController<dynamic>();
  final List<Map<String, dynamic>> sent = [];
  var closedByClient = false;

  void reply(Map<String, Object?> frame) =>
      controller.local.sink.add(jsonEncode(frame));

  void drop() => controller.local.sink.close();

  List<Map<String, dynamic>> ofType(String type) =>
      sent.where((f) => f['type'] == type).toList();
}

final class _Harness {
  _Harness({List<String?> tokens = const ['t1']}) : _tokens = [...tokens];

  final List<String?> _tokens;
  final List<_Socket> sockets = [];
  final List<Duration> waits = [];

  late final client = SubscriptionClient(
    _url,
    accessToken: () async =>
        _tokens.length > 1 ? _tokens.removeAt(0) : _tokens.first,
    connect: (uri) {
      final socket = _Socket(uri);
      sockets.add(socket);
      return socket.controller.foreign;
    },
    wait: (d) async => waits.add(d),
  );

  _Socket get last => sockets.last;

  /// Subscribes and acknowledges the connection; returns what arrives.
  Future<(List<Object?>, StreamSubscription<Map<String, Object?>>)> open({
    Map<String, Object?> variables = const {},
  }) async {
    final events = <Object?>[];
    final sub = client
        .subscribe(_doc, variables)
        .listen(
          events.add,
          onError: events.add,
          onDone: () => events.add(#done),
        );
    await pumpEventQueue();
    if (_acked.add(last)) {
      last.reply({'type': 'connection_ack'});
      await pumpEventQueue();
    }
    return (events, sub);
  }

  final Set<_Socket> _acked = {};
}

void main() {
  test(
    'connects lazily and sends the bearer token in connection_init',
    () async {
      final h = _Harness();
      expect(h.sockets, isEmpty);

      final sub = h.client.subscribe(_doc, const {}).listen((_) {});
      await pumpEventQueue();

      expect(h.sockets, hasLength(1));
      expect(h.last.uri, Uri.parse(_url));
      expect(h.last.sent.first, {
        'type': 'connection_init',
        'payload': {'authorization': 'Bearer t1'},
      });
      await sub.cancel();
    },
  );

  test('without a token the init payload is empty', () async {
    final h = _Harness(tokens: [null]);
    final sub = h.client.subscribe(_doc, const {}).listen((_) {});
    await pumpEventQueue();

    expect(h.last.sent.first, {'type': 'connection_init', 'payload': {}});
    await sub.cancel();
  });

  test(
    'subscribes after the ack and delivers each next payload data',
    () async {
      final h = _Harness();
      final (events, sub) = await h.open(variables: {'conversationId': 'c1'});

      final subscribe = h.last.ofType('subscribe').single;
      expect(subscribe['payload'], {
        'query': _doc,
        'variables': {'conversationId': 'c1'},
      });

      h.last.reply({
        'type': 'next',
        'id': subscribe['id'],
        'payload': {
          'data': {'ping': 1},
        },
      });
      await pumpEventQueue();

      expect(events, [
        {'ping': 1},
      ]);
      await sub.cancel();
    },
  );

  test('every subscription shares one socket', () async {
    final h = _Harness();
    final (_, a) = await h.open();
    final (_, b) = await h.open();

    expect(h.sockets, hasLength(1));
    final ids = h.last.ofType('subscribe').map((f) => f['id']).toSet();
    expect(ids, hasLength(2));
    await a.cancel();
    await b.cancel();
  });

  test(
    'cancelling sends complete; the last cancel closes the socket',
    () async {
      final h = _Harness();
      final (_, a) = await h.open();
      final (_, b) = await h.open();
      final ids = h.last.ofType('subscribe').map((f) => f['id']).toList();

      await a.cancel();
      await pumpEventQueue();
      expect(h.last.ofType('complete').map((f) => f['id']), [ids[0]]);
      expect(h.last.closedByClient, isFalse);

      await b.cancel();
      await pumpEventQueue();
      expect(h.last.ofType('complete').map((f) => f['id']), ids);
      expect(h.last.closedByClient, isTrue);
    },
  );

  test('answers ping with pong', () async {
    final h = _Harness();
    final (_, sub) = await h.open();

    h.last.reply({'type': 'ping'});
    await pumpEventQueue();

    expect(h.last.ofType('pong'), hasLength(1));
    await sub.cancel();
  });

  test('an error frame fails that stream and closes it', () async {
    final h = _Harness();
    final (events, sub) = await h.open();
    final id = h.last.ofType('subscribe').single['id'];

    h.last.reply({
      'type': 'error',
      'id': id,
      'payload': [
        {'message': 'not a participant'},
      ],
    });
    await pumpEventQueue();

    expect(events, hasLength(2));
    expect(
      events.first,
      isA<GatewayRejected>().having(
        (e) => e.message,
        'message',
        'not a participant',
      ),
    );
    expect(events.last, #done);
    // The server already ended it; no complete goes back.
    expect(h.last.ofType('complete'), isEmpty);
    await sub.cancel();
  });

  test('a next carrying GraphQL errors is an error on that stream', () async {
    final h = _Harness();
    final (events, sub) = await h.open();
    final id = h.last.ofType('subscribe').single['id'];

    h.last.reply({
      'type': 'next',
      'id': id,
      'payload': {
        'data': null,
        'errors': [
          {'message': 'authentication required'},
        ],
      },
    });
    await pumpEventQueue();

    expect(events.single, isA<GatewayRejected>());
    await sub.cancel();
  });

  test('a server complete closes that stream', () async {
    final h = _Harness();
    final (events, sub) = await h.open();
    final id = h.last.ofType('subscribe').single['id'];

    h.last.reply({'type': 'complete', 'id': id});
    await pumpEventQueue();

    expect(events, [#done]);
    await sub.cancel();
  });

  test(
    'a dropped socket reconnects with a fresh token and re-subscribes',
    () async {
      final h = _Harness(tokens: ['t1', 't2']);
      final (events, sub) = await h.open(variables: {'conversationId': 'c1'});

      h.last.drop();
      await pumpEventQueue();

      expect(h.sockets, hasLength(2));
      expect(h.waits, hasLength(1));
      expect(h.last.sent.first, {
        'type': 'connection_init',
        'payload': {'authorization': 'Bearer t2'},
      });

      h.last.reply({'type': 'connection_ack'});
      await pumpEventQueue();
      final again = h.last.ofType('subscribe').single;
      expect(again['payload'], {
        'query': _doc,
        'variables': {'conversationId': 'c1'},
      });

      h.last.reply({
        'type': 'next',
        'id': again['id'],
        'payload': {
          'data': {'ping': 2},
        },
      });
      await pumpEventQueue();
      expect(events, [
        {'ping': 2},
      ]);
      await sub.cancel();
    },
  );

  test('backoff grows while reconnects fail and is capped', () async {
    final h = _Harness();
    final (_, sub) = await h.open();

    for (var i = 0; i < 10; i++) {
      h.last.drop();
      await pumpEventQueue();
    }

    expect(h.waits.first, const Duration(milliseconds: 500));
    expect(h.waits[1], const Duration(seconds: 1));
    expect(h.waits.last, const Duration(seconds: 30));
    await sub.cancel();
  });

  test('an ack resets the backoff', () async {
    final h = _Harness();
    final (_, sub) = await h.open();

    h.last.drop();
    await pumpEventQueue();
    h.last.drop();
    await pumpEventQueue();
    h.last.reply({'type': 'connection_ack'});
    await pumpEventQueue();
    h.last.drop();
    await pumpEventQueue();

    expect(h.waits.last, const Duration(milliseconds: 500));
    await sub.cancel();
  });

  test('no reconnect once every subscription is gone', () async {
    final h = _Harness();
    final (_, sub) = await h.open();
    await sub.cancel();
    await pumpEventQueue();

    expect(h.sockets, hasLength(1));
    expect(h.waits, isEmpty);
  });

  test('dispose closes the socket and every stream', () async {
    final h = _Harness();
    final (events, _) = await h.open();

    await h.client.dispose();
    await pumpEventQueue();

    expect(events, [#done]);
    expect(h.last.closedByClient, isTrue);
    expect(h.waits, isEmpty);
  });
}
