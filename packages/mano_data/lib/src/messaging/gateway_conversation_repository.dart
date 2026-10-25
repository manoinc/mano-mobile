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
  myConversations {
    id unreadCount
    participants { $participantFields }
    lastMessage { $messageFields }
  }
}''';

  @override
  Future<List<Conversation>> conversations() async {
    final data = await _transport.run(_query);
    final viewer = _viewerId();
    return [
      for (final json in data['myConversations'] as List<dynamic>)
        _toConversation(json as Map<String, dynamic>, viewer),
    ];
  }

  Conversation _toConversation(Map<String, dynamic> json, String? viewer) {
    final other = _other(json['participants'] as List<dynamic>, viewer);
    final last = json['lastMessage'] as Map<String, dynamic>?;
    return Conversation(
      id: json['id'] as String,
      participant: other == null
          ? const Party(id: '', displayName: '', photoUrl: '')
          : toParty(other),
      participantRole: toManoRole(other?['role']),
      lastMessage: last?['content'] as String? ?? '',
      lastMessageAt: last == null
          ? DateTime(0)
          : DateTime.parse(last['sentAt'] as String),
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }

  // The first participant who isn't me.
  static Map<String, dynamic>? _other(List<dynamic> participants, String? me) =>
      participants
          .cast<Map<String, dynamic>>()
          .where((p) => p['profileId'] != me)
          .firstOrNull;
}
