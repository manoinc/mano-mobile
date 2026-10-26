import 'package:mano_domain/mano_domain.dart';

import '../gateway/gateway_failure.dart';
import '../gateway/gateway_transport.dart';
import 'gateway_chat_json.dart';

/// [ConversationRepository] backed by the gateway's `myConversations`.
final class GatewayConversationRepository implements ConversationRepository {
  const GatewayConversationRepository(
    this._transport, {
    required this._viewerId,
  });

  final GatewayTransport _transport;

  // The signed-in profile, to tell the other participant from me.
  final String? Function() _viewerId;

  static const _query =
      '''
query MyConversations {
  myConversations { $conversationFields }
}''';

  static const _open =
      '''
mutation Open(\$reference: ConversationRefInput!) {
  openConversation(reference: \$reference) { $conversationFields }
}''';

  @override
  Future<List<Conversation>> conversations() async {
    final data = await _transport.run(_query);
    final viewer = _viewerId();
    return [
      for (final json in data['myConversations'] as List<dynamic>)
        toConversation(json as Map<String, dynamic>, viewer),
    ];
  }

  @override
  Future<Result<Conversation, DataFailure>> open({
    String? withWorkerId,
    String? jobId,
  }) => guardGateway(() async {
    final data = await _transport.run(
      _open,
      variables: {
        'reference': {'withWorkerId': ?withWorkerId, 'jobId': ?jobId},
      },
    );
    return toConversation(
      data['openConversation'] as Map<String, dynamic>,
      _viewerId(),
    );
  });
}
