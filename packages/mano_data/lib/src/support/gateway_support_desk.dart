import 'package:mano_domain/mano_domain.dart';

import '../gateway/gateway_failure.dart';
import '../gateway/gateway_json.dart';
import '../gateway/gateway_transport.dart';
import 'gateway_support_json.dart';

/// [SupportDesk] backed by the gateway's support tickets.
final class GatewaySupportDesk implements SupportDesk {
  const GatewaySupportDesk(this._transport);

  final GatewayTransport _transport;

  static const _create =
      '''
mutation CreateSupportTicket(\$input: SupportTicketInput!) {
  createSupportTicket(input: \$input) { $ticketFields }
}''';

  static const _mine =
      '''
query MySupportTickets {
  mySupportTickets(page: {first: 50}) { items { $ticketFields } }
}''';

  static const _thread =
      '''
query SupportMessages(\$ticketId: ID!) {
  supportMessages(ticketId: \$ticketId, page: {first: 100}) { items { $messageFields } }
}''';

  static const _send =
      '''
mutation SendSupportMessage(\$ticketId: ID!, \$body: String!) {
  sendSupportMessage(ticketId: \$ticketId, body: \$body) { $messageFields }
}''';

  @override
  Future<Result<SupportTicket, DataFailure>> submit(
    SupportTicketDraft draft,
  ) async {
    if (!draft.isValid) return Err(DataRejected(reason: '${draft.problems}'));
    return guardGateway(() async {
      final data = await _transport.run(
        _create,
        variables: {
          'input': {
            'kind': kindToJson(draft.kind),
            'subject': draft.subject.trim(),
            'description': draft.description.trim(),
          },
        },
      );
      return toSupportTicket(
        data['createSupportTicket'] as Map<String, dynamic>,
      );
    });
  }

  @override
  Future<Result<List<SupportTicket>, DataFailure>> myTickets() =>
      guardGateway(() async {
        final data = await _transport.run(_mine);
        return pageItems(data['mySupportTickets'])
            .map(toSupportTicket)
            .toList();
      });

  @override
  Future<Result<List<SupportMessage>, DataFailure>> messages(String ticketId) =>
      guardGateway(() async {
        final data = await _transport.run(
          _thread,
          variables: {'ticketId': ticketId},
        );
        return pageItems(data['supportMessages'])
            .map(toSupportMessage)
            .toList();
      });

  @override
  Future<Result<SupportMessage, DataFailure>> send(
    String ticketId,
    String body,
  ) async {
    if (!isValidSupportMessage(body)) return const Err(DataRejected());
    return guardGateway(() async {
      final data = await _transport.run(
        _send,
        variables: {'ticketId': ticketId, 'body': body.trim()},
      );
      return toSupportMessage(
        data['sendSupportMessage'] as Map<String, dynamic>,
      );
    });
  }
}
