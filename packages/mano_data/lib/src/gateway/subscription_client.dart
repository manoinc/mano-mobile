import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'gateway_transport.dart';

/// Opens the socket; tests hand back an in-memory channel.
typedef SocketConnector = StreamChannel<dynamic> Function(Uri url);

/// GraphQL subscriptions over one shared `graphql-transport-ws` socket.
///
/// Connects on the first subscription and closes after the last. A dropped
/// socket reconnects with capped backoff, a fresh token and every live
/// subscription re-sent.
final class SubscriptionClient {
  SubscriptionClient(
    String url, {
    required Future<String?> Function() accessToken,
    SocketConnector? connect,
    Future<void> Function(Duration)? wait,
  }) : _url = Uri.parse(url),
       _accessToken = accessToken,
       _connect = connect ?? _webSocket,
       _wait = wait ?? Future<void>.delayed;

  static const _protocol = 'graphql-transport-ws';
  static const _firstBackoff = Duration(milliseconds: 500);
  static const _maxBackoff = Duration(seconds: 30);

  final Uri _url;
  final Future<String?> Function() _accessToken;
  final SocketConnector _connect;
  final Future<void> Function(Duration) _wait;

  final Map<String, _Operation> _operations = {};
  StreamChannel<dynamic>? _channel;
  StreamSubscription<dynamic>? _incoming;
  var _acknowledged = false;
  var _connecting = false;
  var _failures = 0;
  var _nextId = 0;

  static StreamChannel<dynamic> _webSocket(Uri url) =>
      WebSocketChannel.connect(url, protocols: const [_protocol]);

  /// Each `next` payload's `data`; a GraphQL error fails and ends the stream.
  Stream<Map<String, Object?>> subscribe(
    String document,
    Map<String, Object?> variables,
  ) {
    late final _Operation operation;
    final controller = StreamController<Map<String, Object?>>(
      onListen: () {
        _operations[operation.id] = operation;
        if (_acknowledged) _sendSubscribe(operation);
        _ensureConnected();
      },
      onCancel: () => _cancel(operation.id),
    );
    operation = _Operation('${_nextId++}', document, variables, controller);
    return controller.stream;
  }

  /// Ends every stream and closes the socket.
  Future<void> dispose() async {
    final open = List.of(_operations.values);
    _operations.clear();
    _close();
    for (final operation in open) {
      await operation.controller.close();
    }
  }

  void _cancel(String id) {
    if (_operations.remove(id) == null) return;
    if (_acknowledged) _send({'type': 'complete', 'id': id});
    if (_operations.isEmpty) _close();
  }

  void _ensureConnected() {
    if (_channel != null || _connecting) return;
    _connecting = true;
    unawaited(_open());
  }

  Future<void> _open() async {
    String? token;
    try {
      token = await _accessToken();
    } on Object {
      token = null;
    }
    _connecting = false;
    if (_operations.isEmpty || _channel != null) return;

    final channel = _connect(_url);
    _channel = channel;
    _incoming = channel.stream.listen(
      _onFrame,
      onError: (Object _) {},
      onDone: () => _onDropped(channel),
    );
    _send({
      'type': 'connection_init',
      'payload': {'authorization': ?(token == null ? null : 'Bearer $token')},
    });
  }

  Future<void> _onDropped(StreamChannel<dynamic> channel) async {
    if (!identical(channel, _channel)) return;
    _channel = null;
    _incoming = null;
    _acknowledged = false;
    if (_operations.isEmpty) return;

    _connecting = true;
    await _wait(_backoff(_failures++));
    _connecting = false;
    _ensureConnected();
  }

  Duration _backoff(int failures) {
    final doubled = _firstBackoff * pow(2, min(failures, 10));
    return doubled > _maxBackoff ? _maxBackoff : doubled;
  }

  void _close() {
    unawaited(_incoming?.cancel());
    unawaited(_channel?.sink.close());
    _incoming = null;
    _channel = null;
    _acknowledged = false;
    _failures = 0;
  }

  void _onFrame(dynamic raw) {
    final Map<String, dynamic> frame;
    try {
      frame = jsonDecode(raw as String) as Map<String, dynamic>;
    } on Object {
      return;
    }
    final operation = _operations[frame['id']];
    switch (frame['type']) {
      case 'connection_ack':
        _acknowledged = true;
        _failures = 0;
        _operations.values.forEach(_sendSubscribe);
      case 'ping':
        _send({'type': 'pong'});
      case 'next' when operation != null:
        _next(operation, frame['payload'] as Map<String, dynamic>? ?? {});
      case 'error' when operation != null:
        _fail(operation, _firstMessage(frame['payload']));
      case 'complete' when operation != null:
        _finish(operation);
    }
  }

  void _next(_Operation operation, Map<String, dynamic> payload) {
    final errors = payload['errors'];
    if (errors is List && errors.isNotEmpty) {
      operation.controller.addError(GatewayRejected(_firstMessage(errors)));
      return;
    }
    final data = payload['data'];
    if (data is Map<String, dynamic>) operation.controller.add(data);
  }

  void _fail(_Operation operation, String message) {
    operation.controller.addError(GatewayRejected(message));
    _finish(operation);
  }

  void _finish(_Operation operation) {
    _operations.remove(operation.id);
    unawaited(operation.controller.close());
    if (_operations.isEmpty) _close();
  }

  static String _firstMessage(Object? errors) => switch (errors) {
    [final Map<String, dynamic> first, ...] => '${first['message']}',
    _ => 'subscription failed',
  };

  void _sendSubscribe(_Operation operation) => _send({
    'type': 'subscribe',
    'id': operation.id,
    'payload': {'query': operation.document, 'variables': operation.variables},
  });

  void _send(Map<String, Object?> frame) =>
      _channel?.sink.add(jsonEncode(frame));
}

final class _Operation {
  _Operation(this.id, this.document, this.variables, this.controller);

  final String id;
  final String document;
  final Map<String, Object?> variables;
  final StreamController<Map<String, Object?>> controller;
}
