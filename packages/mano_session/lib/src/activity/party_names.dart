import 'package:mano_domain/mano_domain.dart';

// Live profiles have no names yet; the screens say "Cliente" or "Profesional" instead.
const _client = 'Cliente';
const _provider = 'Profesional';

extension JobPartyNames on Job {
  String get clientName => client.nameOr(_client);
  String get providerName => provider.nameOr(_provider);
}

extension ConversationPartyNames on Conversation {
  String get participantLabel => participant.nameOr(
    participantRole == ManoRole.provider ? _provider : _client,
  );
}

extension RequestPartyNames on ServiceRequest {
  String get clientName => client.nameOr(_client);
  String get providerName => provider.nameOr(_provider);
}
