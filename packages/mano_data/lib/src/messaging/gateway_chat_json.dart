import 'package:mano_domain/mano_domain.dart';

// The gateway's chat wire format, shared by the conversation and chat adapters.

const participantFields = 'role profileId displayName photoUrl';

const messageFields =
    'id conversationId sender { $participantFields } content sentAt readAt';

/// [json] seen by [viewerId]: mine when I sent it, read once `readAt` is set.
Message toMessage(Map<String, dynamic> json, String? viewerId) => Message(
  id: json['id'] as String,
  conversationId: json['conversationId'] as String,
  body: json['content'] as String,
  sentAt: DateTime.parse(json['sentAt'] as String),
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
