import 'package:mano_domain/mano_domain.dart';

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

  @override
  Future<List<Conversation>> conversations() async {
    final data = await _transport.run(_query);
    final viewer = _viewerId();
    return [
      for (final json in data['myConversations'] as List<dynamic>)
        toConversation(json as Map<String, dynamic>, viewer),
    ];
  }
}
