import 'package:mano_domain/mano_domain.dart';

import '../gateway/gateway_json.dart';

// The gateway's chat wire format, shared by the conversation and chat adapters.

const participantFields = 'role profileId displayName photoUrl';

const messageFields =
    'id conversationId sender { $participantFields } content sentAt readAt';

const conversationFields =
    'id unreadCount participants { $participantFields } '
    'lastMessage { $messageFields }';

/// [json] seen by [viewerId]: the other participant, no time until a message.
Conversation toConversation(Map<String, dynamic> json, String? viewerId) {
  final other = _other(json['participants'] as List<dynamic>, viewerId);
  final last = json['lastMessage'] as Map<String, dynamic>?;
  return Conversation(
    id: json['id'] as String,
    participant: other == null
        ? const Party(id: '', displayName: '', photoUrl: '')
        : toParty(other),
    participantRole: toManoRole(other?['role']),
    lastMessage: last?['content'] as String? ?? '',
    lastMessageAt: last == null ? null : dateTimeFromJson(last['sentAt']),
    unreadCount: json['unreadCount'] as int? ?? 0,
  );
}

// The first participant who isn't me.
Map<String, dynamic>? _other(List<dynamic> participants, String? me) =>
    participants
        .cast<Map<String, dynamic>>()
        .where((p) => p['profileId'] != me)
        .firstOrNull;

/// [json] seen by [viewerId]: mine when I sent it, read once `readAt` is set.
Message toMessage(Map<String, dynamic> json, String? viewerId) => Message(
  id: json['id'] as String,
  conversationId: json['conversationId'] as String,
  body: json['content'] as String,
  sentAt: dateTimeFromJson(json['sentAt']),
  fromMe: (json['sender'] as Map<String, dynamic>)['profileId'] == viewerId,
  status: json['readAt'] == null ? MessageStatus.delivered : MessageStatus.read,
);

Party toParty(Map<String, dynamic> json) => Party(
  id: json['profileId'] as String,
  displayName: json['displayName'] as String? ?? '',
  photoUrl: json['photoUrl'] as String? ?? '',
);

/// WORKER is a provider; CLIENT (and STAFF, which has no ManoRole) a requester.
String toManoRole(Object? role) =>
    role == 'WORKER' ? ManoRole.provider : ManoRole.requester;
