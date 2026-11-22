import 'package:mano_domain/mano_domain.dart';

import '../gateway/gateway_json.dart';

// The gateway's support wire format.

const ticketFields =
    'id ticketNumber kind subject description status createdAt updatedAt '
    'resolvedAt';

const messageFields = 'id senderIsStaff body createdAt';

SupportTicket toSupportTicket(Map<String, dynamic> json) => SupportTicket(
  id: json['id'] as String,
  number: json['ticketNumber'] as String,
  kind: switch (json['kind']) {
    'QUEJA' => SupportTicketKind.queja,
    'RECLAMO' => SupportTicketKind.reclamo,
    'SUGERENCIA' => SupportTicketKind.sugerencia,
    _ => SupportTicketKind.peticion,
  },
  subject: json['subject'] as String,
  description: json['description'] as String,
  status: switch (json['status']) {
    'IN_PROGRESS' => SupportTicketStatus.inProgress,
    'RESOLVED' => SupportTicketStatus.resolved,
    'CLOSED' => SupportTicketStatus.closed,
    _ => SupportTicketStatus.filed,
  },
  createdAt: dateTimeFromJson(json['createdAt']),
);

SupportMessage toSupportMessage(Map<String, dynamic> json) => SupportMessage(
  id: json['id'] as String,
  fromStaff: json['senderIsStaff'] as bool,
  body: json['body'] as String,
  sentAt: dateTimeFromJson(json['createdAt']),
);

String kindToJson(SupportTicketKind kind) => kind.name.toUpperCase();
