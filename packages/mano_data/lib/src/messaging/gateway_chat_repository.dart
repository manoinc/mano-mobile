import 'package:mano_domain/mano_domain.dart';

import '../gateway/gateway_failure.dart';
import '../gateway/gateway_transport.dart';
import 'gateway_chat_json.dart';

/// Starts a GraphQL subscription; `SubscriptionClient.subscribe` in the app.
typedef Subscribe = Stream<Map<String, Object?>> Function(
  String document,
  Map<String, Object?> variables,
);

/// [ChatRepository] over gateway queries, mutations and `messageAdded`.
final class GatewayChatRepository implements ChatRepository {
  const GatewayChatRepository(
    this._transport, {
    required this._subscribe,
    required this._viewerId,
  });

  final GatewayTransport _transport;
  final Subscribe _subscribe;
  final String? Function() _viewerId;

  static const _messagesQuery =
      '''
query Messages(\$id: ID!) {
  conversation(id: \$id) {
    messages(page: {first: 50}) { items { $messageFields } }
  }
}''';

  static const _messageAdded =
      '''
subscription MessageAdded(\$conversationId: ID!) {
  messageAdded(conversationId: \$conversationId) { $messageFields }
}''';

  static const _send =
      '''
mutation Send(\$id: ID!, \$content: String!) {
  sendMessage(conversationId: \$id, content: \$content) { $messageFields }
}''';

  static const _markRead = '''
mutation MarkRead(\$id: ID!) { markConversationRead(conversationId: \$id) }''';

  @override
  Future<List<Message>> messages(String conversationId) async {
    final data = await _transport.run(
      _messagesQuery,
      variables: {'id': conversationId},
    );
    final page =
        (data['conversation'] as Map<String, dynamic>?)?['messages']
            as Map<String, dynamic>?;
    final items = page?['items'] as List<dynamic>? ?? const [];
    // The gateway pages newest first; the port is oldest first.
    return [for (final json in items.reversed) _toMessage(json)];
  }

  @override
  Stream<Message> watch(String conversationId) => _subscribe(_messageAdded, {
    'conversationId': conversationId,
  }).map((data) => _toMessage(data['messageAdded']));

  @override
  Future<Result<Message, DataFailure>> send(
    String conversationId,
    String body,
  ) => guardGateway(() async {
    final data = await _transport.run(
      _send,
      variables: {'id': conversationId, 'content': body},
    );
    return _toMessage(data['sendMessage']);
  });

  @override
  Future<Result<void, DataFailure>> markRead(String conversationId) =>
      guardGateway(
        () => _transport.run(_markRead, variables: {'id': conversationId}),
      );

  Message _toMessage(Object? json) =>
      toMessage(json as Map<String, dynamic>, _viewerId());
}
